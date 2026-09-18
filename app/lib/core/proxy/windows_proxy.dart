import 'dart:io';

/// Windows 系统代理管理 (操作 Windows 注册表)
class WindowsProxyManager {
  static const String _regKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';

  /// 开启系统代理
  static Future<bool> enableProxy({String host = '127.0.0.1', int port = 7890}) async {
    if (!Platform.isWindows) return false;

    final proxyServer = '$host:$port';
    try {
      // 设置 ProxyServer
      final setServerResult = await Process.run('reg', [
        'add',
        _regKey,
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        proxyServer,
        '/f',
      ]);

      if (setServerResult.exitCode != 0) return false;

      // 开启 ProxyEnable = 1
      final setEnableResult = await Process.run('reg', [
        'add',
        _regKey,
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f',
      ]);

      return setEnableResult.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 关闭系统代理
  static Future<bool> disableProxy() async {
    if (!Platform.isWindows) return false;

    try {
      final res = await Process.run('reg', [
        'add',
        _regKey,
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f',
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 查询当前系统代理状态
  static Future<({bool enabled, String? server})> getProxyStatus() async {
    if (!Platform.isWindows) return (enabled: false, server: null);

    try {
      final res = await Process.run('reg', [
        'query',
        _regKey,
        '/v',
        'ProxyEnable',
      ]);

      final output = res.stdout.toString();
      final isEnabled = output.contains('0x1');

      String? server;
      final serverRes = await Process.run('reg', [
        'query',
        _regKey,
        '/v',
        'ProxyServer',
      ]);
      final serverOut = serverRes.stdout.toString();
      final match = RegExp(r'ProxyServer\s+REG_SZ\s+(.+)').firstMatch(serverOut);
      if (match != null) {
        server = match.group(1)?.trim();
      }

      return (enabled: isEnabled, server: server);
    } catch (_) {
      return (enabled: false, server: null);
    }
  }
}
