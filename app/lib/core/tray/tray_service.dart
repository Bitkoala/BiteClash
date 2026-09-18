import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../proxy/windows_proxy.dart';

/// 桌面端系统托盘与无感后台常驻管理器
class TrayService with TrayListener, WindowListener {
  static final TrayService instance = TrayService._();
  TrayService._();

  bool _initialized = false;

  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    if (_initialized) return;
    _initialized = true;

    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);
      trayManager.addListener(this);

      // 设置窗口关闭时拦截 (实现点击 X 最小化到系统托盘)
      await windowManager.setPreventClose(true);

      // 初始化右下角托盘图标
      final iconPath = Platform.isWindows ? 'assets/icons/app_icon.ico' : 'assets/icons/app_icon.png';
      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('BiteClash 代理客户端');

      final menu = Menu(
        items: [
          MenuItem(
            key: 'show_window',
            label: '显示 BiteClash 主窗口',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'toggle_proxy',
            label: '切换系统代理 (开/关)',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: '完全退出',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);
    } catch (_) {}
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'toggle_proxy':
        final status = await WindowsProxyManager.getProxyStatus();
        if (status.enabled) {
          await WindowsProxyManager.disableProxy();
        } else {
          await WindowsProxyManager.enableProxy(port: 7890);
        }
        break;
      case 'exit_app':
        await WindowsProxyManager.disableProxy();
        await windowManager.destroy();
        exit(0);
    }
  }

  @override
  void onWindowClose() async {
    // 拦截点击关闭按钮，缩进托盘
    final isPrevent = await windowManager.isPreventClose();
    if (isPrevent) {
      await windowManager.hide();
    }
  }
}
