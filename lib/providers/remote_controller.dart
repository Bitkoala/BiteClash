import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/remote.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteControllerState {
  final bool enabled;
  final String host;
  final int port;
  final String secret;
  final bool testing;
  final String? testResult;
  final bool? testSuccess;

  const RemoteControllerState({
    this.enabled = false,
    this.host = '192.168.1.1',
    this.port = 9090,
    this.secret = '',
    this.testing = false,
    this.testResult,
    this.testSuccess,
  });

  RemoteControllerState copyWith({
    bool? enabled,
    String? host,
    int? port,
    String? secret,
    bool? testing,
    String? testResult,
    bool? testSuccess,
  }) {
    return RemoteControllerState(
      enabled: enabled ?? this.enabled,
      host: host ?? this.host,
      port: port ?? this.port,
      secret: secret ?? this.secret,
      testing: testing ?? this.testing,
      testResult: testResult,
      testSuccess: testSuccess,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'host': host,
    'port': port,
    'secret': secret,
  };

  factory RemoteControllerState.fromMap(Map<String, dynamic> map) =>
      RemoteControllerState(
        enabled: map['enabled'] as bool? ?? false,
        host: map['host'] as String? ?? '192.168.1.1',
        port: map['port'] as int? ?? 9090,
        secret: map['secret'] as String? ?? '',
      );
}

class RemoteControllerNotifier extends Notifier<RemoteControllerState> {
  @override
  RemoteControllerState build() {
    _loadInitial();
    return const RemoteControllerState();
  }

  Future<void> _loadInitial() async {
    final map = await preferences.getRemoteControllerMap();
    if (map != null) {
      final loaded = RemoteControllerState.fromMap(map);
      state = loaded;
      if (loaded.enabled && loaded.host.isNotEmpty) {
        coreController.setRemoteHandler(
          RemoteCoreHandler(
            host: loaded.host,
            port: loaded.port,
            secret: loaded.secret,
          ),
        );
      }
    }
  }

  Future<void> updateConfig({String? host, int? port, String? secret}) async {
    state = state.copyWith(
      host: host ?? state.host,
      port: port ?? state.port,
      secret: secret ?? state.secret,
      testResult: null,
      testSuccess: null,
    );
    await preferences.saveRemoteControllerMap(state.toMap());
    if (state.enabled) {
      coreController.setRemoteHandler(
        RemoteCoreHandler(
          host: state.host,
          port: state.port,
          secret: state.secret,
        ),
      );
    }
  }

  Future<void> toggleEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await preferences.saveRemoteControllerMap(state.toMap());
    if (enabled) {
      coreController.setRemoteHandler(
        RemoteCoreHandler(
          host: state.host,
          port: state.port,
          secret: state.secret,
        ),
      );
    } else {
      coreController.setRemoteHandler(null);
    }
  }

  Future<bool> testConnection() async {
    state = state.copyWith(testing: true, testResult: null, testSuccess: null);
    final handler = RemoteCoreHandler(
      host: state.host,
      port: state.port,
      secret: state.secret,
    );
    final stopwatch = Stopwatch()..start();
    final success = await handler.testConnection();
    stopwatch.stop();
    final ms = stopwatch.elapsedMilliseconds;
    state = state.copyWith(
      testing: false,
      testSuccess: success,
      testResult: success
          ? '连接成功 (延迟 ${ms}ms)'
          : '连接失败: 无法访问 http://${state.host}:${state.port}',
    );
    return success;
  }
}

final remoteControllerProvider =
    NotifierProvider<RemoteControllerNotifier, RemoteControllerState>(
      RemoteControllerNotifier.new,
    );
