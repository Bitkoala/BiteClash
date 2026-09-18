/// 节点延迟历史记录
class DelayRecord {
  final DateTime time;
  final int delay; // 毫秒

  const DelayRecord({required this.time, required this.delay});

  factory DelayRecord.fromJson(Map<String, dynamic> json) {
    return DelayRecord(
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      delay: json['delay'] as int? ?? 0,
    );
  }
}

/// 代理节点模型
class ProxyNode {
  final String name;
  final String type;
  final bool udp;
  final bool alive;
  final List<DelayRecord> history;
  final int? delay; // 最近一次延迟测速结果 (ms)，0 或 null 表示未测或超时

  const ProxyNode({
    required this.name,
    required this.type,
    this.udp = false,
    this.alive = true,
    this.history = const [],
    this.delay,
  });

  factory ProxyNode.fromJson(Map<String, dynamic> json) {
    final historyList = (json['history'] as List<dynamic>?)
            ?.map((e) => DelayRecord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    int? currentDelay;
    if (historyList.isNotEmpty) {
      currentDelay = historyList.last.delay;
      if (currentDelay == 0) currentDelay = null;
    }

    return ProxyNode(
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'Direct',
      udp: json['udp'] as bool? ?? false,
      alive: json['alive'] as bool? ?? true,
      history: historyList,
      delay: currentDelay,
    );
  }

  ProxyNode copyWith({int? delay, bool? alive}) {
    return ProxyNode(
      name: name,
      type: type,
      udp: udp,
      alive: alive ?? this.alive,
      history: history,
      delay: delay ?? this.delay,
    );
  }

  @override
  String toString() => 'ProxyNode($name, type: $type, delay: ${delay ?? "timeout"}ms)';
}
