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
            
            // App Groups / Mac App status
            if syncManager.isConnectedViaAppGroups {
                Image(systemName: "laptopcomputer")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            // Not synced indicator if nothing is connected
            if !syncManager.isAnyTransportConnected {
                Image(systemName: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.orange)
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
            Text("Sync Status")
                .font(.headline)
            
            HStack {
                Image(systemName: "icloud.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text("iCloud Sync")
                Spacer()
                statusIndicator(syncManager.isConnectedViaCloud)
            }
            
            HStack {
                Image(systemName: "laptopcomputer")
                    .foregroundColor(.green)
                    .frame(width: 24)
                Text("Mac App (Local)")
                Spacer()
                statusIndicator(syncManager.isConnectedViaAppGroups)
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
            
            Text("The iOS app is a remote for the Mac app")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
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
                .fill(isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Synced" : "Not Synced")
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
