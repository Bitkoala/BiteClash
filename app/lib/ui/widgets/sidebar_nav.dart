import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const navItems = [
  NavItemData(
    icon: Icons.speed_outlined,
    activeIcon: Icons.speed_rounded,
    label: '仪表盘',
  ),
  NavItemData(
    icon: Icons.hub_outlined,
    activeIcon: Icons.hub_rounded,
    label: '节点策略',
  ),
  NavItemData(
    icon: Icons.cloud_download_outlined,
    activeIcon: Icons.cloud_download_rounded,
    label: '订阅管理',
  ),
  NavItemData(
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune_rounded,
    label: '核心设置',
  ),
];

/// 桌面端左侧悬浮玻璃导航栏
class SidebarNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SidebarNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        borderRadius: 24,
        child: Column(
          children: [
            // App Logo & 标语
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antigravity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Universal Proxy',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),

            // 导航按钮列表
            Expanded(
              child: ListView.separated(
                itemCount: navItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final isSelected = selectedIndex == index;

                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(14),
                      hoverColor: AppTheme.primary.withValues(alpha: 0.08),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary.withValues(alpha: 0.4) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 20,
                              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 底部版本与内核状态标签
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 16, color: AppTheme.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Mihomo Meta Core',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 移动端底部毛玻璃 Dock 导航栏
class BottomDockNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const BottomDockNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isSelected = selectedIndex == index;

            return InkWell(
              onTap: () => onDestinationSelected(index),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 22,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
