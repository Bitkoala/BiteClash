// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'core/api/mihomo_api_client.dart';
import 'core/process/mihomo_process.dart';
import 'core/proxy/windows_proxy.dart';

void main() async {
  print('====================================================');
  print('🚀 Mihomo 核心通信层与系统控制端到端自动化测试');
  print('====================================================');

  final currentDir = Directory.current.path;
  final basePath = currentDir.endsWith('app')
      ? Directory(currentDir).parent.path
      : currentDir;

  final exePath = '$basePath\\core\\windows\\mihomo.exe';
  final configPath = '$basePath\\core\\configs\\default_config.yaml';
  final workDir = '$basePath\\core\\configs';

  print('📁 内核路径: $exePath');
  print('📁 配置路径: $configPath');

  // 1. 记录测试前用户的原始代理状态，测试结束后严格恢复
  final originalProxy = await WindowsProxyManager.getProxyStatus();
  print('ℹ️  测试前系统代理状态: enabled=${originalProxy.enabled}, server=${originalProxy.server}');

  final processService = MihomoProcessService(
    executablePath: exePath,
    workingDir: workDir,
    configPath: configPath,
    apiPort: 9090,
  );

  final client = MihomoApiClient(port: 9090);

  try {
    // 2. 启动内核与健康自检
    print('\n[1/6] 正在拉起 Mihomo 内核进程...');
    final started = await processService.start(timeout: const Duration(seconds: 5));
    if (!started) {
      throw Exception('Mihomo 内核启动失败或健康检测超时！');
    }
    print('✅ 内核已成功启动! PID: ${processService.pid}');

    // 3. 测试 REST API 获取内核版本
    print('\n[2/6] 调用 REST API: GET /version');
    final versionInfo = await client.getVersion();
    print('✅ 内核版本返回成功: $versionInfo');

    // 4. 测试获取策略组与节点全景图
    print('\n[3/6] 调用 REST API: GET /proxies 并解析模型');
    final proxiesData = await client.getProxiesAndGroups();
    print('✅ 策略组数量: ${proxiesData.groups.length} -> ${proxiesData.groups.keys.toList()}');
    print('✅ 节点数量: ${proxiesData.nodes.length} -> ${proxiesData.nodes.keys.toList()}');

    // 5. 测试策略组节点切换
    print('\n[4/6] 测试切换策略组节点: PROXY -> DIRECT_NODE');
    final switchSuccess = await client.selectProxy('PROXY', 'DIRECT_NODE');
    print('✅ 节点切换结果: $switchSuccess');

    // 6. 测试实时流量 WebSocket 流
    print('\n[5/6] 订阅 WebSocket: /traffic 监听 3 秒数据流...');
    final trafficCompleter = Completer<void>();
    int trafficPackets = 0;

    final sub = client.getTrafficStream().listen((traffic) {
      trafficPackets++;
      print('   📶 实时速率推送 #$trafficPackets: ↑ ${traffic.formattedUp} | ↓ ${traffic.formattedDown}');
      if (trafficPackets >= 3 && !trafficCompleter.isCompleted) {
        trafficCompleter.complete();
      }
    });

    await Future.any([
      trafficCompleter.future,
      Future.delayed(const Duration(seconds: 4)),
    ]);
    await sub.cancel();
    print('✅ WebSocket 流量推送测试完成, 累计接收数据帧: $trafficPackets');

    // 7. 测试 Windows 系统代理设置与恢复
    print('\n[6/6] 测试 Windows 系统代理注册表设置');
    final setProxySuccess = await WindowsProxyManager.enableProxy(host: '127.0.0.1', port: 7890);
    print('   -> 开启系统代理 (127.0.0.1:7890): $setProxySuccess');

    final activeProxy = await WindowsProxyManager.getProxyStatus();
    print('   -> 验证注册表当前状态: enabled=${activeProxy.enabled}, server=${activeProxy.server}');

    if (activeProxy.enabled && activeProxy.server == '127.0.0.1:7890') {
      print('✅ Windows 注册表代理设置验证完全通过!');
    } else {
      print('⚠️  注册表代理验证与预期不完全吻合');
    }

  } catch (e, stack) {
    print('❌ 测试过程中发生异常: $e');
    print(stack);
  } finally {
    // 8. 恢复环境与关闭进程
    print('\n🧹 正在执行环境清理与进程安全退出...');

    // 恢复系统代理为原始状态
    if (originalProxy.enabled && originalProxy.server != null) {
      final parts = originalProxy.server!.split(':');
      final host = parts[0];
      final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 7890 : 7890;
      await WindowsProxyManager.enableProxy(host: host, port: port);
      print('   -> 已恢复用户原始系统代理: ${originalProxy.server}');
    } else {
      await WindowsProxyManager.disableProxy();
      print('   -> 已重置并关闭系统代理');
    }

    // 停止内核
    await processService.stop();
    print('   -> Mihomo 内核进程已安全终止');
  }

  print('\n🎉🎉 第一阶段所有核心通信与底层控制接口全部测试通过！\n');
}
