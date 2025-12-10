//
//  RemoteControlProtocol.swift
//  SmartLights iOS Companion
//
//  Remote control API for managing Govee devices from iOS.
//  This client routes commands through the UnifiedSyncManager and updates
//  the local DeviceStore, persisting changes to App Groups/CloudKit.
//
//  TODO: See IOS_BRIDGE_DEVELOPER_GUIDE.md for integration with real device APIs.
//

import Foundation

/// Protocol defining remote control operations for Govee devices
public protocol RemoteControlProtocol {
    func setDevicePower(deviceId: String, powerState: Bool) async throws
    func setDeviceBrightness(deviceId: String, brightness: Int) async throws
    func setDeviceColor(deviceId: String, color: DeviceColor) async throws
    func setDeviceColorTemperature(deviceId: String, kelvin: Int) async throws
    func createGroup(name: String, deviceIds: [String]) async throws -> DeviceGroup
    func deleteGroup(groupId: String) async throws
    func setGroupPower(groupId: String, powerState: Bool) async throws
    func refreshDevices() async throws
    func getSettings() async -> SyncedSettings
    func updateSettings(_ settings: SyncedSettings) async throws
}

/// Remote control client for managing Govee devices.
/// This class implements the remote control protocol and coordinates with
/// the sync manager and device store to persist changes.
@MainActor
public class RemoteControlClient: RemoteControlProtocol {
    // MARK: - Dependencies
    
    private let syncManager: MultiTransportSyncManager
    private let deviceStore: DeviceStore
    
    // MARK: - Initialization
    
    public init(syncManager: MultiTransportSyncManager, deviceStore: DeviceStore) {
        self.syncManager = syncManager
        self.deviceStore = deviceStore
        print("🎮 RemoteControlClient initialized")
    }
    
    // MARK: - Device Control
    
    /// Set device power state (on/off)
    public func setDevicePower(deviceId: String, powerState: Bool) async throws {
        print("🔌 Setting device \(deviceId) power to \(powerState)")
        
        guard deviceStore.device(withId: deviceId) != nil else {
            throw SyncError.deviceNotFound(deviceId)
        }
        
        // Update local store
        deviceStore.updateDevicePower(deviceId: deviceId, powerState: powerState)
        
        // Persist to storage
        await syncManager.saveDevices(deviceStore.devices)
        
        // TODO: Send actual command to device via appropriate transport
        // - If local network available: HTTP POST to device
        // - If Bluetooth available: Write to BLE characteristic
        // - If cloud only: Send CloudKit notification to macOS app
        // See IOS_BRIDGE_DEVELOPER_GUIDE.md for command format
    }
    
    /// Set device brightness (0-100)
    public func setDeviceBrightness(deviceId: String, brightness: Int) async throws {
        guard brightness >= 0 && brightness <= 100 else {
            throw SyncError.invalidInput("Brightness must be between 0 and 100")
        }
        
        print("💡 Setting device \(deviceId) brightness to \(brightness)")
        
        guard deviceStore.device(withId: deviceId) != nil else {
            throw SyncError.deviceNotFound(deviceId)
        }
        
        // Update local store
        deviceStore.updateDeviceBrightness(deviceId: deviceId, brightness: brightness)
        
        // Persist to storage
        await syncManager.saveDevices(deviceStore.devices)
        
        // TODO: Send actual command to device
    }
    
    /// Set device color (RGB)
    public func setDeviceColor(deviceId: String, color: DeviceColor) async throws {
        // Validate RGB values
        guard (0...255).contains(color.red),
              (0...255).contains(color.green),
              (0...255).contains(color.blue) else {
            throw SyncError.invalidInput("RGB values must be between 0 and 255")
        }
        
        print("🎨 Setting device \(deviceId) color to RGB(\(color.red), \(color.green), \(color.blue))")
        
        guard let device = deviceStore.device(withId: deviceId) else {
            throw SyncError.deviceNotFound(deviceId)
        }
        
        guard device.supports("color") else {
            throw SyncError.invalidInput("Device does not support color")
        }
        
        // Update local store
        deviceStore.updateDeviceColor(deviceId: deviceId, color: color)
        
        // Persist to storage
        await syncManager.saveDevices(deviceStore.devices)
        
        // TODO: Send actual command to device
    }
    
    /// Set device color temperature (2000-9000K)
    public func setDeviceColorTemperature(deviceId: String, kelvin: Int) async throws {
        guard (2000...9000).contains(kelvin) else {
            throw SyncError.invalidInput("Color temperature must be between 2000K and 9000K")
        }
        
        print("🌡️ Setting device \(deviceId) color temperature to \(kelvin)K")
        
        guard let device = deviceStore.device(withId: deviceId) else {
            throw SyncError.deviceNotFound(deviceId)
        }
        
        guard device.supports("colorTemperature") else {
            throw SyncError.invalidInput("Device does not support color temperature")
        }
        
        // Update local store
        deviceStore.updateDeviceColorTemperature(deviceId: deviceId, kelvin: kelvin)
        
        // Persist to storage
        await syncManager.saveDevices(deviceStore.devices)
        
        // TODO: Send actual command to device
    }
    
