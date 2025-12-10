//
//  MainTabView.swift
//  SmartLights iOS Companion
//
//  Main tab navigation view with three tabs: Devices, Groups, Settings.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var syncManager: MultiTransportSyncManager
    @EnvironmentObject var remoteControlClient: RemoteControlClient
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Devices Tab
            NavigationView {
                DeviceListView()
            }
            .tabItem {
                Label("Devices", systemImage: "lightbulb.fill")
            }
            .tag(0)
            
            // Groups Tab (Placeholder)
            NavigationView {
                GroupsPlaceholderView()
            }
            .tabItem {
                Label("Groups", systemImage: "square.grid.2x2.fill")
            }
            .tag(1)
            
            // Settings Tab
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - Groups Placeholder View

struct GroupsPlaceholderView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Device Groups")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Group management coming soon!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if deviceStore.groupCount > 0 {
                Text("\(deviceStore.groupCount) groups available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Groups")
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DeviceStore(devices: [
            GoveeDevice(
                id: "test1",
                name: "Test Light",
                model: "H6159",
                powerState: true,
                brightness: 75
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
        
        MainTabView()
            .environmentObject(store)
            .environmentObject(syncManager)
            .environmentObject(remoteClient)
    }
}
