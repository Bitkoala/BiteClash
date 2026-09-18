import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/connection_item.dart';
import '../models/log_item.dart';
import '../models/proxy_group.dart';
import '../models/proxy_node.dart';
import '../models/traffic.dart';

/// Mihomo (Clash.Meta) External Controller RESTful & WebSocket API 客户端
class MihomoApiClient {
  final String host;
  final int port;
  final String secret;
  late final Dio _dio;

  MihomoApiClient({
    this.host = '127.0.0.1',
    this.port = 9090,
    this.secret = '',
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://$host:$port',
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          if (secret.isNotEmpty) 'Authorization': 'Bearer $secret',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// 获取内核版本信息
  Future<Map<String, dynamic>> getVersion() async {
    final res = await _dio.get('/version');
    return res.data as Map<String, dynamic>;
  }

  /// 获取当前运行配置 (包括 mode: rule/global/direct)
  Future<Map<String, dynamic>> getConfigs() async {
    final res = await _dio.get('/configs');
    return res.data as Map<String, dynamic>;
  }

  /// 动态更新配置 (如切换模式: {'mode': 'rule'})
  Future<void> updateConfigs(Map<String, dynamic> patch) async {
    await _dio.patch('/configs', data: patch);
  }

  /// 获取当前内存占用
  Future<int> getMemoryInBytes() async {
    try {
      final res = await _dio.get('/memory');
      return (res.data as Map<String, dynamic>)['inuse'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 获取所有代理与策略组并进行归类解析
  Future<({Map<String, ProxyGroup> groups, Map<String, ProxyNode> nodes})> getProxiesAndGroups() async {
    final res = await _dio.get('/proxies');
    final data = (res.data as Map<String, dynamic>)['proxies'] as Map<String, dynamic>? ?? {};

    final groups = <String, ProxyGroup>{};
    final nodes = <String, ProxyNode>{};

    for (final entry in data.entries) {
      final item = entry.value as Map<String, dynamic>;
      final type = (item['type'] as String? ?? '').toLowerCase();

      // 判断是策略组还是单节点
      final isGroup = ['selector', 'urltest', 'url-test', 'fallback', 'loadbalance', 'load-balance', 'relay']
          .contains(type);

      if (isGroup) {
        groups[entry.key] = ProxyGroup.fromJson(item);
      } else {
        nodes[entry.key] = ProxyNode.fromJson(item);
      }
    }

    return (groups: groups, nodes: nodes);
  }

  /// 为指定的策略组切换选中的节点
  Future<bool> selectProxy(String groupName, String nodeName) async {
    try {
      final encodedGroupName = Uri.encodeComponent(groupName);
      final res = await _dio.put(
        '/proxies/$encodedGroupName',
        data: {'name': nodeName},
      );
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 测试指定节点或策略组的延迟 (返回毫秒数，若失败返回 null)
  Future<int?> getProxyDelay(
    String proxyName, {
    String testUrl = 'http://www.gstatic.com/generate_204',
    int timeout = 5000,
  }) async {
    try {
      final encodedName = Uri.encodeComponent(proxyName);
      final res = await _dio.get(
        '/proxies/$encodedName/delay',
        queryParameters: {
          'url': testUrl,
          'timeout': timeout,
        },
      );
      final delay = (res.data as Map<String, dynamic>)['delay'] as int?;
      return delay;
    } catch (_) {
      return null;
    }
  }

  /// 重置所有现有网络连接
  Future<void> closeAllConnections() async {
    try {
      await _dio.delete('/connections');
    } catch (_) {}
  }

  /// 订阅实时流量 WebSocket 流 (/traffic)
  Stream<Traffic> getTrafficStream() {
    final wsUri = Uri(
      scheme: 'ws',
      host: host,
      port: port,
      path: '/traffic',
      queryParameters: secret.isNotEmpty ? {'token': secret} : null,
    );

    late WebSocketChannel channel;
    late StreamController<Traffic> controller;

    void connect() {
      try {
        channel = WebSocketChannel.connect(wsUri);
        channel.stream.listen(
          (message) {
            try {
              final json = jsonDecode(message.toString()) as Map<String, dynamic>;
              controller.add(Traffic.fromJson(json));
            } catch (_) {}
          },
          onError: (err) {
            controller.addError(err);
          },
          onDone: () {
            // 连接断开
          },
          cancelOnError: false,
        );
      } catch (e) {
        controller.addError(e);
      }
    }

    controller = StreamController<Traffic>.broadcast(
      onListen: connect,
      onCancel: () {
        channel.sink.close();
      },
    );

    return controller.stream;
  }

  /// 获取当前所有活跃连接与总流量
  Future<({int uploadTotal, int downloadTotal, List<ConnectionItem> connections})> getConnections() async {
    try {
      final res = await _dio.get('/connections');
      final data = res.data as Map<String, dynamic>;
      final upTotal = data['uploadTotal'] as int? ?? 0;
      final downTotal = data['downloadTotal'] as int? ?? 0;
      final rawList = data['connections'] as List<dynamic>? ?? [];

      final list = rawList
          .map((e) => ConnectionItem.fromJson(e as Map<String, dynamic>))
          .toList();

      return (
        uploadTotal: upTotal,
        downloadTotal: downTotal,
        connections: list,
      );
    } catch (_) {
      return (
        uploadTotal: 0,
        downloadTotal: 0,
        connections: <ConnectionItem>[],
      );
    }
  }

  /// 断开指定的网络连接
  Future<bool> closeConnection(String id) async {
    try {
      final res = await _dio.delete('/connections/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// 订阅实时日志 WebSocket 流 (/logs)
  Stream<LogItem> getLogsStream({String level = 'info'}) {
    final wsUri = Uri(
      scheme: 'ws',
      host: host,
      port: port,
      path: '/logs',
      queryParameters: {
        'level': level,
        if (secret.isNotEmpty) 'token': secret,
      },
    );

    late WebSocketChannel channel;
    late StreamController<LogItem> controller;

    void connect() {
      try {
        channel = WebSocketChannel.connect(wsUri);
        channel.stream.listen(
          (message) {
            try {
              final json = jsonDecode(message.toString()) as Map<String, dynamic>;
              controller.add(LogItem.fromJson(json));
            } catch (_) {}
          },
          onError: (err) {
            controller.addError(err);
          },
          onDone: () {},
          cancelOnError: false,
        );
      } catch (e) {
        controller.addError(e);
      }
    }

    controller = StreamController<LogItem>.broadcast(
      onListen: connect,
      onCancel: () {
        channel.sink.close();
      },
    );

    return controller.stream;
  }
}
