import SwiftUI

struct ContentView: View {
    @StateObject private var deviceStore: DeviceStore
    @StateObject private var cloudSyncManager: CloudSyncManager
    @StateObject private var syncManager: MultiTransportSyncManager
    @StateObject private var remoteControlClient: RemoteControlClient
    
    init() {
        let deviceStore = DeviceStore()
        let cloudSyncManager = CloudSyncManager()
        let syncManager = MultiTransportSyncManager(
            cloudSyncManager: cloudSyncManager,
            deviceStore: deviceStore
        )
        let remoteControlClient = RemoteControlClient(
            syncManager: syncManager,
            deviceStore: deviceStore
        )
        
        _deviceStore = StateObject(wrappedValue: deviceStore)
        _cloudSyncManager = StateObject(wrappedValue: cloudSyncManager)
        _syncManager = StateObject(wrappedValue: syncManager)
        _remoteControlClient = StateObject(wrappedValue: remoteControlClient)
    }
    
    var body: some View {
        MainTabView()
            .environmentObject(deviceStore)
            .environmentObject(syncManager)
            .environmentObject(remoteControlClient)
    }
}

#Preview {
    ContentView()
}
