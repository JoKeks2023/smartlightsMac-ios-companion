//
//  SmartLightsIOSCompanionApp.swift
//  SmartLights iOS Companion
//
//  Main app entry point for the iOS companion app.
//  Initializes sync managers, device store, and provides them as environment objects.
//

import SwiftUI

@main
struct SmartLightsIOSCompanionApp: App {
    // MARK: - State Objects
    
    /// Cloud sync manager for persistence
    @StateObject private var cloudSyncManager = CloudSyncManager()
    
    /// Device store (shared state)
    @StateObject private var deviceStore = DeviceStore()
    
    /// Unified sync manager
    @StateObject private var syncManager: MultiTransportSyncManager
    
    /// Remote control client
    @StateObject private var remoteControlClient: RemoteControlClient
    
    // MARK: - Initialization
    
    init() {
        // Note: We create instances locally to properly initialize StateObjects
        // SwiftUI requires StateObject initialization in init(), and we need the instances
        // to wire dependencies. The same instances are wrapped and used throughout.
        let cloudSync = CloudSyncManager()
        let store = DeviceStore()
        let multiSync = MultiTransportSyncManager(
            cloudSyncManager: cloudSync,
            deviceStore: store
        )
        let remoteClient = RemoteControlClient(
            syncManager: multiSync,
            deviceStore: store
        )
        
        // Wrap the same instances in StateObjects
        _cloudSyncManager = StateObject(wrappedValue: cloudSync)
        _deviceStore = StateObject(wrappedValue: store)
        _syncManager = StateObject(wrappedValue: multiSync)
        _remoteControlClient = StateObject(wrappedValue: remoteClient)
        
        print("🚀 SmartLights iOS App initializing...")
    }
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deviceStore)
                .environmentObject(syncManager)
                .environmentObject(remoteControlClient)
                .task {
                    // Initialize on app launch
                    await initializeApp()
                }
        }
    }
    
    // MARK: - Initialization
    
    @MainActor
    private func initializeApp() async {
        print("🔧 Initializing iOS companion app...")
        print("📱 This app is a remote control for the macOS SmartLights app")
        
        // Enable App Groups by default (with UserDefaults fallback)
        // This syncs with the Mac app on the same device
        await syncManager.enableTransport(.appGroups)
        
        // Check and enable CloudKit if available
        // This syncs across devices via iCloud
        await syncManager.enableTransport(.cloud)
        
        // Load settings
        let settings = await remoteControlClient.getSettings()
        
        // Add sample devices if store is empty (for first launch demo)
        if deviceStore.devices.isEmpty {
            print("📦 No devices found, adding sample devices for demo")
            await addSampleDevices()
        }
        
        print("✅ App initialization complete")
    }
    
    // MARK: - Sample Data (for demo/testing)
    
    private func addSampleDevices() async {
        let sampleDevices = [
            GoveeDevice(
                id: "AA:BB:CC:DD:EE:01",
                name: "Living Room Light",
                model: "H6159",
                isOnline: true,
                powerState: false,
                brightness: 80,
                color: .white,
                capabilities: ["color", "brightness", "colorTemperature"]
            ),
            GoveeDevice(
                id: "AA:BB:CC:DD:EE:02",
                name: "Bedroom Strip",
                model: "H6182",
                isOnline: true,
                powerState: true,
                brightness: 50,
                color: DeviceColor(red: 100, green: 50, blue: 200),
                capabilities: ["color", "brightness"]
            ),
            GoveeDevice(
                id: "AA:BB:CC:DD:EE:03",
                name: "Kitchen Lights",
                model: "H6159",
                isOnline: false,
                powerState: false,
                brightness: 100,
                color: .warmWhite,
                capabilities: ["color", "brightness", "colorTemperature"]
            )
        ]
        
        deviceStore.replaceAllDevices(sampleDevices)
        
        // Save to persistent storage
        await syncManager.saveDevices(sampleDevices)
        
        print("✅ Added \(sampleDevices.count) sample devices")
    }
}
