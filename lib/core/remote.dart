import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/desktop/model.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/models/models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RemoteCoreHandler extends CoreHandlerInterface {
  final String host;
  final int port;
  final String secret;

  late final Dio _dio;
  WebSocketChannel? _trafficChannel;
  WebSocketChannel? _logsChannel;
  Traffic _latestTraffic = const Traffic(up: 0, down: 0);
  int _latestMemory = 0;
  bool _isConnected = false;
  int _lifecycleRevision = 0;

  RemoteCoreHandler({required this.host, this.port = 9090, this.secret = ''}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://$host:$port',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          if (secret.isNotEmpty) 'Authorization': 'Bearer $secret',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  String get baseUrl => 'http://$host:$port';
  String get wsUrl => 'ws://$host:$port';

  Future<bool> testConnection() async {
    try {
      final res = await _dio.get('/version');
      return res.statusCode == 200;
    } catch (_) {
      try {
        final res = await _dio.get('/proxies');
        return res.statusCode == 200;
      } catch (e) {
        commonPrint.log('RemoteCoreHandler testConnection failed: $e');
        return false;
      }
    }
  }

  void _startTrafficSubscription() {
    _stopTrafficSubscription();
    try {
      final uri = Uri.parse(
        '$wsUrl/traffic${secret.isNotEmpty ? '?token=$secret' : ''}',
      );
      _trafficChannel = WebSocketChannel.connect(uri);
      _trafficChannel?.stream.listen(
        (data) {
          try {
            final jsonMap =
                json.decode(data.toString()) as Map<String, dynamic>;
            _latestTraffic = Traffic.fromJson(jsonMap);
          } catch (_) {}
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (e) {
      commonPrint.log('RemoteCoreHandler traffic ws error: $e');
    }
  }

  void _stopTrafficSubscription() {
    _trafficChannel?.sink.close();
    _trafficChannel = null;
  }

  @override
  Future<CoreLifecycleResult> start() async {
    final ok = await testConnection();
    if (!ok) {
      throw StateError('Cannot connect to remote Mihomo at $baseUrl');
    }
    _isConnected = true;
    _startTrafficSubscription();
    return CoreLifecycleResult(
      revision: ++_lifecycleRevision,
      outcome: CoreLifecycleOutcome.applied,
    );
  }

  @override
  Future<CoreLifecycleResult> restart() async {
    await stop();
    return start();
  }

  @override
  Future<CoreLifecycleResult> stop() async {
    _stopTrafficSubscription();
    await _logsChannel?.sink.close();
    _logsChannel = null;
    _isConnected = false;
    return CoreLifecycleResult(
      revision: ++_lifecycleRevision,
      outcome: CoreLifecycleOutcome.applied,
    );
  }

  @override
  Future<CoreLifecycleResult> close() => stop();

  @override
  Future<bool> init(InitParams params) async {
    _isConnected = await testConnection();
    if (_isConnected) {
      _startTrafficSubscription();
    }
    return _isConnected;
  }

  @override
  Future<bool> get isInit async => _isConnected;

  @override
  Future<bool> forceGc() async {
    try {
      await _dio.post('/gc');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> validateConfig(String path) async => '';

  @override
  Future<Map<String, dynamic>> getConfig(String path) async {
    try {
      final res = await _dio.get('/configs');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return {};
    } catch (e) {
      commonPrint.log('RemoteCoreHandler getConfig failed: $e');
      return {};
    }
  }

  @override
  Future<Delay?> asyncTestDelay(String url, String proxyName) async {
    try {
      final encodedName = Uri.encodeComponent(proxyName);
      final res = await _dio.get(
        '/proxies/$encodedName/delay',
        queryParameters: {'url': url, 'timeout': 5000},
      );
      final delay = (res.data as Map)['delay'] as int?;
      return Delay(name: proxyName, url: url, value: delay);
    } catch (e) {
      return Delay(name: proxyName, url: url, value: null);
    }
  }

  @override
  Future<String> updateConfig(UpdateParams updateParams) async {
    try {
      await _dio.patch('/configs', data: updateParams.toJson());
      return '';
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<String> setupConfig(SetupParams setupParams) async => '';

  @override
  Future<ProxiesData> getProxies() async {
    try {
      final res = await _dio.get('/proxies');
      if (res.data is Map) {
        return ProxiesData.fromJson(Map<String, dynamic>.from(res.data as Map));
      }
      return const ProxiesData(proxies: {}, all: []);
    } catch (e) {
      commonPrint.log('RemoteCoreHandler getProxies failed: $e');
      return const ProxiesData(proxies: {}, all: []);
    }
  }

  @override
  Future<String> changeProxy(ChangeProxyParams changeProxyParams) async {
    try {
      final encodedGroup = Uri.encodeComponent(changeProxyParams.groupName);
      await _dio.put(
        '/proxies/$encodedGroup',
        data: {'name': changeProxyParams.proxyName},
      );
      return '';
    } catch (e) {
      commonPrint.log('RemoteCoreHandler changeProxy failed: $e');
      return e.toString();
    }
  }

  @override
  Future<bool> startListener() async => true;

  @override
  Future<bool> stopListener() async => true;

  @override
  Future<List<ExternalProvider>> getExternalProviders() async {
    try {
      final res = await _dio.get('/providers/proxies');
      final data = res.data;
      if (data is Map && data['providers'] is Map) {
        final providersMap = data['providers'] as Map;
        return providersMap.values
            .whereType<Map>()
            .map(
              (item) =>
                  ExternalProvider.fromJson(Map<String, Object?>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ExternalProvider?> getExternalProvider(
    String externalProviderName,
  ) async {
    try {
      final encoded = Uri.encodeComponent(externalProviderName);
      final res = await _dio.get('/providers/proxies/$encoded');
      if (res.data is Map) {
        return ExternalProvider.fromJson(
          Map<String, Object?>.from(res.data as Map),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> updateGeoData(String type) async => '';

  @override
  Future<String> sideLoadExternalProvider({
    required String providerName,
    required String data,
  }) async => '';

  @override
  Future<String> updateExternalProvider(String providerName) async {
    try {
      final encoded = Uri.encodeComponent(providerName);
      await _dio.put('/providers/proxies/$encoded');
      return '';
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<Traffic> getTraffic(bool onlyStatisticsProxy) async => _latestTraffic;

  @override
  Future<Traffic> getTotalTraffic(bool onlyStatisticsProxy) async =>
      _latestTraffic;

  @override
  Future<int> getMemory() async {
    try {
      final res = await _dio.get('/memory');
      if (res.data is Map && (res.data as Map)['inuse'] != null) {
        _latestMemory = ((res.data as Map)['inuse'] as num).toInt();
      }
    } catch (_) {}
    return _latestMemory;
  }

  @override
  void resetTraffic() {
    _latestTraffic = const Traffic(up: 0, down: 0);
  }

  @override
  void startLog() {
    try {
      final uri = Uri.parse(
        '$wsUrl/logs${secret.isNotEmpty ? '?token=$secret' : ''}',
      );
      _logsChannel = WebSocketChannel.connect(uri);
    } catch (_) {}
  }

  @override
  void stopLog() {
    _logsChannel?.sink.close();
    _logsChannel = null;
  }

  @override
  Future<bool> crash() async => false;

  @override
  Future<List<TrackerInfo>> getConnections() async {
    try {
      final res = await _dio.get('/connections');
      final data = res.data;
      if (data is Map && data['connections'] is List) {
        final list = data['connections'] as List;
        return list
            .whereType<Map>()
            .map(
              (item) => TrackerInfo.fromJson(Map<String, Object?>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      commonPrint.log('RemoteCoreHandler getConnections failed: $e');
      return [];
    }
  }

  @override
  Future<bool> closeConnection(String id) async {
    try {
      await _dio.delete('/connections/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> clearEffect(int profileId) async => '';

  @override
  Future<bool> closeConnections() async {
    try {
      await _dio.delete('/connections');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> resetConnections() async => closeConnections();

  @override
  Future<T?> invokeMethod<T>({
    required CoreMethod method,
    Object? arguments,
    Duration? timeout,
  }) async {
    return null;
  }
}
