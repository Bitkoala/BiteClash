import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class RemoteControllerView extends ConsumerStatefulWidget {
  const RemoteControllerView({super.key});

  @override
  ConsumerState<RemoteControllerView> createState() =>
      _RemoteControllerViewState();
}

class _RemoteControllerViewState extends ConsumerState<RemoteControllerView> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _secretController;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(remoteControllerProvider);
    _hostController = TextEditingController(text: state.host);
    _portController = TextEditingController(text: state.port.toString());
    _secretController = TextEditingController(text: state.secret);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  void _saveCurrentConfig() {
    final port = int.tryParse(_portController.text.trim()) ?? 9090;
    ref
        .read(remoteControllerProvider.notifier)
        .updateConfig(
          host: _hostController.text.trim(),
          port: port,
          secret: _secretController.text.trim(),
        );
  }

  void _applyPreset(String host, int port) {
    _hostController.text = host;
    _portController.text = port.toString();
    _saveCurrentConfig();
  }

  @override
  Widget build(BuildContext context) {
    final remoteState = ref.watch(remoteControllerProvider);
    final colorScheme = context.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BaseScaffold(
      title: '远程核心托管 (Remote Core)',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B).withValues(alpha: 0.6),
                      ]
                    : [
                        Colors.white,
                        colorScheme.primaryContainer.withValues(alpha: 0.25),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: remoteState.enabled
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : (isDark
                          ? const Color(0xFF334155)
                          : colorScheme.outlineVariant.withValues(alpha: 0.4)),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.hub_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '超级网络枢纽模式',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            remoteState.enabled
                                ? '已启用: 当前托管远程核心 (http://${remoteState.host}:${remoteState.port})'
                                : '已关闭: 当前运行本机独立核心',
                            style: TextStyle(
                              fontSize: 12,
                              color: remoteState.enabled
                                  ? const Color(0xFF10B981)
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: remoteState.enabled,
                      onChanged: (val) {
                        _saveCurrentConfig();
                        ref
                            .read(remoteControllerProvider.notifier)
                            .toggleEnabled(val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '接管软路由 (OpenWrt / iStoreOS)、家庭 NAS (Docker 旁路由容器) 或局域网内任意 Mihomo 核心。开启后，本客户端将转变为专属网络遥控器，实时同步节点分组、分流策略与流量监控。',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '快捷预设设备',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.router, size: 16),
                label: const Text('OpenWrt 软路由 (192.168.1.1)'),
                onPressed: () => _applyPreset('192.168.1.1', 9090),
              ),
              ActionChip(
                avatar: const Icon(Icons.dns, size: 16),
                label: const Text('Docker 旁路由 (192.168.1.2)'),
                onPressed: () => _applyPreset('192.168.1.2', 9090),
              ),
              ActionChip(
                avatar: const Icon(Icons.computer, size: 16),
                label: const Text('本机容器 (127.0.0.1)'),
                onPressed: () => _applyPreset('127.0.0.1', 9090),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '远程核心连接参数',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: '服务器 IP 或域名 (Host)',
              hintText: '例如: 192.168.1.1 或 openwrt.lan',
              prefixIcon: Icon(Icons.lan_rounded),
            ),
            onChanged: (_) => _saveCurrentConfig(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Controller API 端口 (Port)',
              hintText: '默认 9090',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
            onChanged: (_) => _saveCurrentConfig(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _secretController,
            obscureText: _obscureSecret,
            decoration: InputDecoration(
              labelText: 'API 访问密钥 (Secret / Token)',
              hintText: '无密钥请留空',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                tooltip: _obscureSecret ? 'Show secret' : 'Hide secret',
                icon: Icon(
                  _obscureSecret ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureSecret = !_obscureSecret;
                  });
                },
              ),
            ),
            onChanged: (_) => _saveCurrentConfig(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: remoteState.testing
                      ? null
                      : () {
                          _saveCurrentConfig();
                          ref
                              .read(remoteControllerProvider.notifier)
                              .testConnection();
                        },
                  icon: remoteState.testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check_rounded),
                  label: Text(remoteState.testing ? '正在测速...' : '测试连通性'),
                ),
              ),
            ],
          ),
          if (remoteState.testResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: remoteState.testSuccess == true
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: remoteState.testSuccess == true
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    remoteState.testSuccess == true
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: remoteState.testSuccess == true
                        ? const Color(0xFF10B981)
                        : colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      remoteState.testResult!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: remoteState.testSuccess == true
                            ? const Color(0xFF10B981)
                            : colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
