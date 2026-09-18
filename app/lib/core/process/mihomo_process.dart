import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../api/mihomo_api_client.dart';

/// Mihomo 内核进程管理器 (Windows 桌面端)
class MihomoProcessService {
  final String executablePath;
  final String workingDir;
  final String configPath;
  final int apiPort;
  final String apiSecret;

  Process? _process;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  MihomoProcessService({
    required this.executablePath,
    required this.workingDir,
    required this.configPath,
    this.apiPort = 9090,
    this.apiSecret = '',
  });

  bool get isRunning => _process != null;
  int? get pid => _process?.pid;

  /// 启动 Mihomo 内核并等待 API 端口健康检查通过
  Future<bool> start({Duration timeout = const Duration(seconds: 5)}) async {
    if (isRunning) return true;

    final exeFile = File(executablePath);
    if (!exeFile.existsSync()) {
      throw FileNotFoundException('Mihomo executable not found at: $executablePath');
    }

    final cfgFile = File(configPath);
    if (!cfgFile.existsSync()) {
      throw FileNotFoundException('Config file not found at: $configPath');
    }

    // 组装命令行参数: mihomo.exe -d <workingDir> -f <configPath>
    final args = [
      '-d',
      workingDir,
      '-f',
      configPath,
    ];

    try {
      _process = await Process.start(
        executablePath,
        args,
        workingDirectory: workingDir,
        mode: ProcessStartMode.normal,
      );

      _stdoutSub = _process!.stdout.transform(utf8.decoder).listen((data) {
        // 内核输出日志 (可接入应用日志流)
      });

      _stderrSub = _process!.stderr.transform(utf8.decoder).listen((data) {
        // 内核错误日志
      });

      // 监听进程非预期退出
      _process!.exitCode.then((code) {
        _process = null;
        _stdoutSub?.cancel();
        _stderrSub?.cancel();
      });

      // 进行 API 就绪健康检测轮询
      final client = MihomoApiClient(port: apiPort, secret: apiSecret);
      final startTime = DateTime.now();

      while (DateTime.now().difference(startTime) < timeout) {
        if (_process == null) return false; // 进程启动瞬间异常退出了
        try {
          final ver = await client.getVersion();
          if (ver.containsKey('version')) {
            return true;
          }
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      // 超时仍未响应 API
      await stop();
      return false;
    } catch (e) {
      await stop();
      rethrow;
    }
  }

  /// 安全停止内核进程
  Future<void> stop() async {
    if (_process == null) return;

    try {
      _process!.kill(ProcessSignal.sigterm);
      // 等待最长 1 秒让其正常清理连接退出
      await _process!.exitCode.timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          _process?.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    } catch (_) {
      try {
        _process?.kill();
      } catch (_) {}
    } finally {
      _process = null;
      await _stdoutSub?.cancel();
      await _stderrSub?.cancel();
      _stdoutSub = null;
      _stderrSub = null;
    }
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => 'FileNotFoundException: $message';
}
