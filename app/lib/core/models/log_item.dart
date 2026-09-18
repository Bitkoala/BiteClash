/// 内核日志条目模型
class LogItem {
  final String type; // info, warning, error, debug
  final String payload;
  final DateTime time;

  const LogItem({
    required this.type,
    required this.payload,
    required this.time,
  });

  factory LogItem.fromJson(Map<String, dynamic> json) {
    return LogItem(
      type: (json['type'] as String? ?? 'info').toLowerCase(),
      payload: json['payload'] as String? ?? '',
      time: DateTime.now(),
    );
  }

  String get formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
