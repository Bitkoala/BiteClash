import 'dart:io';

/// Windows 开机自启动管理器
class WindowsAutoStart {
  static const String _regKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const String _appName = 'BiteClash';

  /// 检查是否已开启开机自启
  static Future<bool> isAutoStartEnabled() async {
    if (!Platform.isWindows) return false;

    try {
      final res = await Process.run('reg', [
        'query',
        _regKey,
        '/v',
        _appName,
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 设置开启或关闭开机自启
  static Future<bool> setAutoStart(bool enable) async {
    if (!Platform.isWindows) return false;

    try {
      if (enable) {
        final exePath = Platform.resolvedExecutable;
        final res = await Process.run('reg', [
          'add',
          _regKey,
          '/v',
          _appName,
          '/t',
          'REG_SZ',
          '/d',
          '"$exePath"',
          '/f',
        ]);
        return res.exitCode == 0;
      } else {
        final res = await Process.run('reg', [
          'delete',
          _regKey,
          '/v',
          _appName,
          '/f',
        ]);
        return res.exitCode == 0;
      }
    } catch (_) {
      return false;
    }
  }
}
