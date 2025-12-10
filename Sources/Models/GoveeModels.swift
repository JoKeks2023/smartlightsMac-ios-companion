//
//  GoveeModels.swift
//  SmartLights iOS Companion
//
//  Shared data models for Govee smart light devices.
//  These models match the shapes documented in IOS_BRIDGE_DEVELOPER_GUIDE.md
//  and are designed to be synced across macOS and iOS via CloudKit and App Groups.
//

import Foundation
import SwiftUI

// MARK: - Device Color Model

/// Represents a color value for a smart light device.
/// Can represent RGB colors or color temperature (Kelvin).
public struct DeviceColor: Codable, Equatable, Hashable {
    /// Red component (0-255)
    public var red: Int
    
    /// Green component (0-255)
    public var green: Int
    
    /// Blue component (0-255)
    public var blue: Int
    
    /// Color temperature in Kelvin (2000-9000), optional
    public var kelvin: Int?
    
    public init(red: Int, green: Int, blue: Int, kelvin: Int? = nil) {
        self.red = red
        self.green = green
        self.blue = blue
        self.kelvin = kelvin
    }
    
    /// Initialize from color temperature only
    /// Note: RGB values are set to approximate values based on Kelvin.
    /// For accurate color representation, use the conversion utilities in DeviceColor+Extensions.
    /// This is a simplified version for model initialization; the UI uses the precise kelvinToUIColor algorithm.
    public init(kelvin: Int) {
        // Use a simple approximation for RGB based on kelvin ranges
        // This provides reasonable defaults without requiring Foundation imports in the model
        // For precise conversion used in UI, see DeviceColor+Extensions.kelvinToUIColor()
        if kelvin < 3000 {
            // Warm (orange-ish)
            self.red = 255
            self.green = 180
            self.blue = 107
        } else if kelvin < 5000 {
            // Neutral warm
            self.red = 255
            self.green = 220
            self.blue = 180
        } else if kelvin < 7000 {
            // Neutral cool
            self.red = 255
            self.green = 240
            self.blue = 220
        } else {
            // Cool (blue-ish)
            self.red = 200
            self.green = 220
            self.blue = 255
        }
        self.kelvin = kelvin
    }
    
    /// Preset white color
    public static var white: DeviceColor {
        DeviceColor(red: 255, green: 255, blue: 255)
    }
    
    /// Preset warm white (3000K)
    public static var warmWhite: DeviceColor {
        DeviceColor(kelvin: 3000)
    }
    
    /// Preset cool white (6500K)
    public static var coolWhite: DeviceColor {
        DeviceColor(kelvin: 6500)
    }
}

// MARK: - Govee Device Model

/// Represents a Govee smart light device with its current state and capabilities.
/// Conforms to Identifiable for use in SwiftUI Lists.
public struct GoveeDevice: Codable, Identifiable, Equatable, Hashable {
    /// Unique device identifier (typically MAC address or Govee device ID)
    public var id: String
    
    /// Human-readable device name
    public var name: String
    
    /// Device model identifier (e.g., "H6159", "H6182")
    public var model: String
    
    /// Whether the device is currently powered on
    public var isOnline: Bool
    
    /// Current power state
    public var powerState: Bool
    
    /// Current brightness level (0-100)
    public var brightness: Int
    
    /// Current color setting
    public var color: DeviceColor
    
    /// Supported capabilities (e.g., "color", "brightness", "colorTemperature")
    public var capabilities: [String]
    
    /// Last time this device was seen or updated
    public var lastSeen: Date
    
    /// Optional group membership (ID of the group this device belongs to)
    public var groupId: String?
    
    public init(
        id: String,
        name: String,
        model: String,
        isOnline: Bool = true,
        powerState: Bool = false,
        brightness: Int = 100,
        color: DeviceColor = .white,
        capabilities: [String] = ["color", "brightness", "colorTemperature"],
        lastSeen: Date = Date(),
        groupId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.isOnline = isOnline
        self.powerState = powerState
        self.brightness = brightness
        self.color = color
        self.capabilities = capabilities
        self.lastSeen = lastSeen
        self.groupId = groupId
    }
    
