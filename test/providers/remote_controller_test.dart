import 'dart:io';

import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String root;

  _FakePathProvider(this.root);

  @override
  Future<String?> getTemporaryPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getApplicationCachePath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProvider(
      Directory.systemTemp.path,
    );
  });

  group('RemoteControllerNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      coreController.setRemoteHandler(null);
    });

    test('defaults to disabled remote controller', () {
      final state = container.read(remoteControllerProvider);
      expect(state.enabled, isFalse);
      expect(state.port, 9090);
      expect(coreController.isRemote, isFalse);
    });

    test('updateConfig updates host, port and secret', () async {
      final notifier = container.read(remoteControllerProvider.notifier);
      await notifier.updateConfig(
        host: '192.168.31.1',
        port: 9095,
        secret: 'test-secret',
      );

      final state = container.read(remoteControllerProvider);
      expect(state.host, '192.168.31.1');
      expect(state.port, 9095);
      expect(state.secret, 'test-secret');
    });

    test(
      'toggleEnabled activates and deactivates RemoteCoreHandler in coreController',
      () async {
        final notifier = container.read(remoteControllerProvider.notifier);
        await notifier.updateConfig(host: '10.0.0.1', port: 9090);

        await notifier.toggleEnabled(true);
        expect(container.read(remoteControllerProvider).enabled, isTrue);
        expect(coreController.isRemote, isTrue);

        await notifier.toggleEnabled(false);
        expect(container.read(remoteControllerProvider).enabled, isFalse);
        expect(coreController.isRemote, isFalse);
      },
    );
  });
}
