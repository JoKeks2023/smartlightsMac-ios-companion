# SmartLights iOS Companion

iOS remote control app for the SmartLights macOS application.

## Overview

This iOS app is a **remote control** for the macOS SmartLights app. It does NOT directly control Govee devices. Instead, it provides a mobile interface to:
- View device status from the Mac app
- Adjust device settings (power, brightness, color, temperature)
- Create and manage device groups
- Sync via iCloud (CloudKit) or locally (App Groups)

**How it works:**
```
iOS App (UI) → App Groups/CloudKit → macOS App monitors changes → Device Control
```

The macOS app is responsible for device discovery and command execution.

## Features

- 📱 **Remote Control UI**: Control devices managed by the Mac app
- ☁️ **iCloud Sync**: CloudKit sync across all your devices
- 🔄 **Local Sync**: App Groups for instant sync on the same device
- 🎨 **Full Controls**: Power, brightness, RGB color, and color temperature
- 👥 **Device Groups**: Organize and control multiple devices together
- ⚙️ **Settings Management**: Configure sync preferences

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
- Enable/disable iCloud sync (CloudKit)
- Enable/disable local Mac app sync (App Groups)
- Configure display preferences
- View sync status
- Manually trigger sync

## Data Sync Architecture

### App Groups (Local Sync)
Shares data between iOS and macOS apps on the same device:

- **App Group ID**: `group.com.govee.mac`
- **Storage Keys**:
  - `com.govee.smartlights.devices` - Device list and states
  - `com.govee.smartlights.groups` - Device groups
  - `com.govee.smartlights.settings` - Synced settings

**Fallback**: If App Groups unavailable, uses `UserDefaults.standard` (data won't sync with Mac)

### CloudKit (iCloud Sync)
Syncs data across all devices via iCloud:

- **Container**: `iCloud.com.govee.smartlights`
- **Status**: Fully implemented with real CKRecord operations
- **Features**:
  - Cross-device sync (iPhone, iPad, Mac)
  - Automatic conflict resolution
  - Graceful fallback to local storage on errors

### How Sync Works

1. **iOS → Mac (same device)**: Instant via App Groups
2. **iOS → Mac (different devices)**: Via CloudKit (seconds)
3. **Mac monitors changes**: Executes device commands
4. **Mac updates state**: iOS reads latest via App Groups/CloudKit

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

## Important Notes

- **Remote Control Only**: This iOS app does NOT directly control devices. It's a remote for the macOS app.
- **Mac App Required**: You need the macOS SmartLights app installed to control actual devices.
- **Device Discovery**: The Mac app handles device discovery and management.
- **Command Execution**: The Mac app monitors changes and executes device commands.

## Future Roadmap

- [ ] Real-time state updates (push notifications from Mac app)
- [ ] Device group control UI enhancements
- [ ] Widget support for quick controls
- [ ] Shortcuts integration
- [ ] Siri support
- [ ] HomeKit bridge (via Mac app)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Integration with macOS App

The macOS SmartLights app should:

1. **Monitor App Groups**: Watch for changes to the shared container
2. **Monitor CloudKit**: Subscribe to CloudKit notifications
3. **Execute Commands**: When iOS makes changes, execute device commands
4. **Update State**: Write latest device states back to shared storage
5. **Device Discovery**: Handle all device discovery and management

The iOS app reads device states and writes desired states. The Mac app is the bridge to actual devices.

## License

[Add your license here]

## Contact

For questions or support, please open an issue on GitHub.

---

**Architecture**: iOS app is a remote control → Mac app executes commands → Sync via App Groups & CloudKit
