# SmartLights iOS Companion

iOS Companion app for controlling Govee smart lights, designed to sync with the SmartLights macOS app.

## Features

- 📱 **Device Control**: Power, brightness, color, and color temperature control
- ☁️ **Multi-Transport Sync**: CloudKit, App Groups, Local Network, and Bluetooth (stubs)
- 🔄 **Real-time Updates**: Changes persist across devices via App Groups and CloudKit
- 🎨 **Color Controls**: RGB color picker with presets and color temperature adjustment
- 👥 **Device Groups**: Organize and control multiple devices together (coming soon)
- ⚙️ **Flexible Settings**: Configure sync transports and display options

## Requirements

- iOS 15.0 or later
- Xcode 14.0 or later
- Swift 5.5+
- Optional: iCloud account for CloudKit sync
- Optional: macOS app for App Groups sharing

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/JoKeks2023/smartlightsMac-ios-companion.git
cd smartlightsMac-ios-companion
```

### 2. Open in Xcode

Open the project in Xcode:

```bash
open SmartLightsIOSCompanion.xcodeproj
```

**Note**: If there's no `.xcodeproj` file yet, you'll need to create one:
1. Open Xcode
2. File > New > Project
3. Choose "iOS" > "App"
4. Product Name: "SmartLightsIOSCompanion"
5. Interface: SwiftUI
6. Language: Swift
7. Add all the source files from this repository

### 3. Configure Capabilities (Optional but Recommended)

To enable full functionality, configure these capabilities in Xcode:

#### App Groups (for sharing with macOS app)
1. Select your target in Xcode
2. Go to "Signing & Capabilities"
3. Click "+ Capability" and add "App Groups"
4. Add group: `group.com.govee.mac`

**Note**: If you don't configure App Groups, the app will automatically fall back to using `UserDefaults.standard` for local storage. This is fine for testing but won't sync with the macOS app.

#### CloudKit (for cloud sync)
1. In "Signing & Capabilities"
2. Click "+ Capability" and add "iCloud"
3. Enable "CloudKit"
4. Add container: `iCloud.com.govee.smartlights`

**Note**: CloudKit requires signing in with an Apple ID in the Simulator/device settings.

#### Background Modes (optional, for refresh)
1. Add "Background Modes" capability
2. Enable "Background fetch" and "Remote notifications"

### 4. Build and Run

1. Select a target device or simulator (iPhone 13 or later recommended)
2. Press Cmd+R or click the "Run" button
3. The app will launch with sample devices pre-populated for testing

## Project Structure

```
SmartLightsIOSCompanion/
├── SmartLightsIOSApp.swift          # App entry point and initialization
├── Sources/
│   ├── Models/
│   │   └── GoveeModels.swift        # Data models: Device, Group, Settings
│   ├── Stores/
│   │   └── DeviceStore.swift        # Observable device/group store
│   ├── Services/
│   │   ├── CloudSyncManager.swift   # App Groups & CloudKit persistence
│   │   ├── MultiTransportSyncManager.swift  # Unified sync facade
│   │   └── RemoteControlProtocol.swift      # Device control API
│   ├── Views/
│   │   ├── MainTabView.swift        # Main tab navigation
│   │   ├── DeviceListView.swift     # Device list with quick controls
│   │   ├── DeviceControlView.swift  # Detailed device control
│   │   ├── SettingsView.swift       # App settings
│   │   └── ConnectionStatusView.swift # Connection status indicator
│   └── Utils/
│       └── DeviceColor+Extensions.swift # Color conversion utilities
└── README.md
```

## Usage

### Device List
- View all discovered devices
- Quick power toggle for each device
- Pull to refresh device list
- Tap eye icon to show/hide offline devices
- Tap a device to open detailed controls

### Device Control
- Toggle power on/off
- Adjust brightness (0-100%)
- Change color with color picker or presets
- Adjust color temperature (2000K-9000K)
- View device capabilities and status

### Settings
- Enable/disable sync transports (CloudKit, Local Network, Bluetooth, App Groups)
- Configure auto-refresh interval
- Show/hide offline devices
- View connection status
- Sync settings across devices

## App Groups & Data Sharing

The app uses App Groups to share device data with the macOS companion app:

- **App Group ID**: `group.com.govee.mac`
- **Storage Keys**:
  - `com.govee.smartlights.devices` - Device list
  - `com.govee.smartlights.groups` - Device groups
  - `com.govee.smartlights.settings` - Synced settings

### Fallback Behavior

If App Groups are not configured:
- The app automatically falls back to `UserDefaults.standard`
- Data is stored locally but won't sync with the macOS app
- A console message will indicate the fallback: `"⚠️ App Groups not available, falling back to UserDefaults.standard"`

## CloudKit Integration

The app includes CloudKit stubs for future cloud sync:

- **Container**: `iCloud.com.govee.smartlights`
- **Current Status**: Stub implementation (saves to local storage)
- **TODO**: Full CloudKit implementation for cross-device sync

To implement real CloudKit sync, see the TODO comments in `CloudSyncManager.swift`.

## Sync Transports

The app supports multiple transport mechanisms:

### 1. App Groups ✅ (Implemented)
- Shares data with macOS app locally
- Instant sync on the same device
- Fallback to UserDefaults if not configured

### 2. CloudKit ⚠️ (Stub)
- Designed for cross-device sync via iCloud
- Currently saves to local storage
- TODO: Implement CKRecord operations

### 3. Local Network ⚠️ (Stub)
- For Bonjour/mDNS device discovery
- TODO: Implement NetService browser

### 4. Bluetooth ⚠️ (Stub)
- For direct BLE device control
- TODO: Implement CoreBluetooth scanning

## Development

### Adding New Features

1. **New Device Type**: Update `GoveeModels.swift` with new capabilities
2. **New Control**: Add methods to `RemoteControlProtocol.swift`
3. **New View**: Create in `Sources/Views/` and add to navigation
4. **New Transport**: Extend `MultiTransportSyncManager.swift`

### Testing

The app includes sample devices for testing:
- Living Room Light (H6159) - Online, supports all features
- Bedroom Strip (H6182) - Online, color and brightness only
- Kitchen Lights (H6159) - Offline

These are created on first launch if no devices exist.

### Debugging

Enable console logging to see detailed sync activity:
- 🚀 App initialization
- ✅ Successful operations
- ⚠️ Warnings and fallbacks
- ❌ Errors
- 📦 Data loading/saving
- ☁️ CloudKit operations

## Known Limitations

- **CloudKit**: Stub implementation, saves locally only
- **Local Network**: Stub implementation, no actual discovery
- **Bluetooth**: Stub implementation, not functional
- **Group Controls**: UI placeholder, partial implementation
- **Device Discovery**: No automatic device discovery yet

## Future Roadmap

- [ ] Full CloudKit sync implementation
- [ ] Bonjour/mDNS local network discovery
- [ ] CoreBluetooth device scanning and control
- [ ] Real-time device state updates
- [ ] Device group control UI
- [ ] Widget support
- [ ] Shortcuts integration
- [ ] Siri support
- [ ] HomeKit integration

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Documentation References

This implementation is designed to match the architecture described in:
- `IOS_BRIDGE_DEVELOPER_GUIDE.md` (if available in macOS repo)
- `IOS_COMPANION_GUIDE.md` (if available in macOS repo)
- `AI_CONTEXT.md` (if available in macOS repo)

## License

[Add your license here]

## Contact

For questions or support, please open an issue on GitHub.

---

**Note**: This is a companion app starter implementation. Many features are stubs designed to be replaced with full implementations. See TODO comments in the code for integration guidance.
