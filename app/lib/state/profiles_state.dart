import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';
import '../../core/api/mihomo_api_client.dart';

class ProfileItem {
  final String id;
  final String name;
  final String url;
  final DateTime updatedAt;
  final int nodeCount;

  const ProfileItem({
    required this.id,
    required this.name,
    required this.url,
    required this.updatedAt,
    this.nodeCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'updatedAt': updatedAt.toIso8601String(),
        'nodeCount': nodeCount,
      };

  factory ProfileItem.fromJson(Map<String, dynamic> json) => ProfileItem(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        nodeCount: json['nodeCount'] as int? ?? 0,
      );
}

class ProfilesState {
  final List<ProfileItem> profiles;
  final String? activeProfileId;
  final bool isLoading;
  final String? error;

  const ProfilesState({
    this.profiles = const [],
    this.activeProfileId,
    this.isLoading = false,
    this.error,
  });

  ProfilesState copyWith({
    List<ProfileItem>? profiles,
    String? activeProfileId,
    bool? isLoading,
    String? error,
  }) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfilesNotifier extends StateNotifier<ProfilesState> {
  final MihomoApiClient _apiClient = MihomoApiClient();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  ProfilesNotifier() : super(const ProfilesState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('profiles_list');
    final activeId = prefs.getString('active_profile_id');

    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => ProfileItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(profiles: list, activeProfileId: activeId);
      } catch (_) {}
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(state.profiles.map((e) => e.toJson()).toList());
    await prefs.setString('profiles_list', raw);
    if (state.activeProfileId != null) {
      await prefs.setString('active_profile_id', state.activeProfileId!);
    }
  }

  String _resolveBasePath() {
    final cur = Directory.current.path;
    return cur.endsWith('app') ? Directory(cur).parent.path : cur;
  }

  /// 下载并添加 Clash 订阅
  Future<bool> addSubscription(String name, String url) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'ClashMeta/v1.19.31',
          },
        ),
      );

      final yamlContent = res.data ?? '';
      // 解析 YAML 统计节点数量
      final doc = loadYaml(yamlContent) as YamlMap?;
      int nodes = 0;
      if (doc != null && doc.containsKey('proxies')) {
        final proxies = doc['proxies'] as YamlList?;
        nodes = proxies?.length ?? 0;
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final basePath = _resolveBasePath();
      final saveDir = Directory('$basePath\\core\\configs\\profiles');
      if (!saveDir.existsSync()) saveDir.createSync(recursive: true);

      final filePath = '${saveDir.path}\\$id.yaml';
      await File(filePath).writeAsString(yamlContent);

      final item = ProfileItem(
        id: id,
        name: name.isEmpty ? '订阅 $id' : name,
        url: url,
        updatedAt: DateTime.now(),
        nodeCount: nodes,
      );

      final updatedList = [...state.profiles, item];
      state = state.copyWith(
        profiles: updatedList,
        activeProfileId: state.activeProfileId ?? id,
        isLoading: false,
      );

      await _saveToStorage();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '拉取订阅失败: $e',
      );
      return false;
    }
  }

  /// 切换并热重载当前订阅到 Mihomo
  Future<void> applyProfile(String profileId) async {
    final basePath = _resolveBasePath();
    final profileFile = File('$basePath\\core\\configs\\profiles\\$profileId.yaml');
    if (!profileFile.existsSync()) return;

    try {
      state = state.copyWith(isLoading: true);
      // 调用 Mihomo API 热加载新配置文件
      await _apiClient.updateConfigs({
        'path': profileFile.path,
      });
      state = state.copyWith(activeProfileId: profileId, isLoading: false);
      await _saveToStorage();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载配置失败: $e');
    }
  }

  /// 删除订阅
  Future<void> deleteProfile(String profileId) async {
    final basePath = _resolveBasePath();
    final file = File('$basePath\\core\\configs\\profiles\\$profileId.yaml');
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }

    final updated = state.profiles.where((p) => p.id != profileId).toList();
    state = state.copyWith(
      profiles: updated,
      activeProfileId: state.activeProfileId == profileId
          ? (updated.isNotEmpty ? updated.first.id : null)
          : state.activeProfileId,
    );
    await _saveToStorage();
  }
}

final profilesStateProvider = StateNotifierProvider<ProfilesNotifier, ProfilesState>((ref) {
  return ProfilesNotifier();
});
