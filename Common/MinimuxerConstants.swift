//
//  MinimuxerConstants.swift
//  Minimuxer
//
//  Created by Magesh K on 4/7/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Foundation

public enum MinimuxerConstants {
    public static let lockdowndPort: UInt16 = 62078     // lockdown daemon port
    public static let remotePairingPort: UInt16 = 49152 // RemotePairing daemon port
    
    public static let appName = "minimuxer"

    public static let usbmuxdHost = "127.0.0.1"
    public static let usbmuxdPort: UInt16 = 27015       // usbmux daemon port
    public static let usbmuxdSocket = "\(usbmuxdHost):\(usbmuxdPort)"

    public static let empServerHost = "127.0.0.1"
    public static let empServerPort: UInt16 = 51820     // default EMProxy WireGuard loopback port
    
    public static let vpnHandshakeTimeoutNs: UInt64 = 10_000_000_000
    
    public static let deviceFetchTimeoutMs: UInt16 = 5000
    public static var defaultTCPProbeTimeoutMs: Int = 250
    
    public static let pkgPath = "PublicStaging"
    public static let usbmuxdEnvKey = "USBMUXD_SOCKET_ADDRESS"

    public static let pre17VersionsURL  = "https://raw.githubusercontent.com/jkcoxson/JitStreamer/master/versions.json"
    public static let ddiImageURL       = "https://raw.githubusercontent.com/doronz88/DeveloperDiskImage/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/Image.dmg"
    public static let ddiTrustcacheURL  = "https://raw.githubusercontent.com/doronz88/DeveloperDiskImage/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/Image.dmg.trustcache"
    public static let ddiManifestURL    = "https://raw.githubusercontent.com/doronz88/DeveloperDiskImage/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/BuildManifest.plist"

    // WirelessPair Constants
    public static let defaultHostName = "SideStore"
    public static let defaultHostModel = "Mac17,7"
    public static let defaultBindPort: UInt16 = 0
    public static let defaultAdDomain = ""
    public static let remotePairingDaemonServiceType = "_remotepairing._tcp."
    public static let remotePairingPairableHostServiceType = "_remotepairing-pairable-host._tcp."
    public static let remotePairingManualPairingServiceType = "_remotepairing-manual-pairing._tcp."
    public static let defaultRPPairingFileName = "rp_pairing_file.plist"
    public static let rpPairingFileSuffix = "_rp.plist"

    // UsbmuxdProxyServer Constants
    public static let deviceAttach = "Attached"
    public static let deviceDetach = "Detached"
    public static let usbmuxMaxPacketBufferLength = 4095
    public static let usbmuxHeaderLen = 16

    // Heartbeat keep-alive
    public static let heartbeatInterval: UInt64 = 1000
    public static let heartbeatSleepNs: UInt64 = 1_000_000_000
    public static let heartbeatInitialReceiveTimeoutSeconds: UInt64 = 15
    public static let heartbeatReceiveTimeoutMarginSeconds: UInt64 = 5
    public static let heartbeatMaxReceiveTimeoutSeconds: UInt64 = 60

    /// Receive deadline for a device driven heartbeat: requested interval plus margin, capped.
    public static func heartbeatReceiveTimeoutSeconds(forRequestedInterval requestedInterval: UInt64) -> UInt64 {
        let (withMargin, overflow) = requestedInterval.addingReportingOverflow(heartbeatReceiveTimeoutMarginSeconds)
        if overflow {
            return heartbeatMaxReceiveTimeoutSeconds
        }
        return min(withMargin, heartbeatMaxReceiveTimeoutSeconds)
    }

    // Packet Configuration
    public static let maxPacketSize = 1024
    public static let packetHeaderLen = 16
}