    /// Check if device supports a specific capability
    public func supports(_ capability: String) -> Bool {
        capabilities.contains(capability)
    }
}

// MARK: - Device Group Model

/// Represents a logical group of devices that can be controlled together.
public struct DeviceGroup: Codable, Identifiable, Equatable, Hashable {
    /// Unique group identifier
    public var id: String
    
    /// Group name
    public var name: String
    
    /// IDs of devices in this group
    public var deviceIds: [String]
    
    /// Optional icon name for the group
    public var icon: String?
    
    /// Date the group was created
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        deviceIds: [String] = [],
        icon: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.deviceIds = deviceIds
        self.icon = icon
        self.createdAt = createdAt
    }
}

// MARK: - Synced Settings Model

/// App-wide settings that sync across devices via CloudKit.
/// These settings control sync behavior and app preferences.
public struct SyncedSettings: Codable, Equatable {
    /// Enable CloudKit sync
    public var cloudSyncEnabled: Bool
    
    /// Enable local network discovery (Bonjour/mDNS)
    public var localNetworkEnabled: Bool
    
    /// Enable Bluetooth discovery
    public var bluetoothEnabled: Bool
    
    /// Enable App Groups sharing with macOS app
    public var appGroupsEnabled: Bool
    
    /// Auto-refresh interval in seconds (0 = disabled)
    public var autoRefreshInterval: TimeInterval
    
    /// Show offline devices in the list
    public var showOfflineDevices: Bool
    
    /// Last sync timestamp
    public var lastSyncTime: Date?
    
    /// CloudKit container identifier
    public var cloudKitContainer: String
    
    /// App Group identifier
    public var appGroupIdentifier: String
    
    public init(
        cloudSyncEnabled: Bool = true,
        localNetworkEnabled: Bool = true,
        bluetoothEnabled: Bool = false,
        appGroupsEnabled: Bool = true,
        autoRefreshInterval: TimeInterval = 30,
        showOfflineDevices: Bool = true,
        lastSyncTime: Date? = nil,
        cloudKitContainer: String = "iCloud.com.govee.smartlights",
        appGroupIdentifier: String = "group.com.govee.mac"
    ) {
        self.cloudSyncEnabled = cloudSyncEnabled
        self.localNetworkEnabled = localNetworkEnabled
        self.bluetoothEnabled = bluetoothEnabled
        self.appGroupsEnabled = appGroupsEnabled
        self.autoRefreshInterval = autoRefreshInterval
        self.showOfflineDevices = showOfflineDevices
        self.lastSyncTime = lastSyncTime
        self.cloudKitContainer = cloudKitContainer
        self.appGroupIdentifier = appGroupIdentifier
    }
    
    /// Default settings
    public static var `default`: SyncedSettings {
        SyncedSettings()
    }
}

// MARK: - Sync Error Types

/// Errors that can occur during device sync operations
public enum SyncError: LocalizedError {
    case appGroupsNotAvailable
    case cloudKitNotAvailable
    case networkError(Error)
    case encodingError(Error)
    case decodingError(Error)
    case deviceNotFound(String)
    case groupNotFound(String)
    case invalidInput(String)
    case unauthorized
    
    public var errorDescription: String? {
        switch self {
        case .appGroupsNotAvailable:
            return "App Groups are not available. Check entitlements or use UserDefaults fallback."
        case .cloudKitNotAvailable:
            return "CloudKit is not available. Check network connection and iCloud account."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .deviceNotFound(let id):
            return "Device not found: \(id)"
        case .groupNotFound(let id):
            return "Group not found: \(id)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .unauthorized:
            return "Unauthorized access. Check permissions."
        }
    }
}
