import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/logs_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getLevelColor(String type) {
    switch (type.toLowerCase()) {
      case 'error':
        return AppTheme.error;
      case 'warning':
      case 'warn':
        return const Color(0xFFFBBF24); // Amber
      case 'debug':
        return const Color(0xFFA78BFA); // Purple
      case 'info':
      default:
        return AppTheme.secondary; // Cyan
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(logsStateProvider);
    final logsNotifier = ref.read(logsStateProvider.notifier);
    final logs = logsState.filteredLogs;

    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!logsState.isPaused && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部操作栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '内核运行日志',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '实时跟踪 Mihomo 路由分流与代理核心控制台输出 (${logs.length} 条记录)',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // 日志级别切换
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighlight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: logsState.level,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textMuted),
                          items: const [
                            DropdownMenuItem(value: 'info', child: Text('级别: INFO')),
                            DropdownMenuItem(value: 'warning', child: Text('级别: WARN')),
                            DropdownMenuItem(value: 'error', child: Text('级别: ERROR')),
                            DropdownMenuItem(value: 'debug', child: Text('级别: DEBUG')),
                          ],
                          onChanged: (val) {
                            if (val != null) logsNotifier.setLevel(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 暂停/继续按钮
                    IconButton(
                      tooltip: logsState.isPaused ? '恢复滚动' : '暂停输出',
                      onPressed: () => logsNotifier.togglePause(),
                      icon: Icon(
                        logsState.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: logsState.isPaused ? AppTheme.secondary : AppTheme.textMuted,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceHighlight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 清屏按钮
                    IconButton(
                      tooltip: '清空日志记录',
                      onPressed: () => logsNotifier.clearLogs(),
                      icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.textMuted),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceHighlight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 搜索过滤栏
            TextField(
              onChanged: (val) => logsNotifier.setSearchKeyword(val),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: '过滤关键字 (如 Rule, Match, DNS, error)...',
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
            const SizedBox(height: 16),

            // 终端风格日志控制台
            Expanded(
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.terminal_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              '暂无内核日志输出 (请确保内核已启动并产生网络活动)',
                              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : SelectionArea(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final levelColor = _getLevelColor(log.type);

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: index % 2 == 0 ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 时间戳
                                  Text(
                                    log.formattedTime,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 级别徽章
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: levelColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.type.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: levelColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // 内容正文
                                  Expanded(
                                    child: Text(
                                      log.payload,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),

                                  // 单行复制小图标
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: '[${log.formattedTime}] [${log.type.toUpperCase()}] ${log.payload}'));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('已复制日志到剪贴板'),
                                          duration: Duration(seconds: 1),
                                          backgroundColor: AppTheme.primary,
                                        ),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
