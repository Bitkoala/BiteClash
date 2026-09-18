import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path/path.dart';

class CoreController {
  static CoreController? _instance;
  late CoreHandlerInterface _interface;
  RemoteCoreHandler? _remoteHandler;

  CoreController._internal() {
    if (system.isAndroid || system.isIOS) {
      _interface = coreLib!;
    } else {
      _interface = coreService!;
    }
  }

  @visibleForTesting
  CoreController.test(this._interface) {
    _instance = this;
  }

  @visibleForTesting
  CoreController.scoped(this._interface);

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  factory CoreController() {
    _instance ??= CoreController._internal();
    return _instance!;
  }

  void setRemoteHandler(RemoteCoreHandler? handler) {
    _remoteHandler = handler;
  }

  RemoteCoreHandler? get remoteHandler => _remoteHandler;

  bool get isRemote => _remoteHandler != null;

  CoreHandlerInterface get _activeInterface => _remoteHandler ?? _interface;

  Future<CoreLifecycleResult> start() => _activeInterface.start();

  Future<CoreLifecycleResult> restart() => _activeInterface.restart();

  Future<CoreLifecycleResult> stop() => _activeInterface.stop();

  Future<CoreLifecycleResult> close() => _activeInterface.close();

  static Future<void> ensureHomeDir() async {
    final homePath = await appPath.homeDirPath;
    final homeDir = Directory(homePath);
    final isExists = await homeDir.exists();
    if (!isExists) {
      await homeDir.create(recursive: true);
    }
    await system.grantHomeDirAccess(homePath);
  }

  static Future<void> initGeo() async {
    final homePath = await appPath.homeDirPath;
    const geoFileNameList = [MMDB, GEOIP, GEOSITE, ASN];
    try {
      for (final geoFileName in geoFileNameList) {
        final geoFile = File(join(homePath, geoFileName));
        final isExists = await geoFile.exists();
        if (isExists) {
          continue;
        }
        final data = await rootBundle.load('assets/data/$geoFileName');
        final List<int> bytes = data.buffer.asUint8List();
        await geoFile.writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      commonPrint.log(
        'Failed to initialize geo data: $e',
        logLevel: LogLevel.error,
      );
      rethrow;
    }
  }

  Future<bool> init(int version) async {
    await ensureHomeDir();
    await initGeo();
    final homeDirPath = await appPath.homeDirPath;
    return _activeInterface.init(
      InitParams(homeDir: homeDirPath, version: version),
    );
  }

  FutureOr<bool> get isInit => _activeInterface.isInit;

  Future<String> validateConfig(String path) async {
    final res = await _activeInterface.validateConfig(path);
    return res;
  }

  Future<String> validateConfigWithData(String data) async {
    final path = await appPath.tempFilePath;
    final file = File(path);
    await file.safeWriteAsString(data);
    final res = await _activeInterface.validateConfig(path);
    await File(path).safeDelete();
    return res;
  }

  Future<String> updateConfig(UpdateParams updateParams) async {
    return _activeInterface.updateConfig(updateParams);
  }

  Future<String> setupConfig({
    required SetupParams params,
    Future<void> Function()? preloadInvoke,
  }) async {
    if (preloadInvoke == null) {
      return _activeInterface.setupConfig(params);
    }
    final (result, _) = await (
      _activeInterface.setupConfig(params),
      preloadInvoke(),
    ).wait;
    return result;
  }

  Future<List<Group>> getProxiesGroups({
    required ProxiesSortType sortType,
    required DelayMap delayMap,
    required Map<String, String> selectedMap,
    required String defaultTestUrl,
  }) async {
    final proxiesData = await _activeInterface.getProxies();
    return toGroupsTask(
      ComputeGroupsState(
        proxiesData: proxiesData,
        sortType: sortType,
        delayMap: delayMap,
        selectedMap: selectedMap,
        defaultTestUrl: defaultTestUrl,
      ),
    );
  }

  FutureOr<String> changeProxy(ChangeProxyParams changeProxyParams) async {
    return await _activeInterface.changeProxy(changeProxyParams);
  }

  Future<List<TrackerInfo>> getConnections() async {
    return _activeInterface.getConnections();
  }

  Future<void> closeConnection(String id) async {
    await _activeInterface.closeConnection(id);
  }

  Future<void> closeConnections() async {
    await _activeInterface.closeConnections();
  }

  Future<void> resetConnections() async {
    await _activeInterface.resetConnections();
  }

  Future<List<ExternalProvider>> getExternalProviders() async {
    return _activeInterface.getExternalProviders();
  }

  Future<ExternalProvider?> getExternalProvider(
    String externalProviderName,
  ) async {
    return _activeInterface.getExternalProvider(externalProviderName);
  }

  Future<String> updateGeoData(String type) {
    return _activeInterface.updateGeoData(type);
  }

  Future<String> sideLoadExternalProvider({
    required String providerName,
    required String data,
  }) {
    return _activeInterface.sideLoadExternalProvider(
      providerName: providerName,
      data: data,
    );
  }

  Future<String> updateExternalProvider({required String providerName}) async {
    return _activeInterface.updateExternalProvider(providerName);
  }

  Future<bool> startListener() async {
    return _activeInterface.startListener();
  }

  Future<bool> stopListener() async {
    return _activeInterface.stopListener();
  }

  Future<Delay?> getDelay(String url, String proxyName) async {
    return _activeInterface.asyncTestDelay(url, proxyName);
  }

  Future<Map<String, dynamic>> getConfig(int id) async {
    final profilePath = await appPath.getProfilePath(id.toString());
    final data = Map<String, dynamic>.from(
      await _activeInterface.getConfig(profilePath),
    );
    data['rules'] = data['rule'];
    data.remove('rule');
    return data;
  }

  Future<Traffic> getTraffic(bool onlyStatisticsProxy) async {
    return _activeInterface.getTraffic(onlyStatisticsProxy);
  }

  Future<Traffic> getTotalTraffic(bool onlyStatisticsProxy) async {
    return _activeInterface.getTotalTraffic(onlyStatisticsProxy);
  }

  Future<int> getMemory() async {
    return _activeInterface.getMemory();
  }

  void resetTraffic() {
    _activeInterface.resetTraffic();
  }

  void startLog() {
    _activeInterface.startLog();
  }

  void stopLog() {
    _activeInterface.stopLog();
  }

  Future<void> requestGc() async {
    await _activeInterface.forceGc();
  }

  Future<void> crash() async {
    await _activeInterface.crash();
  }

  Future<String> clearEffect(int profileId) async {
    return _activeInterface.clearEffect(profileId);
  }
}

final coreController = CoreController();
