//
//  DeviceColor+Extensions.swift
//  SmartLights iOS Companion
//
//  Color conversion utilities between DeviceColor and SwiftUI/UIKit color types.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - DeviceColor to SwiftUI Color

extension DeviceColor {
    /// Convert DeviceColor to SwiftUI Color
    public var swiftUIColor: Color {
        if let kelvin = kelvin {
            // Convert Kelvin to approximate RGB for display
            return Color(kelvinToUIColor(kelvin))
        } else {
            return Color(
                red: Double(red) / 255.0,
                green: Double(green) / 255.0,
                blue: Double(blue) / 255.0
            )
        }
    }
    
    /// Convert DeviceColor to UIColor
    public var uiColor: UIColor {
        if let kelvin = kelvin {
            return kelvinToUIColor(kelvin)
        } else {
            return UIColor(
                red: CGFloat(red) / 255.0,
                green: CGFloat(green) / 255.0,
                blue: CGFloat(blue) / 255.0,
                alpha: 1.0
            )
        }
    }
    
    /// Convert Kelvin color temperature to approximate UIColor
    private func kelvinToUIColor(_ kelvin: Int) -> UIColor {
        // Simplified Kelvin to RGB conversion
        // Based on Tanner Helland's algorithm
        let temp = Double(kelvin) / 100.0
        
        var red: Double
        var green: Double
        var blue: Double
        
        // Calculate red
        if temp <= 66 {
            red = 255
        } else {
            red = temp - 60
            red = 329.698727446 * pow(red, -0.1332047592)
            red = max(0, min(255, red))
        }
        
        // Calculate green
        if temp <= 66 {
            green = temp
            green = 99.4708025861 * log(green) - 161.1195681661
        } else {
            green = temp - 60
            green = 288.1221695283 * pow(green, -0.0755148492)
        }
        green = max(0, min(255, green))
        
        // Calculate blue
        if temp >= 66 {
            blue = 255
        } else if temp <= 19 {
            blue = 0
        } else {
            blue = temp - 10
            blue = 138.5177312231 * log(blue) - 305.0447927307
            blue = max(0, min(255, blue))
        }
        
        return UIColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - SwiftUI Color to DeviceColor

extension Color {
    /// Convert SwiftUI Color to DeviceColor (RGB only)
    public func toDeviceColor() -> DeviceColor {
        let uiColor = UIColor(self)
        return uiColor.toDeviceColor()
    }
}

// MARK: - UIColor to DeviceColor

extension UIColor {
    /// Convert UIColor to DeviceColor (RGB only)
    public func toDeviceColor() -> DeviceColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return DeviceColor(
            red: Int(red * 255),
            green: Int(green * 255),
            blue: Int(blue * 255)
        )
    }
}

// MARK: - Helper Views for Color Temperature

/// A view that displays a color temperature slider with visual feedback
public struct ColorTemperatureSlider: View {
    @Binding var kelvin: Int
    let range: ClosedRange<Int> = 2000...9000
    
    public init(kelvin: Binding<Int>) {
        self._kelvin = kelvin
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Color Temperature")
                    .font(.subheadline)
                Spacer()
                Text("\(kelvin)K")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Slider(
                value: Binding(
                    get: { Double(kelvin) },
                    set: { kelvin = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 100
            )
            
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
    }
}

// MARK: - Debounced Value Holder

/// A property wrapper for debouncing value changes.
/// Useful for optimistic UI updates without overwhelming the backend.
@propertyWrapper
public struct Debounced<Value> {
    private var value: Value
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            workItem?.cancel()
            
            let newWorkItem = DispatchWorkItem { [value = newValue] in
                // Trigger update after delay
                self.projectedValue?(value)
            }
            workItem = newWorkItem
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
        }
    }
    
    public var projectedValue: ((Value) -> Void)?
    
    public init(wrappedValue: Value, delay: TimeInterval = 0.5) {
        self.value = wrappedValue
        self.delay = delay
    }
}

// MARK: - Color Picker Extensions

extension Color {
    /// Predefined Govee-style color presets
    public static var goveePresets: [Color] {
        [
            .red,
            .orange,
            .yellow,
            .green,
            .blue,
            .indigo,
            .purple,
            .pink,
            .white
        ]
    }
}
