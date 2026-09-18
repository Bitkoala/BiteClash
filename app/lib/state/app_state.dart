import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/mihomo_api_client.dart';
import '../../core/models/traffic.dart';
import '../../core/process/mihomo_process.dart';
import '../../core/proxy/windows_proxy.dart';

/// 全局客户端核心状态
class AppState {
  final bool isRunning;
  final int? pid;
  final bool isProxyEnabled;
  final String currentMode; // 'rule', 'global', 'direct'
  final Traffic currentTraffic;
  final List<Traffic> trafficHistory;
  final String? activeNode;
  final bool isLoading;
  final String? error;

  const AppState({
    this.isRunning = false,
    this.pid,
    this.isProxyEnabled = false,
    this.currentMode = 'rule',
    this.currentTraffic = const Traffic(),
    this.trafficHistory = const [],
    this.activeNode,
    this.isLoading = false,
    this.error,
  });

  AppState copyWith({
    bool? isRunning,
    int? pid,
    bool? isProxyEnabled,
    String? currentMode,
    Traffic? currentTraffic,
    List<Traffic>? trafficHistory,
    String? activeNode,
    bool? isLoading,
    String? error,
  }) {
    return AppState(
      isRunning: isRunning ?? this.isRunning,
      pid: pid ?? this.pid,
      isProxyEnabled: isProxyEnabled ?? this.isProxyEnabled,
      currentMode: currentMode ?? this.currentMode,
      currentTraffic: currentTraffic ?? this.currentTraffic,
      trafficHistory: trafficHistory ?? this.trafficHistory,
      activeNode: activeNode ?? this.activeNode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AppNotifier extends StateNotifier<AppState> {
  final MihomoApiClient _apiClient = MihomoApiClient();
  MihomoProcessService? _processService;
  StreamSubscription<Traffic>? _trafficSub;

  AppNotifier() : super(const AppState()) {
    _init();
  }

  Future<void> _init() async {
    // 检查初始 Windows 系统代理状态
    final proxyStatus = await WindowsProxyManager.getProxyStatus();
    state = state.copyWith(isProxyEnabled: proxyStatus.enabled);

    // 检查是否已有 Mihomo 内核在后台运行
    try {
      final ver = await _apiClient.getVersion();
      if (ver.containsKey('version')) {
        final configs = await _apiClient.getConfigs();
        state = state.copyWith(
          isRunning: true,
          currentMode: configs['mode']?.toString().toLowerCase() ?? 'rule',
        );
        _startTrafficMonitor();
      }
    } catch (_) {}
  }

  String _resolveBasePath() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      if (File('$exeDir\\core\\windows\\mihomo.exe').existsSync()) {
        return exeDir;
      }
      final cur = Directory.current.path;
      return cur.endsWith('app') ? Directory(cur).parent.path : cur;
    }
    return Directory.current.path;
  }

  /// 一键启动/停止内核并切换系统代理
  Future<void> toggleCoreAndProxy() async {
    if (state.isRunning) {
      await stopCore();
    } else {
      await startCore();
    }
  }

  /// 启动内核 (自动优先读取当前选中的订阅配置)
  Future<void> startCore() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final basePath = _resolveBasePath();
      final exePath = '$basePath\\core\\windows\\mihomo.exe';
      final workDir = '$basePath\\core\\configs';

      // 读取持久化中激活的订阅配置
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString('active_profile_id');
      String configPath = '$basePath\\core\\configs\\default_config.yaml';

      if (activeId != null && activeId.isNotEmpty) {
        final profileFile = File('$basePath\\core\\configs\\profiles\\$activeId.yaml');
        if (profileFile.existsSync()) {
          configPath = profileFile.path;
        }
      }

      _processService = MihomoProcessService(
        executablePath: exePath,
        workingDir: workDir,
        configPath: configPath,
        apiPort: 9090,
      );

      final ok = await _processService!.start();
      if (!ok) throw Exception('Mihomo 启动异常或 API 响应超时');

      // 开启系统代理
      await WindowsProxyManager.enableProxy(port: 7890);

      // 读取当前模式
      final configs = await _apiClient.getConfigs();
      final mode = configs['mode']?.toString().toLowerCase() ?? 'rule';

      state = state.copyWith(
        isRunning: true,
        pid: _processService!.pid,
        isProxyEnabled: true,
        currentMode: mode,
        isLoading: false,
      );

      _startTrafficMonitor();
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        isProxyEnabled: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 停止内核
  Future<void> stopCore() async {
    state = state.copyWith(isLoading: true);
    await _trafficSub?.cancel();
    _trafficSub = null;

    await WindowsProxyManager.disableProxy();
    await _processService?.stop();
    _processService = null;

    state = state.copyWith(
      isRunning: false,
      isProxyEnabled: false,
      pid: null,
      currentTraffic: const Traffic(),
      isLoading: false,
    );
  }

  /// 单独切换系统代理开关
  Future<void> toggleSystemProxy() async {
    if (state.isProxyEnabled) {
      await WindowsProxyManager.disableProxy();
      state = state.copyWith(isProxyEnabled: false);
    } else {
      await WindowsProxyManager.enableProxy(port: 7890);
      state = state.copyWith(isProxyEnabled: true);
    }
  }

  /// 切换分流模式 (Rule / Global / Direct)
  Future<void> setMode(String mode) async {
    try {
      await _apiClient.updateConfigs({'mode': mode});
      state = state.copyWith(currentMode: mode.toLowerCase());
    } catch (e) {
      state = state.copyWith(error: '切换模式失败: $e');
    }
  }

  void _startTrafficMonitor() {
    _trafficSub?.cancel();
    _trafficSub = _apiClient.getTrafficStream().listen((traffic) {
      final newHistory = List<Traffic>.from(state.trafficHistory)..add(traffic);
      if (newHistory.length > 30) {
        newHistory.removeAt(0);
      }
      state = state.copyWith(
        currentTraffic: traffic,
        trafficHistory: newHistory,
      );
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _trafficSub?.cancel();
    super.dispose();
  }
}

final appStateProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier();
});