    // MARK: - Group Management
    
    /// Create a new device group
    public func createGroup(name: String, deviceIds: [String]) async throws -> DeviceGroup {
        guard !name.isEmpty else {
            throw SyncError.invalidInput("Group name cannot be empty")
        }
        
        print("👥 Creating group '\(name)' with \(deviceIds.count) device(s)")
        
        // Verify all devices exist
        for deviceId in deviceIds {
            guard deviceStore.device(withId: deviceId) != nil else {
                throw SyncError.deviceNotFound(deviceId)
            }
        }
        
        // Create new group
        let group = DeviceGroup(name: name, deviceIds: deviceIds)
        
        // Add to store
        deviceStore.upsertGroup(group)
        
        // Update device group associations
        for deviceId in deviceIds {
            deviceStore.addDevice(deviceId, toGroup: group.id)
        }
        
        // Persist to storage
        await syncManager.saveGroups(deviceStore.groups)
        await syncManager.saveDevices(deviceStore.devices)
        
        return group
    }
    
    /// Delete a device group
    public func deleteGroup(groupId: String) async throws {
        print("🗑️ Deleting group \(groupId)")
        
        guard deviceStore.group(withId: groupId) != nil else {
            throw SyncError.groupNotFound(groupId)
        }
        
        // Remove from store (also clears device associations)
        deviceStore.removeGroup(withId: groupId)
        
        // Persist to storage
        await syncManager.saveGroups(deviceStore.groups)
        await syncManager.saveDevices(deviceStore.devices)
    }
    
    /// Set power state for all devices in a group
    public func setGroupPower(groupId: String, powerState: Bool) async throws {
        print("🔌 Setting group \(groupId) power to \(powerState)")
        
        guard let group = deviceStore.group(withId: groupId) else {
            throw SyncError.groupNotFound(groupId)
        }
        
        // Update all devices in the group
        for deviceId in group.deviceIds {
            if deviceStore.device(withId: deviceId) != nil {
                deviceStore.updateDevicePower(deviceId: deviceId, powerState: powerState)
            }
        }
        
        // Persist to storage
        await syncManager.saveDevices(deviceStore.devices)
        
        // TODO: Send batch command to devices
    }
    
    // MARK: - Device Discovery
    
    /// Refresh device list from all available sources
    public func refreshDevices() async throws {
        print("🔄 Refreshing devices from all sources")
        
        await syncManager.syncNow()
        
        // TODO: Trigger actual device discovery
        // - Query local network for devices
        // - Scan Bluetooth for devices
        // - Fetch latest from CloudKit
        // See IOS_COMPANION_GUIDE.md for discovery examples
    }
    
    // MARK: - Settings Management
    
    /// Get current synced settings
    public func getSettings() async -> SyncedSettings {
        print("⚙️ Loading settings")
        return syncManager.loadSettings()
    }
    
    /// Update synced settings
    public func updateSettings(_ settings: SyncedSettings) async throws {
        print("⚙️ Updating settings")
        try await syncManager.saveSettings(settings)
        
        // Enable/disable transports based on settings
        if settings.cloudSyncEnabled {
            await syncManager.enableTransport(.cloud)
        } else {
            syncManager.disableTransport(.cloud)
        }
        
        if settings.localNetworkEnabled {
            await syncManager.enableTransport(.localNetwork)
        } else {
            syncManager.disableTransport(.localNetwork)
        }
        
        if settings.bluetoothEnabled {
            await syncManager.enableTransport(.bluetooth)
        } else {
            syncManager.disableTransport(.bluetooth)
        }
        
        if settings.appGroupsEnabled {
            await syncManager.enableTransport(.appGroups)
        }
    }
    
    // MARK: - Batch Operations
    
    /// Update multiple devices at once (useful for optimizations)
    public func batchUpdateDevices(_ updates: [(deviceId: String, powerState: Bool?, brightness: Int?, color: DeviceColor?)]) async throws {
        print("📦 Batch updating \(updates.count) device(s)")
        
        for update in updates {
            guard deviceStore.device(withId: update.deviceId) != nil else {
                throw SyncError.deviceNotFound(update.deviceId)
            }
            
            if let powerState = update.powerState {
                deviceStore.updateDevicePower(deviceId: update.deviceId, powerState: powerState)
            }
            
            if let brightness = update.brightness {
                guard (0...100).contains(brightness) else {
                    throw SyncError.invalidInput("Invalid brightness: \(brightness)")
                }
                deviceStore.updateDeviceBrightness(deviceId: update.deviceId, brightness: brightness)
            }
            
            if let color = update.color {
                deviceStore.updateDeviceColor(deviceId: update.deviceId, color: color)
            }
        }
        
        // Persist all changes at once
        await syncManager.saveDevices(deviceStore.devices)
    }
}
