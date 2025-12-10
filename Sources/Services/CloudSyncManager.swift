//
//  CloudSyncManager.swift
//  SmartLights iOS Companion
//
//  Manages persistence and sync of devices/groups using App Groups and CloudKit.
//  Implements local storage via App Groups (with UserDefaults fallback) and
//  provides stubs for CloudKit integration.
//
//  TODO: See IOS_BRIDGE_DEVELOPER_GUIDE.md for full CloudKit implementation details.
//

import Foundation
import CloudKit

/// Manages device/group persistence and CloudKit sync.
@MainActor
public class CloudSyncManager: ObservableObject {
    // MARK: - Properties
    
    /// App Group identifier for sharing data with macOS app
    private let appGroupIdentifier: String
    
    /// CloudKit container identifier
    private let cloudKitContainerIdentifier: String
    
    /// UserDefaults instance (either App Group or standard)
    private let userDefaults: UserDefaults
    
    /// Whether App Groups are available
    private let isAppGroupsAvailable: Bool
    
    /// CloudKit container (lazy loaded)
    private lazy var cloudKitContainer: CKContainer = {
        CKContainer(identifier: cloudKitContainerIdentifier)
    }()
    
    // Storage keys
    private let devicesKey = "com.govee.smartlights.devices"
    private let groupsKey = "com.govee.smartlights.groups"
    private let settingsKey = "com.govee.smartlights.settings"
    
    // MARK: - Initialization
    
