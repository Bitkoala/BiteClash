import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/mihomo_api_client.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final MihomoApiClient _apiClient = MihomoApiClient();
  int _memoryBytes = 0;

  @override
  void initState() {
    super.initState();
    _fetchMemory();
  }

  Future<void> _fetchMemory() async {
    final mem = await _apiClient.getMemoryInBytes();
    if (mounted) {
      setState(() {
        _memoryBytes = mem;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '核心设置与参数',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '配置底层代理网络端口、内核资源占用与分流策略参数',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),

            // 端口设置组
            const Text(
              '网络与端口配置',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSettingItem(
                    title: 'HTTP/SOCKS5 混合代理端口 (Mixed Port)',
                    subtitle: '局域网与本地应用接入的代理入口',
                    trailing: '7890',
                  ),
                  const Divider(color: AppTheme.borderLight, height: 28),
                  _buildSettingItem(
                    title: 'RESTful API 控制器端口 (External Controller)',
                    subtitle: 'GUI 客户端与内核通信端口',
                    trailing: '9090',
                  ),
                  const Divider(color: AppTheme.borderLight, height: 28),
                  _buildSettingItem(
                    title: '内核运行时内存占用',
                    subtitle: 'Mihomo 当前 Resident Memory',
                    trailing: appState.isRunning ? _formatBytes(_memoryBytes) : '未启动',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 关于与内核信息
            const Text(
              '软件与内核信息',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSettingItem(
                    title: '客户端版本',
                    subtitle: 'BiteClash Universal Client',
                    trailing: 'v1.0.0-beta',
                  ),
                  const Divider(color: AppTheme.borderLight, height: 28),
                  _buildSettingItem(
                    title: '内核程序 (Core Engine)',
                    subtitle: 'MetaCubeX Mihomo Meta with gVisor TUN',
                    trailing: 'v1.19.31 (amd64)',
                  ),
                  const Divider(color: AppTheme.borderLight, height: 28),
                  _buildSettingItem(
                    title: '运行平台架构',
                    subtitle: 'Windows Desktop / Native C-Core Pipe',
                    trailing: 'Windows x64',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
