import 'proxy_node.dart';

/// 策略组类型
enum ProxyGroupType {
  selector,
  urlTest,
  fallback,
  loadBalance,
  relay,
  unknown;

  static ProxyGroupType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'selector':
        return ProxyGroupType.selector;
      case 'urltest':
      case 'url-test':
        return ProxyGroupType.urlTest;
      case 'fallback':
        return ProxyGroupType.fallback;
      case 'loadbalance':
      case 'load-balance':
        return ProxyGroupType.loadBalance;
      case 'relay':
        return ProxyGroupType.relay;
      default:
        return ProxyGroupType.unknown;
    }
  }
}

/// 策略组模型 (如 PROXY, AUTO, GLOBAL)
class ProxyGroup {
  final String name;
  final ProxyGroupType groupType;
  final String rawType;
  final String now; // 当前选中的节点名称
  final List<String> all; // 组内所有节点/子策略组名称
  final int? delay;

  const ProxyGroup({
    required this.name,
    required this.groupType,
    required this.rawType,
    required this.now,
    required this.all,
    this.delay,
  });

  factory ProxyGroup.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'Selector';
    final allList = (json['all'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final historyList = (json['history'] as List<dynamic>?)
            ?.map((e) => DelayRecord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    int? currentDelay;
    if (historyList.isNotEmpty) {
      currentDelay = historyList.last.delay;
      if (currentDelay == 0) currentDelay = null;
    }

    return ProxyGroup(
      name: json['name'] as String? ?? '',
      groupType: ProxyGroupType.fromString(rawType),
      rawType: rawType,
      now: json['now'] as String? ?? '',
      all: allList,
      delay: currentDelay,
    );
  }

  ProxyGroup copyWith({String? now, int? delay}) {
    return ProxyGroup(
      name: name,
      groupType: groupType,
      rawType: rawType,
      now: now ?? this.now,
      all: all,
      delay: delay ?? this.delay,
    );
  }

  @override
  String toString() => 'ProxyGroup($name, type: $rawType, now: $now, nodes: ${all.length})';
}
