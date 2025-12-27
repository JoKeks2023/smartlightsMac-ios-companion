//
//  DeviceStore.swift
//  SmartLights iOS Companion
//
//  Observable store for managing devices and groups in memory.
//  Acts as the single source of truth for UI and syncs with persistent storage.
//

import Foundation
import Combine
import SwiftUI

/// Observable store that manages the in-memory collection of devices and groups.
/// This store is used by SwiftUI views and updated by sync managers.
@MainActor
public class DeviceStore: ObservableObject {
    /// Published array of all devices
    @Published public var devices: [GoveeDevice] = []
    
    /// Published array of all device groups
    @Published public var groups: [DeviceGroup] = []
    
    /// Computed property for online devices only
    public var onlineDevices: [GoveeDevice] {
        devices.filter { $0.isOnline }
    }
    
    /// Computed property for offline devices
    public var offlineDevices: [GoveeDevice] {
        devices.filter { !$0.isOnline }
    }
    
    public init(devices: [GoveeDevice] = [], groups: [DeviceGroup] = []) {
        self.devices = devices
        self.groups = groups
    }
    
    // MARK: - Device Operations
    
    /// Replace all devices with a new array
    public func replaceAllDevices(_ newDevices: [GoveeDevice]) {
        devices = newDevices
    }
    
    /// Add or update a device
    public func upsertDevice(_ device: GoveeDevice) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
    }
    
    /// Update multiple devices
    public func upsertDevices(_ newDevices: [GoveeDevice]) {
        for device in newDevices {
            upsertDevice(device)
        }
    }
    
    /// Find a device by ID
    public func device(withId id: String) -> GoveeDevice? {
        devices.first { $0.id == id }
    }
    
    /// Remove a device by ID
    public func removeDevice(withId id: String) {
        devices.removeAll { $0.id == id }
    }
    
    /// Update device power state
    public func updateDevicePower(deviceId: String, powerState: Bool) {
        guard let index = devices.firstIndex(where: { $0.id == deviceId }) else { return }
        devices[index].powerState = powerState
        devices[index].lastSeen = Date()
    }
    
    /// Update device brightness
    public func updateDeviceBrightness(deviceId: String, brightness: Int) {
        guard let index = devices.firstIndex(where: { $0.id == deviceId }) else { return }
        devices[index].brightness = max(0, min(100, brightness))
        devices[index].lastSeen = Date()
    }
    
    /// Update device color
    public func updateDeviceColor(deviceId: String, color: DeviceColor) {
        guard let index = devices.firstIndex(where: { $0.id == deviceId }) else { return }
        devices[index].color = color
        devices[index].lastSeen = Date()
    }
    
    /// Update device color temperature
    public func updateDeviceColorTemperature(deviceId: String, kelvin: Int) {
        guard let index = devices.firstIndex(where: { $0.id == deviceId }) else { return }
        // Preserve RGB values when updating kelvin to support devices with both modes
        var updatedColor = devices[index].color
        updatedColor.kelvin = kelvin
        devices[index].color = updatedColor
        devices[index].lastSeen = Date()
    }
    
    // MARK: - Group Operations
    
    /// Replace all groups with a new array
    public func replaceAllGroups(_ newGroups: [DeviceGroup]) {
        groups = newGroups
    }
    
    /// Add or update a group
    public func upsertGroup(_ group: DeviceGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.append(group)
        }
    }
    
    /// Find a group by ID
    public func group(withId id: String) -> DeviceGroup? {
        groups.first { $0.id == id }
    }
    
    /// Remove a group by ID
    public func removeGroup(withId id: String) {
        groups.removeAll { $0.id == id }
        // Also remove group association from devices
        for index in devices.indices {
            if devices[index].groupId == id {
                devices[index].groupId = nil
            }
        }
    }
    
    /// Get all devices in a specific group
    public func devices(inGroup groupId: String) -> [GoveeDevice] {
        guard let group = group(withId: groupId) else { return [] }
        return devices.filter { group.deviceIds.contains($0.id) }
    }
    
    /// Add a device to a group
    public func addDevice(_ deviceId: String, toGroup groupId: String) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }) else { return }
        if !groups[groupIndex].deviceIds.contains(deviceId) {
            groups[groupIndex].deviceIds.append(deviceId)
        }
        
        // Update device's groupId
        if let deviceIndex = devices.firstIndex(where: { $0.id == deviceId }) {
            devices[deviceIndex].groupId = groupId
        }
    }
    
    /// Remove a device from a group
    public func removeDevice(_ deviceId: String, fromGroup groupId: String) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[groupIndex].deviceIds.removeAll { $0 == deviceId }
        
        // Clear device's groupId if it matches
        if let deviceIndex = devices.firstIndex(where: { $0.id == deviceId }) {
            if devices[deviceIndex].groupId == groupId {
                devices[deviceIndex].groupId = nil
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Clear all data
    public func clear() {
        devices = []
        groups = []
    }
    
    /// Get count of devices
    public var deviceCount: Int {
        devices.count
    }
    
    /// Get count of groups
    public var groupCount: Int {
        groups.count
    }
    
    /// Get count of online devices
    public var onlineDeviceCount: Int {
        onlineDevices.count
    }
}
