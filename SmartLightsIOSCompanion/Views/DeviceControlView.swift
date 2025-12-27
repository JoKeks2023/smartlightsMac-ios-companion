//
//  DeviceControlView.swift
//  SmartLights iOS Companion
//
//  Detailed control view for an individual device with power, brightness, color controls.
//

import SwiftUI

struct DeviceControlView: View {
    let device: GoveeDevice
    
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var remoteControlClient: RemoteControlClient
    
    @State private var powerState: Bool
    @State private var brightness: Double
    @State private var selectedColor: Color
    @State private var colorTemperature: Int
    @State private var isUpdating = false
    
    // Debounce timers
    @State private var brightnessTimer: Timer?
    @State private var colorTimer: Timer?
    @State private var temperatureTimer: Timer?
    
    init(device: GoveeDevice) {
        self.device = device
        _powerState = State(initialValue: device.powerState)
        _brightness = State(initialValue: Double(device.brightness))
        _selectedColor = State(initialValue: device.color.swiftUIColor)
        _colorTemperature = State(initialValue: device.color.kelvin ?? 3000)
    }
    
    var body: some View {
        List {
            // Device Info Section
            Section {
                HStack {
                    Text("Model")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(device.model)
                }
                
                HStack {
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: device.isOnline ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(device.isOnline ? "Online" : "Offline")
                    }
                    .foregroundColor(device.isOnline ? .green : .red)
                }
                
                HStack {
                    Text("Last Seen")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(device.lastSeen, style: .relative)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Device Information")
            }
            
            // Power Control Section
            Section {
                Toggle(isOn: $powerState) {
                    HStack {
                        Image(systemName: powerState ? "power" : "power")
                            .foregroundColor(powerState ? .green : .secondary)
                        Text("Power")
                    }
                }
                .onChange(of: powerState) { newValue in
                    updatePowerState(newValue)
                }
                .disabled(!device.isOnline)
            } header: {
                Text("Power")
            }
            
            // Brightness Control Section
            if device.supports("brightness") {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.yellow)
                            Text("Brightness")
                            Spacer()
                            Text("\(Int(brightness))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $brightness, in: 0...100, step: 1)
                            .onChange(of: brightness) { newValue in
                                debouncedBrightnessUpdate(Int(newValue))
                            }
                            .disabled(!device.isOnline || !powerState)
                    }
                } header: {
                    Text("Brightness")
                }
            }
            
            // Color Control Section
            if device.supports("color") {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(selectedColor)
                            Text("Color")
                        }
                        
                        ColorPicker("Select Color", selection: $selectedColor)
                            .onChange(of: selectedColor) { newValue in
                                debouncedColorUpdate(newValue)
                            }
                            .disabled(!device.isOnline || !powerState)
                        
                        // Color presets
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Color.goveePresets, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedColor.description == color.description ? Color.blue : Color.clear,
                                                    lineWidth: 3
                                                )
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                            debouncedColorUpdate(color)
                                        }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Color")
                }
            }
            
            // Color Temperature Section
            if device.supports("colorTemperature") {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "thermometer")
                                .foregroundColor(.orange)
                            Text("Color Temperature")
                            Spacer()
                            Text("\(colorTemperature)K")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(colorTemperature) },
                            set: { colorTemperature = Int($0) }
                        ), in: 2000...9000, step: 100)
                        .onChange(of: colorTemperature) { newValue in
                            debouncedTemperatureUpdate(newValue)
                        }
                        .disabled(!device.isOnline || !powerState)
                        
                        HStack {
                            Text("Warm")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Spacer()
                            Text("Cool")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Color Temperature")
                }
            }
            
            // Capabilities Section
            Section {
                ForEach(device.capabilities, id: \.self) { capability in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(capability.capitalized)
                    }
                }
            } header: {
                Text("Capabilities")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            Group {
                if isUpdating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        )
        .onAppear {
            syncStateWithDevice()
        }
    }
    
    // MARK: - Update Methods
    
    private func syncStateWithDevice() {
        if let currentDevice = deviceStore.device(withId: device.id) {
            powerState = currentDevice.powerState
            brightness = Double(currentDevice.brightness)
            selectedColor = currentDevice.color.swiftUIColor
            colorTemperature = currentDevice.color.kelvin ?? 3000
        }
    }
    
    private func updatePowerState(_ newValue: Bool) {
        Task {
            isUpdating = true
            do {
                try await remoteControlClient.setDevicePower(
                    deviceId: device.id,
                    powerState: newValue
                )
            } catch {
                print("❌ Failed to update power: \(error)")
                // Revert on error
                powerState = device.powerState
            }
            isUpdating = false
        }
    }
    
    private func debouncedBrightnessUpdate(_ newValue: Int) {
        brightnessTimer?.invalidate()
        brightnessTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            Task {
                do {
                    try await remoteControlClient.setDeviceBrightness(
                        deviceId: device.id,
                        brightness: newValue
                    )
                    print("✅ Brightness updated to \(newValue)%")
                } catch {
                    print("❌ Failed to update brightness: \(error)")
                }
            }
        }
    }
    
    private func debouncedColorUpdate(_ newValue: Color) {
        colorTimer?.invalidate()
        colorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task {
                do {
                    let deviceColor = newValue.toDeviceColor()
                    try await remoteControlClient.setDeviceColor(
                        deviceId: device.id,
                        color: deviceColor
                    )
                    print("✅ Color updated")
                } catch {
                    print("❌ Failed to update color: \(error)")
                }
            }
        }
    }
    
    private func debouncedTemperatureUpdate(_ newValue: Int) {
        temperatureTimer?.invalidate()
        temperatureTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            Task {
                do {
                    try await remoteControlClient.setDeviceColorTemperature(
                        deviceId: device.id,
                        kelvin: newValue
                    )
                    print("✅ Temperature updated to \(newValue)K")
                } catch {
                    print("❌ Failed to update temperature: \(error)")
                }
            }
        }
    }
}

// MARK: - Preview

struct DeviceControlView_Previews: PreviewProvider {
    static var previews: some View {
        let device = GoveeDevice(
            id: "test1",
            name: "Living Room Light",
            model: "H6159",
            isOnline: true,
            powerState: true,
            brightness: 75,
            color: DeviceColor(red: 255, green: 150, blue: 50),
            capabilities: ["color", "brightness", "colorTemperature"]
        )
        
        let store = DeviceStore(devices: [device])
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
            DeviceControlView(device: device)
                .environmentObject(store)
                .environmentObject(remoteClient)
        }
    }
}
