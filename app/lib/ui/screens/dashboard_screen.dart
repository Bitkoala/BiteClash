import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/traffic_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final appNotifier = ref.read(appStateProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题与快速状态
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '控制中心',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.isRunning ? '内核正常运行中 (PID: ${appState.pid})' : '内核未运行，点击下方开启',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              // 模式切换胶囊
              _buildModeSelector(context, appState, appNotifier),
            ],
          ),
          const SizedBox(height: 24),

          // 主控制大卡片：一键开关与状态显示
          _buildHeroControlCard(context, appState, appNotifier),
          const SizedBox(height: 20),

          // 上下行速率实时数据卡片 (网格两列)
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: '下行速率 (Download)',
                  value: appState.currentTraffic.formattedDown,
                  icon: Icons.arrow_downward_rounded,
                  color: AppTheme.secondary,
                  gradient: AppTheme.successGradient,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: '上行速率 (Upload)',
                  value: appState.currentTraffic.formattedUp,
                  icon: Icons.arrow_upward_rounded,
                  color: AppTheme.primary,
                  gradient: AppTheme.primaryGradient,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 实时流量波形图卡片
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.show_chart_rounded, size: 20, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          '实时带宽流动监控',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    // 图例标识
                    Row(
                      children: [
                        _buildLegendItem('下行 (Down)', AppTheme.secondary),
                        const SizedBox(width: 16),
                        _buildLegendItem('上行 (Up)', AppTheme.primary),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TrafficChart(history: appState.trafficHistory, height: 160),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 系统代理快速控制卡片
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_rounded, size: 22, color: AppTheme.warning),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Windows 系统代理接管',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                        Text(
                          '自动配置系统 HTTP 代理 (127.0.0.1:7890)',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: appState.isProxyEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => appNotifier.toggleSystemProxy(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context, AppState state, AppNotifier notifier) {
    final modes = ['rule', 'global', 'direct'];
    final labels = {'rule': '规则分流', 'global': '全局代理', 'direct': '全量直连'};

    return GlassContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final isSelected = state.currentMode == m;
          return InkWell(
            onTap: () => notifier.setMode(m),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                labels[m]!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroControlCard(BuildContext context, AppState state, AppNotifier notifier) {
    final isRunning = state.isRunning;

    return GlassContainer(
      borderRadius: 24,
      glow: isRunning,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 状态呼吸灯圆圈
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isRunning ? AppTheme.successGradient : null,
                  color: isRunning ? null : Colors.white.withValues(alpha: 0.06),
                  boxShadow: isRunning
                      ? [
                          BoxShadow(
                            color: AppTheme.secondary.withValues(alpha: 0.45),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isRunning ? Icons.shield_rounded : Icons.power_settings_new_rounded,
                  color: isRunning ? Colors.white : AppTheme.textMuted,
                  size: 30,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRunning ? '已保护，代理服务运转中' : '代理服务已就绪',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRunning
                        ? '混合端口 7890 | 控制端口 9090'
                        : '点击右侧按钮启动内核并接管系统流量',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),

          // 主开关按钮
          ElevatedButton(
            onPressed: state.isLoading ? null : () => notifier.toggleCoreAndProxy(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRunning ? AppTheme.error.withValues(alpha: 0.2) : AppTheme.primary,
              foregroundColor: isRunning ? AppTheme.error : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isRunning ? AppTheme.error.withValues(alpha: 0.5) : Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRunning ? '停止连接' : '一键启动',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
