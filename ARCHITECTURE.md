# SmartLights iOS Companion - Architecture Documentation

## Overview

The SmartLights iOS Companion is a SwiftUI-based application that provides remote control capabilities for Govee smart light devices. It's designed to sync with a macOS companion app and support multiple transport mechanisms for device discovery and control.

## Architecture Principles

1. **Separation of Concerns**: Models, Views, Services, and Stores are clearly separated
2. **Protocol-Oriented**: Services use protocols for testability and future extensibility
3. **Observable Objects**: State management using Combine and SwiftUI's property wrappers
4. **Async/Await**: Modern Swift concurrency for network operations
5. **Graceful Degradation**: Fallbacks when capabilities (App Groups, CloudKit) aren't available

## Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Views Layer                          │
│  (SwiftUI Views, UI Components, User Interactions)         │
│                                                             │
│  • MainTabView                                              │
│  • DeviceListView, DeviceControlView                        │
│  • SettingsView, ConnectionStatusView                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     Store Layer                             │
│        (Observable State, Business Logic)                   │
│                                                             │
│  • DeviceStore (ObservableObject)                           │
│    - Manages in-memory device/group collections             │
│    - Provides computed properties and helpers               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Services Layer                            │
│     (Network, Sync, Persistence, Control)                   │
│                                                             │
│  • RemoteControlClient                                      │
│    - Device control API                                     │
│    - Group management                                       │
│    - Settings management                                    │
│                                                             │
│  • MultiTransportSyncManager (UnifiedSyncManager)           │
│    - Coordinates all transports                             │
│    - Facade for sync operations                             │
│                                                             │
│  • CloudSyncManager                                         │
│    - App Groups persistence                                 │
│    - CloudKit sync (stub)                                   │
│    - UserDefaults fallback                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     Models Layer                            │
│          (Data Structures, Codable Types)                   │
│                                                             │
│  • GoveeDevice                                              │
│  • DeviceGroup                                              │
│  • DeviceColor                                              │
│  • SyncedSettings                                           │
│  • SyncError                                                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Utilities Layer                           │
│        (Extensions, Helpers, Conversions)                   │
│                                                             │
│  • DeviceColor+Extensions                                   │
│    - UIColor/Color conversions                              │
│    - Kelvin to RGB conversion                               │
│    - Color presets                                          │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Models (Data Layer)

**GoveeDevice**
- Represents a physical smart light device
- Codable for persistence
- Identifiable for SwiftUI Lists
- Tracks state: power, brightness, color, online status

**DeviceGroup**
- Logical grouping of devices
- Allows batch operations
- References devices by ID

**DeviceColor**
- RGB color representation (0-255 per channel)
- Optional Kelvin color temperature (2000-9000K)
- Converts to/from SwiftUI Color and UIColor

**SyncedSettings**
- App-wide preferences
- Syncs across devices via CloudKit
- Controls which transports are enabled

**SyncError**
- Typed errors for sync operations
- Localized error descriptions

### 2. Store (State Management)

**DeviceStore**
- Single source of truth for devices and groups
- `@Published` properties trigger UI updates
- Provides convenience methods:
  - `upsertDevice()`, `removeDevice()`
  - `updateDevicePower()`, `updateDeviceBrightness()`, etc.
  - `upsertGroup()`, `removeGroup()`
  - `devices(inGroup:)` for filtering

### 3. Services (Business Logic)

**RemoteControlClient**
- High-level API for device control
- Validates inputs before operations
- Updates DeviceStore
- Persists changes via MultiTransportSyncManager
- Methods:
  - `setDevicePower(deviceId:powerState:)`
  - `setDeviceBrightness(deviceId:brightness:)`
  - `setDeviceColor(deviceId:color:)`
  - `createGroup(name:deviceIds:)`
  - `refreshDevices()`
  - `getSettings()`, `updateSettings()`

**MultiTransportSyncManager**
- Facade coordinating multiple sync transports
- Published connection states:
  - `isConnectedViaCloud`
  - `isConnectedViaLocalNetwork`
  - `isConnectedViaBluetooth`
