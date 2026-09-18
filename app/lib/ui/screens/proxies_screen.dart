import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/proxy_group.dart';
import '../../state/proxies_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/latency_badge.dart';

class ProxiesScreen extends ConsumerWidget {
  const ProxiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxiesState = ref.watch(proxiesStateProvider);
    final proxiesNotifier = ref.read(proxiesStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // 顶部栏
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '节点与策略组',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '点击卡片快速切换出站出口，支持分组并发延迟测速',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  // 刷新按钮
                  ElevatedButton.icon(
                    onPressed: proxiesState.isLoading ? null : () => proxiesNotifier.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceHighlight,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    icon: proxiesState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('刷新状态'),
                  ),
                ],
              ),
            ),
          ),

          if (proxiesState.groups.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      proxiesState.error ?? '暂未读取到策略组 (请先在仪表盘启动内核)',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            // 策略组卡片列表
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final groupName = proxiesState.groups.keys.elementAt(index);
                    final group = proxiesState.groups[groupName]!;
                    return _buildGroupSection(context, group, proxiesState, proxiesNotifier);
                  },
                  childCount: proxiesState.groups.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildGroupSection(
    BuildContext context,
    ProxyGroup group,
    ProxiesState state,
    ProxiesNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 策略组标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        group.rawType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${group.all.length})',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),

                // 批量测速按钮
                TextButton.icon(
                  onPressed: () => notifier.testAllGroupNodes(group.name),
                  icon: const Icon(Icons.speed_rounded, size: 16, color: AppTheme.secondary),
                  label: const Text(
                    '测速全部',
                    style: TextStyle(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 组内节点网格列表 (自适应多列)
            LayoutBuilder(
              builder: (context, constraints) {
                // 根据屏幕宽度自适应 1~3 列
                final crossAxisCount = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 550
                        ? 2
                        : 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollExceptionScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 64,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: group.all.length,
                  itemBuilder: (context, idx) {
                    final nodeName = group.all[idx];
                    final node = state.nodes[nodeName];
                    final isSelected = group.now == nodeName;
                    final isTesting = state.testingNodes.contains(nodeName);

                    return _buildNodeCard(
                      context,
                      nodeName: nodeName,
                      nodeType: node?.type ?? 'Direct',
                      delay: node?.delay,
                      isSelected: isSelected,
                      isTesting: isTesting,
                      onTap: () => notifier.selectNode(group.name, nodeName),
                      onTestTap: () => notifier.testNodeDelay(nodeName),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeCard(
    BuildContext context, {
    required String nodeName,
    required String nodeType,
    required int? delay,
    required bool isSelected,
    required bool isTesting,
    required VoidCallback onTap,
    required VoidCallback onTestTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceHighlight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // 选中指示标记
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                ),
              ),
              const SizedBox(width: 8),

              // 节点名称与协议
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nodeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nodeType.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),

              // 延迟徽章
              LatencyBadge(
                delay: delay,
                isTesting: isTesting,
                onTap: onTestTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
