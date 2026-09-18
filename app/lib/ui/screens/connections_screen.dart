import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/connection_item.dart';
import '../../state/connections_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(connectionsStateProvider);
    final connNotifier = ref.read(connectionsStateProvider.notifier);
    final list = connState.filteredConnections;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // 顶部栏
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '活跃网络连接审计',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '当前活跃连接数: ${connState.connections.length} • 累计传输: ↑ ${ConnectionItem.formatBytes(connState.uploadTotal)} | ↓ ${ConnectionItem.formatBytes(connState.downloadTotal)}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      // 一键断开全部连接按钮
                      ElevatedButton.icon(
                        onPressed: connState.connections.isEmpty
                            ? null
                            : () async {
                                await connNotifier.closeAllConnections();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('已重置并断开所有网络连接'),
                                      backgroundColor: AppTheme.primary,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error.withValues(alpha: 0.15),
                          foregroundColor: AppTheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.link_off_rounded, size: 18),
                        label: const Text('断开全部'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 搜索检索框
                  TextField(
                    onChanged: (val) => connNotifier.setSearchKeyword(val),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '检索目标域名、进程名 (如 chrome.exe、git) 或分流规则...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.surfaceHighlight.withValues(alpha: 0.6),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 连接列表
          if (list.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_tethering_off_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      connState.connections.isEmpty
                          ? '暂无活跃网络连接 (打开浏览器访问网页即可在此实时查看)'
                          : '没有找到匹配的连接',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = list[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // 进程徽章
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.apps_rounded, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 14),

                            // 主机与规则
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.host,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.destinationPort.isNotEmpty)
                                        Text(
                                          ':${item.destinationPort}',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.network.toUpperCase(),
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        item.processName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.chains.isNotEmpty
                                              ? '${item.rule} ➔ ${item.chains.join(" ➔ ")}'
                                              : item.rule,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 上下行流量
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '↓ ${item.formattedDownload}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '↑ ${item.formattedUpload}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // 断开单个连接按钮
                            IconButton(
                              onPressed: () => connNotifier.closeConnection(item.id),
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                              tooltip: '断开此连接',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: list.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
