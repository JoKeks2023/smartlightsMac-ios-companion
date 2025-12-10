//
//  MultiTransportSyncManager.swift
//  SmartLights iOS Companion
//
//  Unified sync manager that coordinates data sync with the macOS app:
//  - CloudKit: Cross-device sync via iCloud (both iOS and macOS)
//  - App Groups: Local shared storage on same device (iOS <-> macOS)
//
//  Note: The iOS app does NOT directly control devices. It updates shared storage,
//  and the macOS app monitors these changes and executes device commands.
//
//  Architecture:
//  iOS App (UI) -> Update App Groups/CloudKit -> macOS App monitors -> Device Control
//

import Foundation
import Combine

/// Transport types for syncing with macOS app
public enum SyncTransport: String, CaseIterable {
    case cloud = "CloudKit"         // iCloud sync between iOS and macOS
    case appGroups = "App Groups"   // Local shared storage on same device
}

/// Unified sync manager that coordinates all sync transports.
/// Acts as a facade for CloudSyncManager, Network discovery, and Bluetooth.
@MainActor
public class MultiTransportSyncManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Whether CloudKit sync is active
    @Published public var isConnectedViaCloud: Bool = false
    
    /// Whether App Groups is available
    @Published public var isConnectedViaAppGroups: Bool = false
    
    /// Current sync status message
    @Published public var statusMessage: String = "Idle"
    
    /// Last sync timestamp
    @Published public var lastSyncTime: Date?
    
    // MARK: - Dependencies
    
    /// Cloud sync manager for CloudKit and App Groups
    private let cloudSyncManager: CloudSyncManager
    
    /// Device store to update
    private weak var deviceStore: DeviceStore?
    
    /// Enabled transports
    private var enabledTransports: Set<SyncTransport> = []
    
    // MARK: - Initialization
    
    public init(cloudSyncManager: CloudSyncManager, deviceStore: DeviceStore? = nil) {
        self.cloudSyncManager = cloudSyncManager
        self.deviceStore = deviceStore
        
        print("🔧 MultiTransportSyncManager initialized")
        print(cloudSyncManager.getStorageInfo())
    }
    
    // MARK: - Transport Control
    
    /// Enable a specific transport
    public func enableTransport(_ transport: SyncTransport) async {
        guard !enabledTransports.contains(transport) else {
            print("ℹ️ Transport \(transport.rawValue) already enabled")
            return
        }
        
        enabledTransports.insert(transport)
        print("✅ Enabling transport: \(transport.rawValue)")
        
        switch transport {
        case .cloud:
            await enableCloudSync()
        case .appGroups:
            await enableAppGroupsSync()
        }
    }
    
    /// Disable a specific transport
    public func disableTransport(_ transport: SyncTransport) {
        guard enabledTransports.contains(transport) else { return }
        
        enabledTransports.remove(transport)
        print("🔴 Disabling transport: \(transport.rawValue)")
        
        switch transport {
        case .cloud:
            isConnectedViaCloud = false
        case .appGroups:
            isConnectedViaAppGroups = false
        }
    }
    
    /// Check if a transport is enabled
    public func isTransportEnabled(_ transport: SyncTransport) -> Bool {
        enabledTransports.contains(transport)
    }
    
    // MARK: - CloudKit Transport
    
    private func enableCloudSync() async {
        statusMessage = "Connecting to CloudKit..."
        
        let isAvailable = await cloudSyncManager.checkCloudKitStatus()
        isConnectedViaCloud = isAvailable
        
        if isAvailable {
            statusMessage = "Connected to CloudKit"
            // Optionally trigger initial sync
            do {
                let devices = try await cloudSyncManager.fetchDevicesFromCloud()
                await deviceStore?.replaceAllDevices(devices)
                lastSyncTime = Date()
                print("✅ CloudKit sync completed: \(devices.count) devices")
            } catch {
                print("⚠️ CloudKit sync failed: \(error)")
                statusMessage = "CloudKit sync failed"
            }
        } else {
            statusMessage = "CloudKit not available"
        }
    }
    
    // MARK: - App Groups Transport
    
    private func enableAppGroupsSync() async {
        statusMessage = "Loading from App Groups..."
        
        do {
            let devices = try cloudSyncManager.loadDevicesFromAppGroups()
            let groups = try cloudSyncManager.loadGroupsFromAppGroups()
            
            await deviceStore?.replaceAllDevices(devices)
            await deviceStore?.replaceAllGroups(groups)
            
            isConnectedViaAppGroups = true
            lastSyncTime = Date()
            statusMessage = "Synced with Mac app via App Groups"
            print("✅ App Groups sync completed: \(devices.count) devices, \(groups.count) groups")
            print("📱 iOS app is now synced with macOS app on this device")
        } catch {
            isConnectedViaAppGroups = false
            statusMessage = "Failed to load from App Groups"
            print("❌ App Groups sync failed: \(error)")
        }
    }
    
    // MARK: - Manual Sync Operations
    
    /// Manually trigger a full sync across all enabled transports
    public func syncNow() async {
        print("🔄 Manual sync triggered")
        statusMessage = "Syncing..."
        
        // Sync with enabled transports
        for transport in enabledTransports {
            await enableTransport(transport)
        }
        
        statusMessage = "Sync completed"
        lastSyncTime = Date()
    }
    
    /// Save current device state to persistent storage
    public func saveDevices(_ devices: [GoveeDevice]) async {
        do {
            try cloudSyncManager.saveDevicesToAppGroups(devices)
            
            if isConnectedViaCloud {
                try await cloudSyncManager.saveDevicesToCloud(devices)
            }
            
            lastSyncTime = Date()
            print("✅ Devices saved to storage")
        } catch {
            print("❌ Failed to save devices: \(error)")
        }
    }
    
    /// Save current group state to persistent storage
    public func saveGroups(_ groups: [DeviceGroup]) async {
        do {
            try cloudSyncManager.saveGroupsToAppGroups(groups)
            
            if isConnectedViaCloud {
                try await cloudSyncManager.saveGroupsToCloud(groups)
            }
            
            print("✅ Groups saved to storage")
        } catch {
            print("❌ Failed to save groups: \(error)")
        }
    }
    
    // MARK: - Settings Management
    
    /// Load synced settings
    public func loadSettings() -> SyncedSettings {
        cloudSyncManager.loadSettings()
    }
    
    /// Save synced settings
    public func saveSettings(_ settings: SyncedSettings) async throws {
        try cloudSyncManager.saveSettings(settings)
    }
    
    // MARK: - Utility
    
    /// Get a summary of connection status
    public var connectionSummary: String {
        var connections: [String] = []
        if isConnectedViaCloud { connections.append("iCloud") }
        if isConnectedViaAppGroups { connections.append("Mac App") }
        
        if connections.isEmpty {
            return "Not Synced"
        } else {
            return "Synced: " + connections.joined(separator: " + ")
        }
    }
    
    /// Check if any transport is connected
    public var isAnyTransportConnected: Bool {
        isConnectedViaCloud || isConnectedViaAppGroups
    }
}
