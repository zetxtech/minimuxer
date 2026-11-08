//
//  HeartbeatService.swift
//  Minimuxer
//
//  Original Rust Implementation by @jkcoxson
//  Swift Port created by Magesh K on 02/03/26.
//

import Foundation
internal import MinimuxerCommon
internal import DeviceGatewayAPI

final internal class HeartbeatService: @unchecked Sendable {
    let deviceProvider: DeviceProvider
    var gateway: any DeviceGatewayAPI {
        deviceProvider.gateway
    }
    let proxyServer: UsbmuxdProxyServer
    let endpoint: DeviceEndpoint

    private let sleepNs: UInt64 = MinimuxerConstants.heartbeatSleepNs

    private let lock = NSLock()
    private var running = false
    private var taskActive = false
    private var lastErrorDescription: String?
    private var lastBeatSuccessfulStorage = false

    init(deviceProvider: DeviceProvider, proxyServer: UsbmuxdProxyServer, endpoint: DeviceEndpoint) {
        self.deviceProvider = deviceProvider
        self.proxyServer = proxyServer
        self.endpoint = endpoint
    }

    var lastBeatSuccessful: Bool {
        lock.withLock { lastBeatSuccessfulStorage }
    }

    // Start the heartbeat keep-alive loop. Safe to call multiple times — ignored while a task is already active.
    func start() {
        let shouldLaunch = lock.withLock { () -> Bool in
            running = true
            if taskActive {
                return false
            }
            taskActive = true
            return true
        }
        guard shouldLaunch else {
            return
        }

        verboseLog("[minimuxer] Starting heartbeat task...")
        Task.detached { [weak self] in
            guard let self = self else { return }
            verboseLog("[minimuxer] heartbeat-task: started")

            await self.heartbeatLoop()

            let shouldRelaunch = self.lock.withLock { () -> Bool in
                self.taskActive = false
                return self.running
            }
            self.setLastBeat(false)
            verboseLog("[minimuxer] heartbeat-task: stopped")
            if shouldRelaunch {
                self.start()
            }
        }
    }

    // Signal the heartbeat task to stop. The task exits after its current exchange.
    func stop() {
        lock.withLock { running = false }
        setLastBeat(false)
        verboseLog("[minimuxer] HeartbeatService stop requested")
    }

    private var isRunning: Bool {
        lock.withLock { running }
    }

    private func setLastBeat(_ value: Bool) {
        lock.withLock { lastBeatSuccessfulStorage = value }
    }

    private func clearLastError() {
        lock.withLock { lastErrorDescription = nil }
    }

    private func logIfNeeded(_ message: String, isVerbose: Bool = false) {
        let shouldLog = lock.withLock { () -> Bool in
            if message == lastErrorDescription {
                return false
            }
            lastErrorDescription = message
            return true
        }
        guard shouldLog else { return }
        if isVerbose {
            verboseLog("[minimuxer] heartbeat-task: \(message)")
        } else {
            debugLog("[minimuxer] heartbeat-task: \(message)")
        }
    }

    private func heartbeatLoop() async {
        if self.gateway.requiresUsbmuxd {
            while isRunning && !self.proxyServer.isListening {
                logIfNeeded("Waiting for usbmuxd to be ready...", isVerbose: true)
                try? await Task.sleep(nanoseconds: sleepNs)
            }
            if isRunning {
                verboseLog("[minimuxer] heartbeat-task: usbmuxd is ready")
            }
        }

        while isRunning {
            let tunnelPeerIp: String
            do {
                tunnelPeerIp = try await self.endpoint.ip()
            } catch {
                logIfNeeded("device IP unavailable", isVerbose: true)
                setLastBeat(false)
                try? await Task.sleep(nanoseconds: sleepNs)
                continue
            }

            // verify tunnel/device reachability first
            let targetPort = self.gateway.servicePort
            if !NetworkUtils.testTCP(ip: tunnelPeerIp, port: targetPort) {
                logIfNeeded("device IP not reachable, waiting...", isVerbose: true)
                setLastBeat(false)
                try? await Task.sleep(nanoseconds: sleepNs)
                continue
            }

            do {
                // The session holds one heartbeat connection open and only returns
                // once the device drops it or `shouldContinue` turns false.
                try await self.gateway.performHeartbeatSession(
                    interval: MinimuxerConstants.heartbeatInitialReceiveTimeoutSeconds,
                    shouldContinue: { [weak self] in
                        self?.isRunning ?? false
                    },
                    onBeat: { [weak self] interval in
                        guard let self = self else { return }
                        self.clearLastError()
                        self.setLastBeat(true)
                        verboseLog("[minimuxer] heartbeat-task: marco received, polo sent, nextInterval=\(interval)")
                    }
                )
            } catch {
                logIfNeeded("Heartbeat failed: \(error)")
                setLastBeat(false)
                try? await Task.sleep(nanoseconds: sleepNs)
            }
        }

        setLastBeat(false)
    }
}
