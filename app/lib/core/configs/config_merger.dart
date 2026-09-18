import 'dart:io';
import 'package:yaml/yaml.dart';

/// 配置合并器与端口注入器 (保障任何外部机场订阅都能正常开启 7890 代理与 9090 控制端口)
class ConfigMerger {
  /// 处理并注入必要的控制与代理端口
  static Future<String> sanitizeAndMergeConfig(String rawYamlContent, {bool enableTun = false}) async {
    dynamic parsed;
    try {
      parsed = loadYaml(rawYamlContent);
    } catch (_) {
      parsed = null;
    }

    final buffer = StringBuffer();

    // 1. 强制写入核心代理与控制端口 (确保 100% 能够代理上网并与客户端通信)
    buffer.writeln('# --- BiteClash Injected Core Parameters ---');
    buffer.writeln('mixed-port: 7890');
    buffer.writeln('allow-lan: false');
    buffer.writeln('log-level: info');
    buffer.writeln('ipv6: false');
    buffer.writeln('external-controller: 127.0.0.1:9090');
    buffer.writeln('secret: ""');
    buffer.writeln('');

    // 2. 检查并注入可靠的 DNS 防污染与解析配置 (如机场未配置或配置不当)
    bool hasValidDns = false;
    if (parsed is YamlMap && parsed.containsKey('dns')) {
      final dns = parsed['dns'];
      if (dns is YamlMap && dns['enable'] == true) {
        hasValidDns = true;
      }
    }

    if (!hasValidDns) {
      buffer.writeln('# --- BiteClash Default Resilient DNS ---');
      buffer.writeln('dns:');
      buffer.writeln('  enable: true');
      buffer.writeln('  listen: 127.0.0.1:1053');
      buffer.writeln('  enhanced-mode: fake-ip');
      buffer.writeln('  fake-ip-range: 198.18.0.1/16');
      buffer.writeln('  nameserver:');
      buffer.writeln('    - 223.5.5.5');
      buffer.writeln('    - 119.29.29.29');
      buffer.writeln('    - 8.8.8.8');
      buffer.writeln('    - 1.1.1.1');
      buffer.writeln('');
    }

    // 3. 注入 TUN 网卡模式 (根据设置开启或关闭)
    buffer.writeln('# --- BiteClash TUN Mode Configuration ---');
    buffer.writeln('tun:');
    buffer.writeln('  enable: $enableTun');
    buffer.writeln('  stack: gvisor');
    buffer.writeln('  dns-hijack:');
    buffer.writeln('    - "any:53"');
    buffer.writeln('    - "tcp://any:53"');
    buffer.writeln('  auto-route: true');
    buffer.writeln('  auto-detect-interface: true');
    buffer.writeln('');

    // 4. 追加机场订阅原始规则、节点与策略组
    buffer.writeln('# --- Upstream Profile Rules & Proxies ---');
    buffer.writeln(rawYamlContent);

    return buffer.toString();
  }

  /// 写入预处理后的文件
  static Future<File> saveSanitizedProfile(String targetPath, String rawYaml, {bool enableTun = false}) async {
    final merged = await sanitizeAndMergeConfig(rawYaml, enableTun: enableTun);
    final file = File(targetPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    return await file.writeAsString(merged);
  }
}
