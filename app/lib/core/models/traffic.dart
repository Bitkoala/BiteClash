/// 实时上行与下行流量速率模型
class Traffic {
  final int up; // 字节/秒
  final int down; // 字节/秒

  const Traffic({
    this.up = 0,
    this.down = 0,
  });

  factory Traffic.fromJson(Map<String, dynamic> json) {
    return Traffic(
      up: json['up'] is int ? json['up'] as int : int.tryParse(json['up']?.toString() ?? '0') ?? 0,
      down: json['down'] is int ? json['down'] as int : int.tryParse(json['down']?.toString() ?? '0') ?? 0,
    );
  }

  /// 格式化为人类可读字符串 (如 1.2 MB/s, 350 KB/s)
  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var i = 0;
    double speed = bytesPerSecond.toDouble();
    while (speed >= 1024 && i < suffixes.length - 1) {
      speed /= 1024;
      i++;
    }
    return '${speed.toStringAsFixed(speed >= 100 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  String get formattedUp => formatSpeed(up);
  String get formattedDown => formatSpeed(down);

  @override
  String toString() => 'Traffic(↑ $formattedUp, ↓ $formattedDown)';
}
