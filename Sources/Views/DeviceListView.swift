//
//  DeviceListView.swift
//  SmartLights iOS Companion
//
//  List view displaying all discovered Govee devices with quick controls.
//

import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var syncManager: MultiTransportSyncManager
    @EnvironmentObject var remoteControlClient: RemoteControlClient
    
    @State private var showOfflineDevices = true
    @State private var isRefreshing = false
    
    var displayedDevices: [GoveeDevice] {
        if showOfflineDevices {
            return deviceStore.devices
        } else {
            return deviceStore.onlineDevices
        }
    }
    
    var body: some View {
        ZStack {
            if deviceStore.devices.isEmpty {
                emptyStateView
            } else {
                deviceList
            }
        }
        .navigationTitle("Devices")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    ConnectionStatusView()
                    
                    Button {
                        Task {
                            isRefreshing = true
                            do {
                                try await remoteControlClient.refreshDevices()
                            } catch {
                                print("❌ Refresh failed: \(error)")
                            }
                            isRefreshing = false
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isRefreshing
                            )
                    }
                    .disabled(isRefreshing)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showOfflineDevices.toggle()
                } label: {
                    Image(systemName: showOfflineDevices ? "eye.fill" : "eye.slash.fill")
                }
            }
        }
    }
    
    // MARK: - Device List
    
    private var deviceList: some View {
        List {
            Section {
                ForEach(displayedDevices) { device in
                    NavigationLink {
                        DeviceControlView(device: device)
                    } label: {
                        DeviceRowView(device: device)
                    }
                }
            } header: {
                HStack {
                    Text("\(displayedDevices.count) Device(s)")
                    Spacer()
                    if !showOfflineDevices && deviceStore.offlineDevices.count > 0 {
                        Text("\(deviceStore.offlineDevices.count) hidden")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            do {
                try await remoteControlClient.refreshDevices()
            } catch {
                print("❌ Refresh failed: \(error)")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Devices Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Pull down to refresh or check your sync settings")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task {
                    do {
                        try await remoteControlClient.refreshDevices()
                    } catch {
                        print("❌ Refresh failed: \(error)")
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Device Row View

struct DeviceRowView: View {
    let device: GoveeDevice
    @EnvironmentObject var remoteControlClient: RemoteControlClient
    
    @State private var isUpdating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(device.color.swiftUIColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(device.model)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: device.isOnline ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.caption)
                        Text(device.isOnline ? "Online" : "Offline")
                            .font(.caption)
                    }
                    .foregroundColor(device.isOnline ? .green : .red)
                }
            }
            
            Spacer()
            
            // Quick power toggle
            Toggle("", isOn: Binding(
                get: { device.powerState },
                set: { newValue in
                    Task {
                        isUpdating = true
                        do {
                            try await remoteControlClient.setDevicePower(
                                deviceId: device.id,
                                powerState: newValue
                            )
                        } catch {
                            print("❌ Failed to toggle power: \(error)")
                        }
                        isUpdating = false
                    }
                }
            ))
            .labelsHidden()
            .disabled(isUpdating || !device.isOnline)
        }
        .opacity(device.isOnline ? 1.0 : 0.5)
    }
}

// MARK: - Preview

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DeviceStore(devices: [
            GoveeDevice(
                id: "1",
                name: "Living Room",
                model: "H6159",
                isOnline: true,
                powerState: true,
                brightness: 80,
                color: DeviceColor(red: 255, green: 100, blue: 50)
            ),
            GoveeDevice(
                id: "2",
                name: "Bedroom",
                model: "H6182",
                isOnline: false,
                powerState: false
            )
        ])
        
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
            DeviceListView()
                .environmentObject(store)
                .environmentObject(syncManager)
                .environmentObject(remoteClient)
        }
    }
}
