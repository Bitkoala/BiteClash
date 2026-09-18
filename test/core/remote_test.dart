import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/core/desktop/model.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/core/remote.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = null;
  });

  late HttpServer server;
  late int serverPort;
  late RemoteCoreHandler handler;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serverPort = server.port;
    handler = RemoteCoreHandler(
      host: '127.0.0.1',
      port: serverPort,
      secret: 'test-secret',
    );

    Future<void> sendJson(
      HttpRequest req,
      Object? data, [
      int status = HttpStatus.ok,
    ]) async {
      req.response.statusCode = status;
      if (data != null) {
        req.response.headers.contentType = ContentType.json;
        req.response.write(json.encode(data));
      }
      await req.response.close();
    }

    server.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        addTearDown(socket.close);
        socket.listen((_) {});
        return;
      }

      await request.drain<void>();
      final path = request.uri.path;
      final method = request.method;

      if (path == '/version') {
        await sendJson(request, {'version': 'v1.18.9'});
      } else if (path == '/proxies') {
        if (method == 'GET') {
          await sendJson(request, {
            'proxies': {
              'GLOBAL': {'name': 'GLOBAL', 'type': 'Selector', 'now': 'DIRECT'},
              'DIRECT': {'name': 'DIRECT', 'type': 'Direct'},
            },
            'all': ['GLOBAL', 'DIRECT'],
          });
        }
      } else if (path.startsWith('/proxies/')) {
        if (method == 'PUT') {
          await sendJson(request, null);
        } else if (path.endsWith('/delay')) {
          await sendJson(request, {'delay': 42});
        }
      } else if (path == '/configs') {
        if (method == 'GET') {
          await sendJson(request, {'mode': 'rule', 'port': 7890});
        } else if (method == 'PATCH') {
          await sendJson(request, null);
        }
      } else if (path == '/gc') {
        await sendJson(request, null);
      } else if (path == '/memory') {
        await sendJson(request, {'inuse': 2048});
      } else if (path == '/connections') {
        if (method == 'GET') {
          await sendJson(request, {
            'connections': [
              {
                'id': 'conn-1',
                'upload': 100,
                'download': 200,
                'start': '2026-01-01T00:00:00.000Z',
                'metadata': {
                  'network': 'tcp',
                  'type': 'HTTP',
                  'sourceIP': '192.168.1.5',
                  'destinationIP': '1.1.1.1',
                  'sourcePort': '54321',
                  'destinationPort': '80',
                  'host': 'example.com',
                  'dnsMode': 'fake-ip',
                  'process': '',
                  'processPath': '',
                  'specialProxy': '',
                  'uid': 0,
                },
                'chains': ['DIRECT'],
                'rule': 'Match',
                'rulePayload': '',
              },
            ],
          });
        } else if (method == 'DELETE') {
          await sendJson(request, null);
        }
      } else if (path.startsWith('/connections/')) {
        if (method == 'DELETE') {
          await sendJson(request, null);
        }
      } else if (path == '/providers/proxies') {
        await sendJson(request, {
          'providers': {
            'default': {
              'name': 'default',
              'type': 'Proxy',
              'count': 1,
              'vehicle-type': 'HTTP',
              'update-at': '2026-01-01T00:00:00.000Z',
            },
          },
        });
      } else if (path.startsWith('/providers/proxies/')) {
        if (method == 'GET') {
          await sendJson(request, {
            'name': 'default',
            'type': 'Proxy',
            'count': 1,
            'vehicle-type': 'HTTP',
            'update-at': '2026-01-01T00:00:00.000Z',
          });
        } else if (method == 'PUT') {
          await sendJson(request, null);
        }
      } else {
        await sendJson(request, null, HttpStatus.notFound);
      }
    });
  });

  tearDown(() async {
    await handler.stop();
    await server.close(force: true);
  });

  group('RemoteCoreHandler', () {
    test('exposes correct baseUrl and wsUrl', () {
      expect(handler.baseUrl, 'http://127.0.0.1:$serverPort');
      expect(handler.wsUrl, 'ws://127.0.0.1:$serverPort');
    });

    test('testConnection returns true when remote responds 200', () async {
      final ok = await handler.testConnection();
      expect(ok, isTrue);
    });

    test('start and stop update lifecycle and connection state', () async {
      final startRes = await handler.start();
      expect(startRes.outcome, CoreLifecycleOutcome.applied);
      expect(await handler.isInit, isTrue);

      final restartRes = await handler.restart();
      expect(restartRes.outcome, CoreLifecycleOutcome.applied);

      final stopRes = await handler.stop();
      expect(stopRes.outcome, CoreLifecycleOutcome.applied);
      expect(await handler.isInit, isFalse);

      final closeRes = await handler.close();
      expect(closeRes.outcome, CoreLifecycleOutcome.applied);
    });

    test('init sets connected state when connection succeeds', () async {
      final initialized = await handler.init(
        const InitParams(homeDir: '.', version: 1),
      );
      expect(initialized, isTrue);
      expect(await handler.isInit, isTrue);
    });

    test('forceGc returns true when endpoint responds 200', () async {
      expect(await handler.forceGc(), isTrue);
    });

    test('getConfig fetches remote configuration', () async {
      final config = await handler.getConfig('');
      expect(config['mode'], 'rule');
      expect(config['port'], 7890);
    });

    test('asyncTestDelay measures remote proxy latency', () async {
      final delay = await handler.asyncTestDelay(
        'http://example.com',
        'DIRECT',
      );
      expect(delay?.value, 42);
      expect(delay?.name, 'DIRECT');
    });

    test('updateConfig patches remote configuration', () async {
      final err = await handler.updateConfig(
        const UpdateParams(
          tun: Tun(),
          mixedPort: 7890,
          allowLan: true,
          findProcessMode: FindProcessMode.off,
          mode: Mode.rule,
          logLevel: LogLevel.info,
          ipv6: false,
          tcpConcurrent: false,
          externalController: ExternalControllerStatus.close,
          unifiedDelay: false,
        ),
      );
      expect(err, isEmpty);
    });

    test('getProxies returns parsed proxies data', () async {
      final data = await handler.getProxies();
      expect(data.proxies.containsKey('GLOBAL'), isTrue);
      expect(data.proxies.containsKey('DIRECT'), isTrue);
    });

    test('changeProxy sends PUT request to select node', () async {
      final err = await handler.changeProxy(
        const ChangeProxyParams(groupName: 'GLOBAL', proxyName: 'DIRECT'),
      );
      expect(err, isEmpty);
    });

    test(
      'getExternalProviders and getExternalProvider parse responses',
      () async {
        final providers = await handler.getExternalProviders();
        expect(providers, isNotEmpty);
        expect(providers.first.name, 'default');

        final single = await handler.getExternalProvider('default');
        expect(single?.name, 'default');

        final updateErr = await handler.updateExternalProvider('default');
        expect(updateErr, isEmpty);
      },
    );

    test('getMemory fetches inuse memory stats', () async {
      final mem = await handler.getMemory();
      expect(mem, 2048);
    });

    test('getConnections parses active trackers and handles closure', () async {
      final conns = await handler.getConnections();
      expect(conns, isNotEmpty);
      expect(conns.first.id, 'conn-1');

      final closedSingle = await handler.closeConnection('conn-1');
      expect(closedSingle, isTrue);

      final closedAll = await handler.closeConnections();
      expect(closedAll, isTrue);

      final reset = await handler.resetConnections();
      expect(reset, isTrue);
    });

    test('traffic meters reset and return latest values', () async {
      handler.resetTraffic();
      final t1 = await handler.getTraffic(false);
      final t2 = await handler.getTotalTraffic(false);
      expect(t1.up, 0);
      expect(t2.down, 0);
    });

    test('stub methods execute gracefully', () async {
      expect(await handler.validateConfig(''), isEmpty);
      expect(
        await handler.setupConfig(
          const SetupParams(selectedMap: {}, testUrl: ''),
        ),
        isEmpty,
      );
      expect(await handler.clearEffect(1), isEmpty);
      expect(await handler.updateGeoData('mmdb'), isEmpty);
      expect(
        await handler.sideLoadExternalProvider(providerName: 'p', data: 'd'),
        isEmpty,
      );
      expect(await handler.crash(), isFalse);
      expect(await handler.startListener(), isTrue);
      expect(await handler.stopListener(), isTrue);

      handler.startLog();
      handler.stopLog();

      final res = await handler.invokeMethod<String>(
        method: CoreMethod.getTraffic,
      );
      expect(res, isNull);
    });
  });
}
