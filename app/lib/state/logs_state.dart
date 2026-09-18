import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/mihomo_api_client.dart';
import '../core/models/log_item.dart';

class LogsState {
  final List<LogItem> logs;
  final String searchKeyword;
  final bool isPaused;
  final String level; // info, warning, error, debug

  const LogsState({
    this.logs = const [],
    this.searchKeyword = '',
    this.isPaused = false,
    this.level = 'info',
  });

  List<LogItem> get filteredLogs {
    if (searchKeyword.isEmpty) return logs;
    final q = searchKeyword.toLowerCase();
    return logs.where((l) => l.payload.toLowerCase().contains(q)).toList();
  }

  LogsState copyWith({
    List<LogItem>? logs,
    String? searchKeyword,
    bool? isPaused,
    String? level,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      isPaused: isPaused ?? this.isPaused,
      level: level ?? this.level,
    );
  }
}

class LogsNotifier extends StateNotifier<LogsState> {
  final MihomoApiClient _apiClient = MihomoApiClient();
  StreamSubscription<LogItem>? _sub;

  LogsNotifier() : super(const LogsState()) {
    _startStream();
  }

  void _startStream() {
    _sub?.cancel();
    _sub = _apiClient.getLogsStream(level: state.level).listen((item) {
      if (state.isPaused) return;
      final newLogs = List<LogItem>.from(state.logs)..add(item);
      if (newLogs.length > 200) {
        newLogs.removeAt(0);
      }
      state = state.copyWith(logs: newLogs);
    }, onError: (_) {});
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void setSearchKeyword(String kw) {
    state = state.copyWith(searchKeyword: kw.trim());
  }

  void setLevel(String level) {
    if (state.level == level) return;
    state = state.copyWith(level: level);
    _startStream();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final logsStateProvider = StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  return LogsNotifier();
});
