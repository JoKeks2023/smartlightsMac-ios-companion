//
//  ConnectionStatusView.swift
//  SmartLights iOS Companion
//
//  A compact view showing current connection status across all transports.
//

import SwiftUI

struct ConnectionStatusView: View {
    @EnvironmentObject var syncManager: MultiTransportSyncManager
    
    var body: some View {
        HStack(spacing: 6) {
            // Cloud status
            if syncManager.isConnectedViaCloud {
                Image(systemName: "icloud.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            // Local network status
            if syncManager.isConnectedViaLocalNetwork {
                Image(systemName: "network")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            // Bluetooth status
            if syncManager.isConnectedViaBluetooth {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            // Offline indicator if nothing is connected
            if !syncManager.isAnyTransportConnected {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

// MARK: - Detailed Connection Status View

struct DetailedConnectionStatusView: View {
    @EnvironmentObject var syncManager: MultiTransportSyncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Status")
                .font(.headline)
            
            HStack {
                Image(systemName: "icloud.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text("CloudKit")
                Spacer()
                statusIndicator(syncManager.isConnectedViaCloud)
            }
            
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.green)
                    .frame(width: 24)
                Text("Local Network")
                Spacer()
                statusIndicator(syncManager.isConnectedViaLocalNetwork)
            }
            
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text("Bluetooth")
                Spacer()
                statusIndicator(syncManager.isConnectedViaBluetooth)
            }
            
            Divider()
            
            HStack {
                Text("Status")
                    .foregroundColor(.secondary)
                Spacer()
                Text(syncManager.statusMessage)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            
            if let lastSync = syncManager.lastSyncTime {
                HStack {
                    Text("Last Sync")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
    
    @ViewBuilder
    private func statusIndicator(_ isConnected: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct ConnectionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Compact view
            ConnectionStatusView()
                .environmentObject({
                    let store = DeviceStore()
                    let cloudSync = CloudSyncManager()
                    let manager = MultiTransportSyncManager(
                        cloudSyncManager: cloudSync,
                        deviceStore: store
                    )
                    manager.isConnectedViaCloud = true
                    manager.isConnectedViaLocalNetwork = true
                    return manager
                }())
            
            // Detailed view
            DetailedConnectionStatusView()
                .environmentObject({
                    let store = DeviceStore()
                    let cloudSync = CloudSyncManager()
                    let manager = MultiTransportSyncManager(
                        cloudSyncManager: cloudSync,
                        deviceStore: store
                    )
                    manager.isConnectedViaCloud = true
                    manager.isConnectedViaLocalNetwork = false
                    manager.isConnectedViaBluetooth = false
                    manager.statusMessage = "CloudKit connected"
                    manager.lastSyncTime = Date()
                    return manager
                }())
        }
        .padding()
    }
}
