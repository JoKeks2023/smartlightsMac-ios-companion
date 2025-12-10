//
//  SettingsView.swift
//  SmartLights iOS Companion
//
//  Settings view for configuring sync transports and app preferences.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var syncManager: MultiTransportSyncManager
    @EnvironmentObject var remoteControlClient: RemoteControlClient
    @EnvironmentObject var deviceStore: DeviceStore
    
    @State private var settings: SyncedSettings = .default
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        List {
            // Sync Transports Section
            Section {
                Toggle(isOn: $settings.cloudSyncEnabled) {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CloudKit Sync")
                            Text("Sync devices via iCloud")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $settings.localNetworkEnabled) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Local Network")
                            Text("Discover devices on your network")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $settings.bluetoothEnabled) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bluetooth")
                            Text("Connect via Bluetooth Low Energy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $settings.appGroupsEnabled) {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Groups Sharing")
                            Text("Share data with macOS app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Sync Transports")
            } footer: {
                Text("Enable sync transports to discover and control devices. CloudKit requires iCloud sign-in. Local Network and Bluetooth require appropriate permissions.")
            }
            
            // Display Options Section
            Section {
                Toggle(isOn: $settings.showOfflineDevices) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundColor(.gray)
                        Text("Show Offline Devices")
                    }
                }
                
                Stepper(value: $settings.autoRefreshInterval, in: 0...300, step: 30) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Refresh")
                            if settings.autoRefreshInterval > 0 {
                                Text("Every \(Int(settings.autoRefreshInterval))s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Disabled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Display Options")
            }
            
            // Configuration Section
            Section {
                HStack {
                    Text("App Group ID")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(settings.appGroupIdentifier)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("CloudKit Container")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(settings.cloudKitContainer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Configuration")
            } footer: {
                Text("These identifiers must match your Xcode project's App Groups and CloudKit capabilities.")
            }
            
            // Status Section
            Section {
                HStack {
                    Text("Last Sync")
                        .foregroundColor(.secondary)
                    Spacer()
                    if let lastSync = settings.lastSyncTime {
                        Text(lastSync, style: .relative)
                    } else {
                        Text("Never")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Devices")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(deviceStore.deviceCount)")
                }
                
                HStack {
                    Text("Online")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(deviceStore.onlineDeviceCount)")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Groups")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(deviceStore.groupCount)")
                }
            } header: {
                Text("Status")
            }
            
            // Connection Status Section
            Section {
                HStack {
                    Image(systemName: syncManager.isConnectedViaCloud ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(syncManager.isConnectedViaCloud ? .green : .red)
                    Text("CloudKit")
                    Spacer()
                    Text(syncManager.isConnectedViaCloud ? "Connected" : "Disconnected")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: syncManager.isConnectedViaLocalNetwork ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(syncManager.isConnectedViaLocalNetwork ? .green : .red)
                    Text("Local Network")
                    Spacer()
                    Text(syncManager.isConnectedViaLocalNetwork ? "Active" : "Inactive")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: syncManager.isConnectedViaBluetooth ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(syncManager.isConnectedViaBluetooth ? .green : .red)
                    Text("Bluetooth")
                    Spacer()
                    Text(syncManager.isConnectedViaBluetooth ? "Active" : "Inactive")
                        .foregroundColor(.secondary)
                }
                
                if !syncManager.discoveredPeers.isEmpty {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                        Text("Discovered Peers")
                        Spacer()
                        Text("\(syncManager.discoveredPeers.count)")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Connection Status")
            }
            
            // Actions Section
            Section {
                Button {
                    Task {
                        await syncManager.syncNow()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                }
                .disabled(isSaving)
            }
            
            // About Section
            Section {
                HStack {
                    Text("Version")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1.0.0")
                }
                
                if let githubURL = URL(string: "https://github.com/JoKeks2023/smartlightsMac-ios-companion") {
                    Link(destination: githubURL) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                }
            } header: {
                Text("About")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveSettings()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSaving)
            }
        }
        .alert("Settings Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your settings have been saved and will be synced across devices.")
        }
        .task {
            await loadSettings()
        }
    }
    
    // MARK: - Methods
    
    private func loadSettings() async {
        isLoading = true
        settings = await remoteControlClient.getSettings()
        isLoading = false
    }
    
    private func saveSettings() {
        Task {
            isSaving = true
            do {
                try await remoteControlClient.updateSettings(settings)
                showingSaveConfirmation = true
            } catch {
                print("❌ Failed to save settings: \(error)")
            }
            isSaving = false
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DeviceStore()
        let cloudSync = CloudSyncManager()
        let syncManager = MultiTransportSyncManager(
            cloudSyncManager: cloudSync,
            deviceStore: store
        )
        let remoteClient = RemoteControlClient(
            syncManager: syncManager,
            deviceStore: store
        )
        
        NavigationView {
            SettingsView()
                .environmentObject(store)
                .environmentObject(syncManager)
                .environmentObject(remoteClient)
        }
    }
}
