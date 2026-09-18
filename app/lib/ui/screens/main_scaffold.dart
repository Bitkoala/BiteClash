import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar_nav.dart';
import 'dashboard_screen.dart';
import 'profiles_screen.dart';
import 'proxies_screen.dart';
import 'settings_screen.dart';

/// 全平台主框架 (支持多端自适应布局)
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    ProxiesScreen(),
    ProfilesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 全局错误提示条
              if (appState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.error.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appState.error!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),

              // 自适应主内容区
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 768;

                    if (isDesktop) {
                      // 宽屏/桌面端：左侧侧边栏 + 右侧主内容
                      return Row(
                        children: [
                          SidebarNav(
                            selectedIndex: _currentIndex,
                            onDestinationSelected: (index) {
                              setState(() => _currentIndex = index);
                            },
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _screens[_currentIndex],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // 窄屏/移动端：主内容 + 底部 Dock
                      return Column(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _screens[_currentIndex],
                            ),
                          ),
                          BottomDockNav(
                            selectedIndex: _currentIndex,
                            onDestinationSelected: (index) {
                              setState(() => _currentIndex = index);
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
