import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {

    private let appGroup = "group.com.biteclash.app"
    private var isTunnelRunning = false

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let tunnelAddress = "198.18.0.1"
        let subnetMask = "255.255.0.0"
        let dnsServer = "198.18.0.2"

        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelAddress)
        
        let ipv4Settings = NEIPv4Settings(addresses: [tunnelAddress], subnetMasks: [subnetMask])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        networkSettings.ipv4Settings = ipv4Settings

        let dnsSettings = NEDNSSettings(servers: [dnsServer])
        dnsSettings.matchDomains = [""]
        networkSettings.dnsSettings = dnsSettings
        networkSettings.mtu = 1500

        setTunnelNetworkSettings(networkSettings) { [weak self] error in
            if let error = error {
                NSLog("[BiteClash PacketTunnel] Failed to set tunnel network settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }

            self?.isTunnelRunning = true
            NSLog("[BiteClash PacketTunnel] Tunnel network settings applied successfully.")
            self?.startPacketFlowLoop()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        isTunnelRunning = false
        NSLog("[BiteClash PacketTunnel] Stopping tunnel, reason: \(reason.rawValue)")
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let message = String(data: messageData, encoding: .utf8) else {
            completionHandler?(nil)
            return
        }

        switch message {
        case "getStatus":
            let status = isTunnelRunning ? "RUNNING" : "STOPPED"
            completionHandler?(status.data(using: .utf8))
        default:
            completionHandler?("OK".data(using: .utf8))
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {
    }

    private func startPacketFlowLoop() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self, self.isTunnelRunning else { return }
            // Forward/process packets if native engine is bound, or loop read
            self.startPacketFlowLoop()
        }
    }
}
