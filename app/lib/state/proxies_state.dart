import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/mihomo_api_client.dart';
import '../../core/models/proxy_group.dart';
import '../../core/models/proxy_node.dart';

class ProxiesState {
  final Map<String, ProxyGroup> groups;
  final Map<String, ProxyNode> nodes;
  final bool isLoading;
  final Set<String> testingNodes;
  final String? error;

  const ProxiesState({
    this.groups = const {},
    this.nodes = const {},
    this.isLoading = false,
    this.testingNodes = const {},
    this.error,
  });

  ProxiesState copyWith({
    Map<String, ProxyGroup>? groups,
    Map<String, ProxyNode>? nodes,
    bool? isLoading,
    Set<String>? testingNodes,
    String? error,
  }) {
    return ProxiesState(
      groups: groups ?? this.groups,
      nodes: nodes ?? this.nodes,
      isLoading: isLoading ?? this.isLoading,
      testingNodes: testingNodes ?? this.testingNodes,
      error: error,
    );
  }
}

class ProxiesNotifier extends StateNotifier<ProxiesState> {
  final MihomoApiClient _apiClient = MihomoApiClient();

  ProxiesNotifier() : super(const ProxiesState()) {
    refresh();
  }

  /// 刷新所有策略组和节点
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.getProxiesAndGroups();
      state = state.copyWith(
        groups: res.groups,
        nodes: res.nodes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '获取节点列表失败 (内核是否已启动？)',
      );
    }
  }

  /// 为指定策略组切换选中的节点
  Future<void> selectNode(String groupName, String nodeName) async {
    // 乐观更新 (Optimistic UI)
    final currentGroup = state.groups[groupName];
    if (currentGroup != null) {
      final updatedGroups = Map<String, ProxyGroup>.from(state.groups);
      updatedGroups[groupName] = currentGroup.copyWith(now: nodeName);
      state = state.copyWith(groups: updatedGroups);
    }

    final success = await _apiClient.selectProxy(groupName, nodeName);
    if (!success) {
      // 切换失败则重新同步
      await refresh();
    }
  }

  /// 测试单个节点的延迟
  Future<void> testNodeDelay(String nodeName) async {
    state = state.copyWith(
      testingNodes: {...state.testingNodes, nodeName},
    );

    final delay = await _apiClient.getProxyDelay(nodeName);

    final updatedNodes = Map<String, ProxyNode>.from(state.nodes);
    final existingNode = updatedNodes[nodeName];
    if (existingNode != null) {
      updatedNodes[nodeName] = existingNode.copyWith(delay: delay);
    }

    final newTesting = Set<String>.from(state.testingNodes)..remove(nodeName);
    state = state.copyWith(
      nodes: updatedNodes,
      testingNodes: newTesting,
    );
  }

  /// 批量对策略组内的所有节点发起快速并发测速
  Future<void> testAllGroupNodes(String groupName) async {
    final group = state.groups[groupName];
    if (group == null) return;

    final targetNodes = group.all.where((name) => state.nodes.containsKey(name)).toList();
    if (targetNodes.isEmpty) return;

    state = state.copyWith(
      testingNodes: {...state.testingNodes, ...targetNodes},
    );

    // 控制并发度为 6
    const chunkSize = 6;
    for (int i = 0; i < targetNodes.length; i += chunkSize) {
      final chunk = targetNodes.sublist(
        i,
        i + chunkSize > targetNodes.length ? targetNodes.length : i + chunkSize,
      );

      await Future.wait(chunk.map((name) async {
        final delay = await _apiClient.getProxyDelay(name);
        final currentNodes = Map<String, ProxyNode>.from(state.nodes);
        if (currentNodes.containsKey(name)) {
          currentNodes[name] = currentNodes[name]!.copyWith(delay: delay);
          state = state.copyWith(nodes: currentNodes);
        }
      }));
    }

    final remaining = Set<String>.from(state.testingNodes)..removeAll(targetNodes);
    state = state.copyWith(testingNodes: remaining);
  }
}

final proxiesStateProvider = StateNotifierProvider<ProxiesNotifier, ProxiesState>((ref) {
  return ProxiesNotifier();
});
