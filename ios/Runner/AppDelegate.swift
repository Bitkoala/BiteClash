import Flutter
import UIKit
import NetworkExtension

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    private let serviceChannelName = "com.biteclash.app/service"
    private let appGroupIdentifier = "group.com.biteclash.app"
    private let tunnelBundleId = "com.biteclash.app.PacketTunnel"
    
    private var vpnManager: NETunnelProviderManager?
    private var methodChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as? FlutterViewController
        if let controller = controller {
            setupServiceChannel(messenger: controller.binaryMessenger)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange(_:)),
            name: .NEVPNStatusDidChange,
            object: nil
        )
        
        loadVPNManager(completion: nil)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }

    private func setupServiceChannel(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: serviceChannelName, binaryMessenger: messenger)
        self.methodChannel = channel

        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            
            switch call.method {
            case "init":
                self.initEnvironment(result: result)
            case "start":
                self.startVPN(result: result)
            case "stop":
                self.stopVPN(result: result)
            case "shutdown":
                self.stopVPN { success in
                    result(success)
                }
            case "syncState":
                if let args = call.arguments as? String {
                    self.saveConfigToSharedGroup(configContent: args)
                }
                result("")
            case "getRunTime":
                if let connectedDate = self.vpnManager?.connection.connectedDate {
                    let ms = Int64(connectedDate.timeIntervalSince1970 * 1000)
                    result(ms)
                } else {
                    result(0)
                }
            case "invokeMethod":
                // Core method proxy - return empty JSON response or delegate
                result("{\"code\": 0, \"message\": \"success\"}")
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func loadVPNManager(completion: ((NETunnelProviderManager?) -> Void)?) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return }
            if let error = error {
                NSLog("[BiteClash] Failed to load VPN managers: \(error.localizedDescription)")
                completion?(nil)
                return
            }

            if let existingManager = managers?.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId
            }) {
                self.vpnManager = existingManager
                completion?(existingManager)
            } else {
                let newManager = NETunnelProviderManager()
                let config = NETunnelProviderProtocol()
                config.providerBundleIdentifier = self.tunnelBundleId
                config.serverAddress = "127.0.0.1"
                newManager.protocolConfiguration = config
                newManager.localizedDescription = "BiteClash"
                newManager.isEnabled = true
                
                newManager.saveToPreferences { [weak self] error in
                    if let error = error {
                        NSLog("[BiteClash] Failed to save initial VPN manager: \(error.localizedDescription)")
                        completion?(nil)
                    } else {
                        self?.vpnManager = newManager
                        completion?(newManager)
                    }
                }
            }
        }
    }

    private func initEnvironment(result: @escaping FlutterResult) {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            NSLog("[BiteClash] App Group Container: \(containerURL.path)")
            result("")
        } else {
            NSLog("[BiteClash] App Group Container not accessible")
            result("")
        }
    }

    private func saveConfigToSharedGroup(configContent: String) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return
        }
        let fileURL = containerURL.appendingPathComponent("config.yaml")
        try? configContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func startVPN(result: @escaping FlutterResult) {
        loadVPNManager { [weak self] manager in
            guard let manager = manager else {
                result(false)
                return
            }

            manager.isEnabled = true
            manager.saveToPreferences { error in
                if let error = error {
                    NSLog("[BiteClash] Error enabling VPN manager: \(error.localizedDescription)")
                    result(false)
                    return
                }

                manager.loadFromPreferences { error in
                    if let error = error {
                        NSLog("[BiteClash] Error reloading VPN preferences: \(error.localizedDescription)")
                        result(false)
                        return
                    }

                    do {
                        try manager.connection.startVPNTunnel()
                        result(true)
                    } catch {
                        NSLog("[BiteClash] Error starting VPN tunnel: \(error.localizedDescription)")
                        result(false)
                    }
                }
            }
        }
    }

    private func stopVPN(result: @escaping FlutterResult) {
        guard let manager = vpnManager else {
            result(true)
            return
        }
        manager.connection.stopVPNTunnel()
        result(true)
    }

    @objc private func vpnStatusDidChange(_ notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection else { return }
        let status = connection.status
        NSLog("[BiteClash] VPN status changed: \(status.rawValue)")
        
        let statusMap: [NEVPNStatus: String] = [
            .invalid: "invalid",
            .disconnected: "disconnected",
            .connecting: "connecting",
            .connected: "connected",
            .reasserting: "reasserting",
            .disconnecting: "disconnecting"
        ]
        
        let statusString = statusMap[status] ?? "unknown"
        let eventPayload: [String: Any] = [
            "method": "event",
            "arguments": "{\"type\":\"status\",\"data\":\"\(statusString)\"}"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: eventPayload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            methodChannel?.invokeMethod("event", arguments: jsonString)
        }
    }
}
