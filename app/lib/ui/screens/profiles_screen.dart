import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/profiles_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesState = ref.watch(profilesStateProvider);
    final profilesNotifier = ref.read(profilesStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部栏与添加按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '订阅配置中心',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '支持导入 Clash YAML 订阅规则，一键热重载至内核',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context, profilesNotifier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('添加订阅', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (profilesState.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        profilesState.error!,
                        style: const TextStyle(fontSize: 13, color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),

            // 订阅列表
            if (profilesState.profiles.isEmpty)
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.folder_zip_outlined, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      const Text(
                        '暂无外部订阅',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '当前使用内核缺省配置，点击右上角可导入机场订阅链接',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profilesState.profiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final profile = profilesState.profiles[index];
                  final isActive = profilesState.activeProfileId == profile.id;

                  return GlassContainer(
                    borderRadius: 18,
                    glow: isActive,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.primary.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.cloud_done_rounded,
                                color: isActive ? AppTheme.primary : AppTheme.textMuted,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      profile.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '生效中',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '包含 ${profile.nodeCount} 个节点 • 更新于 ${_formatDate(profile.updatedAt)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // 操作按钮组
                        Row(
                          children: [
                            if (!isActive)
                              TextButton(
                                onPressed: () => profilesNotifier.applyProfile(profile.id),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('应用此配置'),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => profilesNotifier.deleteProfile(profile.id),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                              tooltip: '删除此订阅',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showAddDialog(BuildContext context, ProfilesNotifier notifier) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('添加 Clash 订阅源', style: TextStyle(color: AppTheme.textPrimary)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: '订阅名称',
                  hintText: '例如：主力机场',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceHighlight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: '订阅链接 URL',
                  hintText: 'https://...',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceHighlight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (url.isEmpty) return;

              Navigator.pop(ctx);
              await notifier.addSubscription(name, url);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('下载并保存'),
          ),
        ],
      ),
    );
  }
}