- Transport control:
  - `enableTransport(_:)`, `disableTransport(_:)`
- Sync operations:
  - `syncNow()` - manual sync trigger
  - `saveDevices(_:)`, `saveGroups(_:)`

**CloudSyncManager**
- Persistence layer
- App Groups support with UserDefaults fallback
- CloudKit stubs for future implementation
- Methods:
  - `loadDevicesFromAppGroups()`, `saveDevicesToAppGroups()`
  - `loadGroupsFromAppGroups()`, `saveGroupsFromAppGroups()`
  - `loadSettings()`, `saveSettings()`
  - `fetchDevicesFromCloud()` (stub)
  - `checkCloudKitStatus()`

### 4. Views (Presentation Layer)

**MainTabView**
- TabView with three tabs
- Provides navigation structure
- Injects environment objects

**DeviceListView**
- Displays all devices in a List
- Quick power toggle per device
- Filter online/offline
- Pull to refresh
- Connection status indicator

**DeviceControlView**
- Detailed control for single device
- Power toggle
- Brightness slider (with debouncing)
- Color picker with presets
- Color temperature slider
- Shows device info and capabilities

**SettingsView**
- Enable/disable transports
- Display options (show offline, auto-refresh)
- View configuration (App Group ID, CloudKit container)
- Connection status
- Sync now button

**ConnectionStatusView**
- Compact status indicator
- Shows active transports with icons
- DetailedConnectionStatusView for expanded view

### 5. Utilities

**DeviceColor+Extensions**
- `DeviceColor.swiftUIColor` - Convert to SwiftUI Color
- `DeviceColor.uiColor` - Convert to UIColor
- `Color.toDeviceColor()` - Convert from SwiftUI Color
- `UIColor.toDeviceColor()` - Convert from UIColor
- Kelvin to RGB conversion algorithm
- `ColorTemperatureSlider` - Reusable slider component
- `Color.goveePresets` - Predefined color array

## Data Flow

### Device Control Flow

```
User Interaction (View)
        ↓
DeviceControlView updates local state
        ↓
Calls RemoteControlClient method
        ↓
RemoteControlClient validates input
        ↓
Updates DeviceStore (UI updates automatically)
        ↓
Calls MultiTransportSyncManager.saveDevices()
        ↓
CloudSyncManager saves to App Groups/UserDefaults
        ↓
(Future) CloudKit sync in background
```

### Sync Flow

```
App Launch
        ↓
SmartLightsIOSApp.initializeApp()
        ↓
MultiTransportSyncManager.enableTransport(.appGroups)
        ↓
CloudSyncManager.loadDevicesFromAppGroups()
        ↓
DeviceStore.replaceAllDevices()
        ↓
Views observe DeviceStore and update
```

### Settings Update Flow

```
User changes setting in SettingsView
        ↓
Local @State binding updates
        ↓
User taps "Save"
        ↓
RemoteControlClient.updateSettings()
        ↓
CloudSyncManager.saveSettings()
        ↓
MultiTransportSyncManager enables/disables transports
```

## Transport Mechanisms

### 1. App Groups (Implemented) ✅
- **Purpose**: Share data with macOS app locally
- **Status**: Fully functional with UserDefaults fallback
- **Storage**:
  - `com.govee.smartlights.devices` (JSON array)
  - `com.govee.smartlights.groups` (JSON array)
  - `com.govee.smartlights.settings` (JSON object)
- **Fallback**: UserDefaults.standard if App Groups unavailable

### 2. CloudKit (Stub) ⚠️
- **Purpose**: Cross-device sync via iCloud
- **Status**: Stub implementation, saves locally
- **Container**: `iCloud.com.govee.smartlights`
- **TODO**: Implement CKRecord queries and saves

### 3. Local Network (Stub) ⚠️
- **Purpose**: Discover devices via Bonjour/mDNS
- **Status**: Stub, no actual discovery
- **Service**: `_smartlights._tcp`
- **TODO**: Implement NetServiceBrowser

