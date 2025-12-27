//
//  CloudSyncManager.swift
//  SmartLights iOS Companion
//
//  Manages persistence and sync of devices/groups using App Groups and CloudKit.
//  
//  Architecture:
//  - iOS App writes device states to App Groups (shared with macOS app)
//  - macOS App monitors App Groups for changes and executes device commands
//  - Both apps sync via CloudKit for cross-device updates
//  - The macOS app is the source of truth for device discovery
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
    
    // MARK: - CloudKit Integration
    
    /// Fetch devices from CloudKit
    /// Syncs device state between iOS and macOS apps via iCloud
    public func fetchDevicesFromCloud() async throws -> [GoveeDevice] {
        print("☁️ Fetching devices from CloudKit...")
        
        let database = cloudKitContainer.privateCloudDatabase
        let query = CKQuery(recordType: "GoveeDevice", predicate: NSPredicate(value: true))
        
        do {
            // Fetch records from CloudKit
            let (matchResults, _) = try await database.records(matching: query)
            
            var devices: [GoveeDevice] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let device = try? convertRecordToDevice(record) {
                        devices.append(device)
                    }
                case .failure(let error):
                    print("⚠️ Failed to fetch record: \(error)")
                }
            }
            
            print("✅ Fetched \(devices.count) device(s) from CloudKit")
            return devices
        } catch {
            print("❌ CloudKit fetch failed: \(error)")
            // Fallback to local storage
            print("📦 Falling back to local storage")
            return try loadDevicesFromAppGroups()
        }
    }
    
    /// Save devices to CloudKit
    /// Syncs device state from iOS app to macOS app via iCloud
    public func saveDevicesToCloud(_ devices: [GoveeDevice]) async throws {
        print("☁️ Saving \(devices.count) device(s) to CloudKit...")
        
        // Always save to local storage first
        try saveDevicesToAppGroups(devices)
        
        let database = cloudKitContainer.privateCloudDatabase
        let records = devices.map { convertDeviceToRecord($0) }
        
        do {
            // Save records to CloudKit
            let (saveResults, _) = try await database.modifyRecords(saving: records, deleting: [])
            
            var successCount = 0
            for (_, result) in saveResults {
                switch result {
                case .success:
                    successCount += 1
                case .failure(let error):
                    print("⚠️ Failed to save record: \(error)")
                }
            }
            
            print("✅ Saved \(successCount)/\(devices.count) device(s) to CloudKit")
        } catch {
            print("⚠️ CloudKit save failed: \(error)")
            print("📦 Data saved to local storage only")
            // Don't throw - local save succeeded
        }
    }
    
    /// Fetch groups from CloudKit
    public func fetchGroupsFromCloud() async throws -> [DeviceGroup] {
        print("☁️ Fetching groups from CloudKit...")
        
        let database = cloudKitContainer.privateCloudDatabase
        let query = CKQuery(recordType: "DeviceGroup", predicate: NSPredicate(value: true))
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            
            var groups: [DeviceGroup] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let group = try? convertRecordToGroup(record) {
                        groups.append(group)
                    }
                case .failure(let error):
                    print("⚠️ Failed to fetch group record: \(error)")
                }
            }
            
            print("✅ Fetched \(groups.count) group(s) from CloudKit")
            return groups
        } catch {
            print("❌ CloudKit fetch groups failed: \(error)")
            print("📦 Falling back to local storage")
            return try loadGroupsFromAppGroups()
        }
    }
    
    /// Save groups to CloudKit
    public func saveGroupsToCloud(_ groups: [DeviceGroup]) async throws {
        print("☁️ Saving \(groups.count) group(s) to CloudKit...")
        
        // Always save to local storage first
        try saveGroupsToAppGroups(groups)
        
        let database = cloudKitContainer.privateCloudDatabase
        let records = groups.map { convertGroupToRecord($0) }
        
        do {
            let (saveResults, _) = try await database.modifyRecords(saving: records, deleting: [])
            
            var successCount = 0
            for (_, result) in saveResults {
                switch result {
                case .success:
                    successCount += 1
                case .failure(let error):
                    print("⚠️ Failed to save group record: \(error)")
                }
            }
            
            print("✅ Saved \(successCount)/\(groups.count) group(s) to CloudKit")
        } catch {
            print("⚠️ CloudKit save groups failed: \(error)")
            print("📦 Data saved to local storage only")
        }
    }
    
    // MARK: - CloudKit Record Conversion
    
    /// Convert CKRecord to GoveeDevice
    private func convertRecordToDevice(_ record: CKRecord) throws -> GoveeDevice {
        guard let id = record["id"] as? String,
              let name = record["name"] as? String,
              let model = record["model"] as? String else {
            throw SyncError.decodingError(NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"]))
        }
        
        let isOnline = record["isOnline"] as? Int == 1
        let powerState = record["powerState"] as? Int == 1
        let brightness = record["brightness"] as? Int ?? 100
        
        let red = record["colorRed"] as? Int ?? 255
        let green = record["colorGreen"] as? Int ?? 255
        let blue = record["colorBlue"] as? Int ?? 255
        let kelvin = record["colorKelvin"] as? Int
        let color = DeviceColor(red: red, green: green, blue: blue, kelvin: kelvin)
        
        let capabilitiesString = record["capabilities"] as? String ?? "color,brightness"
        let capabilities = capabilitiesString.components(separatedBy: ",")
        
        let lastSeen = record["lastSeen"] as? Date ?? Date()
        let groupId = record["groupId"] as? String
        
        return GoveeDevice(
            id: id,
            name: name,
            model: model,
            isOnline: isOnline,
            powerState: powerState,
            brightness: brightness,
            color: color,
            capabilities: capabilities,
            lastSeen: lastSeen,
            groupId: groupId
        )
    }
    
    /// Convert GoveeDevice to CKRecord
    private func convertDeviceToRecord(_ device: GoveeDevice) -> CKRecord {
        let recordID = CKRecord.ID(recordName: "device-\(device.id)")
        let record = CKRecord(recordType: "GoveeDevice", recordID: recordID)
        
        record["id"] = device.id as CKRecordValue
        record["name"] = device.name as CKRecordValue
        record["model"] = device.model as CKRecordValue
        record["isOnline"] = (device.isOnline ? 1 : 0) as CKRecordValue
        record["powerState"] = (device.powerState ? 1 : 0) as CKRecordValue
        record["brightness"] = device.brightness as CKRecordValue
        record["colorRed"] = device.color.red as CKRecordValue
        record["colorGreen"] = device.color.green as CKRecordValue
        record["colorBlue"] = device.color.blue as CKRecordValue
        if let kelvin = device.color.kelvin {
            record["colorKelvin"] = kelvin as CKRecordValue
        }
        record["capabilities"] = device.capabilities.joined(separator: ",") as CKRecordValue
        record["lastSeen"] = device.lastSeen as CKRecordValue
        if let groupId = device.groupId {
            record["groupId"] = groupId as CKRecordValue
        }
        
        return record
    }
    
    /// Convert CKRecord to DeviceGroup
    private func convertRecordToGroup(_ record: CKRecord) throws -> DeviceGroup {
        guard let id = record["id"] as? String,
              let name = record["name"] as? String else {
            throw SyncError.decodingError(NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"]))
        }
        
        let deviceIdsString = record["deviceIds"] as? String ?? ""
        let deviceIds = deviceIdsString.isEmpty ? [] : deviceIdsString.components(separatedBy: ",")
        let icon = record["icon"] as? String
        let createdAt = record["createdAt"] as? Date ?? Date()
        
        return DeviceGroup(
            id: id,
            name: name,
            deviceIds: deviceIds,
            icon: icon,
            createdAt: createdAt
        )
    }
    
    /// Convert DeviceGroup to CKRecord
    private func convertGroupToRecord(_ group: DeviceGroup) -> CKRecord {
        let recordID = CKRecord.ID(recordName: "group-\(group.id)")
        let record = CKRecord(recordType: "DeviceGroup", recordID: recordID)
        
        record["id"] = group.id as CKRecordValue
        record["name"] = group.name as CKRecordValue
        record["deviceIds"] = group.deviceIds.joined(separator: ",") as CKRecordValue
        if let icon = group.icon {
            record["icon"] = icon as CKRecordValue
        }
        record["createdAt"] = group.createdAt as CKRecordValue
        
        return record
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
