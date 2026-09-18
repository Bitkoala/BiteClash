/// 单个网络连接明细模型
class ConnectionItem {
  final String id;
  final String host;
  final String destinationIP;
  final String destinationPort;
  final String network;
  final String type;
  final String processPath;
  final String processName;
  final int upload; // 累计上传字节数
  final int download; // 累计下载字节数
  final DateTime start;
  final List<String> chains;
  final String rule;
  final String rulePayload;

  const ConnectionItem({
    required this.id,
    required this.host,
    required this.destinationIP,
    required this.destinationPort,
    required this.network,
    required this.type,
    required this.processPath,
    required this.processName,
    required this.upload,
    required this.download,
    required this.start,
    required this.chains,
    required this.rule,
    required this.rulePayload,
  });

  factory ConnectionItem.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final procPath = meta['processPath'] as String? ?? '';
    String procName = '';
    if (procPath.isNotEmpty) {
      final sep = procPath.contains('\\') ? '\\' : '/';
      procName = procPath.split(sep).last;
    }
    if (procName.isEmpty) {
      procName = meta['process'] as String? ?? '';
    }
    if (procName.isEmpty) {
      procName = meta['type'] as String? ?? 'Network';
    }

    final chainsList = (json['chains'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final hostStr = meta['host'] as String? ?? '';
    final destIP = meta['destinationIP'] as String? ?? '';

    return ConnectionItem(
      id: json['id'] as String? ?? '',
      host: hostStr.isNotEmpty ? hostStr : destIP,
      destinationIP: destIP,
      destinationPort: meta['destinationPort']?.toString() ?? '',
      network: meta['network'] as String? ?? 'tcp',
      type: meta['type'] as String? ?? 'HTTP',
      processPath: procPath,
      processName: procName,
      upload: json['upload'] as int? ?? 0,
      download: json['download'] as int? ?? 0,
      start: DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now(),
      chains: chainsList,
      rule: json['rule'] as String? ?? '',
      rulePayload: json['rulePayload'] as String? ?? '',
    );
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(d >= 100 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  String get formattedUpload => formatBytes(upload);
  String get formattedDownload => formatBytes(download);
}