### 4. Bluetooth (Stub) ⚠️
- **Purpose**: Direct BLE control
- **Status**: Stub, not functional
- **TODO**: Implement CoreBluetooth CBCentralManager

## Persistence Strategy

### Local Persistence
1. **Primary**: App Groups container (if available)
2. **Fallback**: UserDefaults.standard
3. **Format**: JSON encoded with ISO8601 dates
4. **Keys**: Namespaced with `com.govee.smartlights.*`

### Sync Strategy
1. **Read on launch**: Load from App Groups
2. **Write on change**: Save immediately after device updates
3. **Optimistic UI**: Update UI first, persist in background
4. **Debouncing**: Slider changes debounced (0.3-0.5s)

## Concurrency & Performance

### Swift Concurrency
- All sync operations are `async` functions
- UI updates on `@MainActor`
- Network calls run on background threads

### Debouncing
- Brightness slider: 0.3s debounce
- Color picker: 0.5s debounce
- Temperature slider: 0.3s debounce

### Optimistic Updates
- UI updates immediately
- Persistence happens in background
- Errors revert UI state

## Error Handling

### Error Types
- `SyncError.appGroupsNotAvailable`
- `SyncError.cloudKitNotAvailable`
- `SyncError.networkError(Error)`
- `SyncError.deviceNotFound(String)`
- `SyncError.invalidInput(String)`

### Error Strategy
1. Validate inputs before operations
2. Throw typed errors with descriptions
3. Log errors to console
4. Show user-friendly alerts (TODO in views)
5. Graceful degradation (fallbacks)

## Testing Strategy

### Unit Tests
- Model Codable roundtrip tests
- DeviceStore operations
- CloudSyncManager persistence
- Input validation

### Integration Tests
- Full sync cycle
- Transport switching
- Settings persistence

### UI Tests
- Device list display
- Control interactions
- Settings changes

## Security Considerations

### Data Protection
- Device credentials (if any) should use Keychain
- App Groups data is sandboxed
- CloudKit uses Apple ID authentication

### Privacy
- Local Network usage description in Info.plist
- Bluetooth usage description in Info.plist
- No analytics or tracking

## Future Enhancements

### Short Term
- [ ] Complete CloudKit implementation
- [ ] Implement Local Network discovery
- [ ] Add error alerts in UI
- [ ] Add device group controls

### Medium Term
- [ ] Bluetooth device scanning
- [ ] Real-time device state updates
- [ ] Widget support
- [ ] Shortcuts integration

### Long Term
- [ ] HomeKit integration
- [ ] Siri support
- [ ] Device scenes/automations
- [ ] Multi-room audio sync

## Dependencies

### System Frameworks
- SwiftUI - UI framework
- Combine - Reactive programming
- Foundation - Core utilities
- CloudKit - Cloud sync (stub)
- CoreBluetooth - BLE (TODO)
- Network - Bonjour (TODO)

### Third-Party
- None (currently)

## Performance Metrics

### App Size
- Estimated: < 5 MB (without assets)

### Memory Usage
- Typical: < 50 MB
- Peak: < 100 MB (with many devices)

### Startup Time
- Cold launch: < 2s
- Warm launch: < 1s

### Data Size
- Device: ~500 bytes each
- Group: ~200 bytes each
- Settings: ~300 bytes

## Debugging Tips

### Console Logging
- Look for emoji prefixes:
  - 🚀 Initialization
  - ✅ Success
  - ⚠️ Warning
  - ❌ Error
  - 📦 Data operation
  - ☁️ CloudKit
  - 🔧 Configuration

### Common Issues
1. **App Groups not working**: Check entitlements
2. **CloudKit fails**: Check iCloud sign-in
3. **Devices don't persist**: Check console for fallback message
4. **UI doesn't update**: Check @Published properties

### Xcode Instruments
- Use Time Profiler for performance
- Use Allocations for memory leaks
- Use Network for API debugging

---

This architecture is designed to be:
- **Maintainable**: Clear separation of concerns
- **Testable**: Protocol-based services
- **Extensible**: Easy to add new transports/features
- **Performant**: Efficient state management
- **Robust**: Graceful degradation and error handling