    public init(
        appGroupIdentifier: String = "group.com.govee.mac",
        cloudKitContainerIdentifier: String = "iCloud.com.govee.smartlights"
    ) {
        self.appGroupIdentifier = appGroupIdentifier
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        
        // Try to access App Group container
        if let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            self.userDefaults = groupDefaults
            self.isAppGroupsAvailable = true
            print("✅ CloudSyncManager: Using App Groups container '\(appGroupIdentifier)'")
        } else {
            // Fallback to standard UserDefaults (for Simulator or when entitlements not configured)
            self.userDefaults = UserDefaults.standard
            self.isAppGroupsAvailable = false
            print("⚠️ CloudSyncManager: App Groups not available, falling back to UserDefaults.standard")
            print("   To enable App Groups: Add 'App Groups' capability with identifier '\(appGroupIdentifier)' in Xcode")
        }
    }
    
    // MARK: - App Groups / Local Storage
    
    /// Load devices from App Groups (or UserDefaults fallback)
    public func loadDevicesFromAppGroups() throws -> [GoveeDevice] {
        guard let data = userDefaults.data(forKey: devicesKey) else {
            print("📦 No devices found in storage, returning empty array")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let devices = try decoder.decode([GoveeDevice].self, from: data)
            print("✅ Loaded \(devices.count) device(s) from storage")
            return devices
        } catch {
            print("❌ Failed to decode devices: \(error)")
            throw SyncError.decodingError(error)
        }
    }
    
    /// Save devices to App Groups (or UserDefaults fallback)
    public func saveDevicesToAppGroups(_ devices: [GoveeDevice]) throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(devices)
            userDefaults.set(data, forKey: devicesKey)
            userDefaults.synchronize()
            print("✅ Saved \(devices.count) device(s) to storage")
        } catch {
            print("❌ Failed to encode devices: \(error)")
            throw SyncError.encodingError(error)
        }
    }
    
    /// Load groups from App Groups (or UserDefaults fallback)
    public func loadGroupsFromAppGroups() throws -> [DeviceGroup] {
        guard let data = userDefaults.data(forKey: groupsKey) else {
            print("📦 No groups found in storage, returning empty array")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let groups = try decoder.decode([DeviceGroup].self, from: data)
            print("✅ Loaded \(groups.count) group(s) from storage")
            return groups
        } catch {
            print("❌ Failed to decode groups: \(error)")
            throw SyncError.decodingError(error)
        }
    }
    
    /// Save groups to App Groups (or UserDefaults fallback)
    public func saveGroupsToAppGroups(_ groups: [DeviceGroup]) throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(groups)
            userDefaults.set(data, forKey: groupsKey)
            userDefaults.synchronize()
            print("✅ Saved \(groups.count) group(s) to storage")
        } catch {
            print("❌ Failed to encode groups: \(error)")
            throw SyncError.encodingError(error)
        }
    }
    
    /// Load settings from storage
    public func loadSettings() -> SyncedSettings {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            print("📦 No settings found, returning defaults")
            return .default
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let settings = try decoder.decode(SyncedSettings.self, from: data)
            print("✅ Loaded settings from storage")
            return settings
        } catch {
            print("❌ Failed to decode settings: \(error), returning defaults")
            return .default
        }
    }
    
    /// Save settings to storage
    public func saveSettings(_ settings: SyncedSettings) throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: settingsKey)
            userDefaults.synchronize()
            print("✅ Saved settings to storage")
        } catch {
            print("❌ Failed to encode settings: \(error)")
            throw SyncError.encodingError(error)
        }
    }
    
    // MARK: - CloudKit Integration (Stubs)
    
    /// Fetch devices from CloudKit.
    /// TODO: This is a stub. Implement full CloudKit fetch using CKDatabase queries.
    /// See IOS_BRIDGE_DEVELOPER_GUIDE.md for CloudKit record structure and query examples.
    public func fetchDevicesFromCloud() async throws -> [GoveeDevice] {
        print("☁️ CloudKit fetch called (stub implementation)")
        
        // For now, return locally saved devices to provide some functionality
        // In production, this should:
        // 1. Query cloudKitContainer.privateCloudDatabase
        // 2. Fetch CKRecord objects of type "GoveeDevice"
        // 3. Convert CKRecords to GoveeDevice models
        // 4. Handle pagination, errors, and conflicts
        
        // Stub: Return local devices
        return try loadDevicesFromAppGroups()
        
        // TODO: Uncomment and implement real CloudKit fetch:
        /*
        let database = cloudKitContainer.privateCloudDatabase
        let query = CKQuery(recordType: "GoveeDevice", predicate: NSPredicate(value: true))
        let results = try await database.records(matching: query)
        // Convert CKRecords to [GoveeDevice]
        return convertedDevices
        */
    }
    
    /// Save devices to CloudKit.
    /// TODO: This is a stub. Implement full CloudKit save.
    public func saveDevicesToCloud(_ devices: [GoveeDevice]) async throws {
        print("☁️ CloudKit save called (stub implementation)")
        
        // For now, just save locally
        try saveDevicesToAppGroups(devices)
        
        // TODO: Uncomment and implement real CloudKit save:
        /*
        let database = cloudKitContainer.privateCloudDatabase
        let records = devices.map { convertToCloudKitRecord($0) }
        try await database.save(records)
        */
    }
    
    /// Fetch groups from CloudKit (stub)
    public func fetchGroupsFromCloud() async throws -> [DeviceGroup] {
        print("☁️ CloudKit fetch groups called (stub)")
        return try loadGroupsFromAppGroups()
    }
    
    /// Save groups to CloudKit (stub)
    public func saveGroupsToCloud(_ groups: [DeviceGroup]) async throws {
        print("☁️ CloudKit save groups called (stub)")
        try saveGroupsToAppGroups(groups)
    }
    
    /// Check CloudKit account status
    public func checkCloudKitStatus() async -> Bool {
        do {
            let status = try await cloudKitContainer.accountStatus()
            switch status {
            case .available:
                print("✅ CloudKit account available")
                return true
            case .noAccount:
                print("⚠️ No iCloud account signed in")
                return false
            case .restricted:
                print("⚠️ CloudKit access restricted")
                return false
            case .couldNotDetermine:
                print("⚠️ Could not determine CloudKit status")
                return false
            case .temporarilyUnavailable:
                print("⚠️ CloudKit temporarily unavailable")
                return false
            @unknown default:
                print("⚠️ Unknown CloudKit status")
                return false
            }
        } catch {
            print("❌ Error checking CloudKit status: \(error)")
            return false
        }
    }
    
    // MARK: - Utility
    
    /// Clear all local storage
    public func clearLocalStorage() {
        userDefaults.removeObject(forKey: devicesKey)
        userDefaults.removeObject(forKey: groupsKey)
        userDefaults.removeObject(forKey: settingsKey)
        userDefaults.synchronize()
        print("🗑️ Cleared all local storage")
    }
    
    /// Get storage info for debugging
    public func getStorageInfo() -> String {
        """
        📊 Storage Info:
        - App Groups Available: \(isAppGroupsAvailable)
        - App Group ID: \(appGroupIdentifier)
        - CloudKit Container: \(cloudKitContainerIdentifier)
        - Using: \(isAppGroupsAvailable ? "App Groups" : "UserDefaults.standard")
        """
    }
}
