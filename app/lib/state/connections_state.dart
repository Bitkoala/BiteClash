import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/mihomo_api_client.dart';
import '../core/models/connection_item.dart';

class ConnectionsState {
  final int uploadTotal;
  final int downloadTotal;
  final List<ConnectionItem> connections;
  final String searchKeyword;
  final bool isLoading;

  const ConnectionsState({
    this.uploadTotal = 0,
    this.downloadTotal = 0,
    this.connections = const [],
    this.searchKeyword = '',
    this.isLoading = false,
  });

  List<ConnectionItem> get filteredConnections {
    if (searchKeyword.isEmpty) return connections;
    final q = searchKeyword.toLowerCase();
    return connections.where((c) {
      return c.host.toLowerCase().contains(q) ||
          c.processName.toLowerCase().contains(q) ||
          c.rule.toLowerCase().contains(q) ||
          c.chains.any((ch) => ch.toLowerCase().contains(q));
    }).toList();
  }

  ConnectionsState copyWith({
    int? uploadTotal,
    int? downloadTotal,
    List<ConnectionItem>? connections,
    String? searchKeyword,
    bool? isLoading,
  }) {
    return ConnectionsState(
      uploadTotal: uploadTotal ?? this.uploadTotal,
      downloadTotal: downloadTotal ?? this.downloadTotal,
      connections: connections ?? this.connections,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ConnectionsNotifier extends StateNotifier<ConnectionsState> {
  final MihomoApiClient _apiClient = MihomoApiClient();
  Timer? _timer;

  ConnectionsNotifier() : super(const ConnectionsState()) {
    startPolling();
  }

  void startPolling() {
    _timer?.cancel();
    _fetch();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _fetch());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void setSearchKeyword(String kw) {
    state = state.copyWith(searchKeyword: kw.trim());
  }

  Future<void> _fetch() async {
    try {
      final res = await _apiClient.getConnections();
      state = state.copyWith(
        uploadTotal: res.uploadTotal,
        downloadTotal: res.downloadTotal,
        connections: res.connections,
      );
    } catch (_) {}
  }

  Future<void> closeConnection(String id) async {
    await _apiClient.closeConnection(id);
    await _fetch();
  }

  Future<void> closeAllConnections() async {
    await _apiClient.closeAllConnections();
    await _fetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final connectionsStateProvider = StateNotifierProvider<ConnectionsNotifier, ConnectionsState>((ref) {
  return ConnectionsNotifier();
});
