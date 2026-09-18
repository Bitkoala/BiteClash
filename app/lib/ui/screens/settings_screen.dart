import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/mihomo_api_client.dart';
import '../../core/autostart/windows_autostart.dart';
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
  bool _autoStart = false;
  bool _isCheckingAutoStart = true;

  @override
  void initState() {
    super.initState();
    _fetchMemory();
    _checkAutoStart();
  }

  Future<void> _fetchMemory() async {
    final mem = await _apiClient.getMemoryInBytes();
    if (mounted) {
      setState(() {
        _memoryBytes = mem;
      });
    }
  }

  Future<void> _checkAutoStart() async {
    if (Platform.isWindows) {
      final enabled = await WindowsAutoStart.isAutoStartEnabled();
      if (mounted) {
        setState(() {
          _autoStart = enabled;
          _isCheckingAutoStart = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isCheckingAutoStart = false;
        });
      }
    }
  }

  Future<void> _toggleAutoStart(bool val) async {
    setState(() => _autoStart = val);
    final ok = await WindowsAutoStart.setAutoStart(val);
    if (!ok && mounted) {
      setState(() => _autoStart = !val);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('修改开机自启动失败，请以管理员权限运行尝试')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? '已开启 Windows 开机自启动' : '已关闭开机自启动'),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
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
              '配置底层代理网络端口、Windows 启动策略与内核运行参数',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),

            // 系统与托盘设置 (Windows 专属)
            if (Platform.isWindows) ...[
              const Text(
                '系统与后台运行',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                borderRadius: 18,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Windows 开机自启动',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '在登录 Windows 桌面后在后台自动启动 BiteClash',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        _isCheckingAutoStart
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Switch(
                                value: _autoStart,
                                activeThumbColor: AppTheme.primary,
                                onChanged: _toggleAutoStart,
                              ),
                      ],
                    ),
                    const Divider(color: AppTheme.borderLight, height: 28),
                    _buildSettingItem(
                      title: '关闭主窗口动作',
                      subtitle: '点击右上角关闭(X)时保持后台并最小化到托盘',
                      trailing: '最小化到托盘',
                    ),
                    const Divider(color: AppTheme.borderLight, height: 28),
                    _buildSettingItem(
                      title: '系统托盘支持',
                      subtitle: '任务栏右下角常驻托盘图标与快捷菜单',
                      trailing: '已启用',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

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
                    subtitle: 'BiteClash Universal Client (对标 Clash Verge Rev)',
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
                    trailing: Platform.isWindows ? 'Windows x64' : Platform.operatingSystem,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
