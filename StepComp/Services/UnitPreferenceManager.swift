//
//  UnitPreferenceManager.swift
//  FitComp
//
//  Centralized unit preference management for the entire app
//

import Foundation
import Combine

enum UnitSystem: String, Codable {
    case metric
    case imperial
    
    var distanceLabel: String {
        switch self {
        case .metric: return "Km"
        case .imperial: return "Mi"
        }
    }
    
    var heightLabel: String {
        switch self {
        case .metric: return "CM"
        case .imperial: return "FT"
        }
    }
    
    var weightLabel: String {
        switch self {
        case .metric: return "KG"
        case .imperial: return "LBS"
        }
    }

    var distanceDisplayName: String {
        switch self {
        case .metric: return "Metric (kg, km, cm)"
        case .imperial: return "Imperial (lbs, miles, inches)"
        }
    }
}

final class UnitPreferenceManager: ObservableObject {
    static let shared = UnitPreferenceManager()
    
    @Published var unitSystem: UnitSystem {
        didSet {
            savePreference()
        }
    }
    
    private let userDefaultsKey = "unitSystem"
    
    private init() {
        // Load from UserDefaults
        if let savedUnit = UserDefaults.standard.string(forKey: userDefaultsKey),
           let system = UnitSystem(rawValue: savedUnit) {
            self.unitSystem = system
        } else {
            // Default to imperial (lbs)
            self.unitSystem = .imperial
        }
    }
    
    private func savePreference() {
        UserDefaults.standard.set(unitSystem.rawValue, forKey: userDefaultsKey)
        print("💾 Unit system saved: \(unitSystem.rawValue)")
    }
    
    // MARK: - Distance Conversions
    
    /// Convert kilometers to the user's preferred unit
    func convertDistance(km: Double) -> Double {
        switch unitSystem {
        case .metric:
            return km
        case .imperial:
            return km * 0.621371 // km to miles
        }
    }
    
    /// Format distance with the appropriate unit label
    func formatDistance(_ km: Double, decimals: Int = 1) -> String {
        let value = convertDistance(km: km)
        return String(format: "%.\(decimals)f", value)
    }
    
    /// Get the distance unit label
    var distanceUnit: String {
        unitSystem.distanceLabel
    }
    
    // MARK: - Height Conversions
    
    /// Convert centimeters to the user's preferred unit
    func convertHeight(cm: Double) -> Double {
        switch unitSystem {
        case .metric:
            return cm
        case .imperial:
            return cm / 2.54 // cm to inches
        }
    }
    
    /// Format height with the appropriate unit
    func formatHeight(_ cm: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.0f cm", cm)
        case .imperial:
            let totalInches = cm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\""
        }
    }

    func heightComponents(fromCm cm: Int) -> (feet: Int, inches: Int) {
        let totalInches = Double(cm) / 2.54
        return (
            feet: Int(totalInches / 12),
            inches: Int(totalInches.truncatingRemainder(dividingBy: 12).rounded())
        )
    }

    func heightToStorage(feet: Int, inches: Int) -> Int {
        let totalInches = Double((feet * 12) + inches)
        return Int((totalInches * 2.54).rounded())
    }
    
    // MARK: - Weight Conversions
    
    /// Convert kilograms to the user's preferred unit
    func convertWeight(kg: Double) -> Double {
        switch unitSystem {
        case .metric:
            return kg
        case .imperial:
            return kg * 2.20462 // kg to lbs
        }
    }
    
    /// Format weight with the appropriate unit label
    func formatWeight(_ kg: Double, decimals: Int = 1) -> String {
        let value = convertWeight(kg: kg)
        return String(format: "%.\(decimals)f", value)
    }
    
    /// Get the weight unit label
    var weightUnit: String {
        unitSystem.weightLabel
    }

    func weightToStorage(_ displayWeight: Int) -> Int {
        switch unitSystem {
        case .metric:
            return displayWeight
        case .imperial:
            return Int((Double(displayWeight) / 2.20462).rounded())
        }
    }

    func weightFromStorage(_ storageWeight: Int) -> Int {
        switch unitSystem {
        case .metric:
            return storageWeight
        case .imperial:
            return Int((Double(storageWeight) * 2.20462).rounded())
        }
    }
    
    // MARK: - Pace Conversions
    
    /// Convert pace from min/km to the user's preferred unit
    func convertPace(minPerKm: Double) -> Double {
        switch unitSystem {
        case .metric:
            return minPerKm
        case .imperial:
            return minPerKm * 1.60934
        }
    }
    
    /// Format pace with the appropriate unit label
    func formatPace(_ minPerKm: Double) -> String {
        let value = convertPace(minPerKm: minPerKm)
        return String(format: "%.2f %@", value, paceUnit)
    }
    
    /// Get the pace unit label
    var paceUnit: String {
        switch unitSystem {
        case .metric: return "min/km"
        case .imperial: return "min/mi"
        }
    }
    
    // MARK: - Waist Measurement Conversions
    
    var waistLabel: String {
        switch unitSystem {
        case .metric: return "cm"
        case .imperial: return "in"
        }
    }
    
    func convertWaist(cm: Double) -> Double {
        switch unitSystem {
        case .metric: return cm
        case .imperial: return cm / 2.54
        }
    }
    
    func convertWaistToStorage(_ displayValue: Double) -> Double {
        switch unitSystem {
        case .metric: return displayValue
        case .imperial: return displayValue * 2.54
        }
    }
    
    // MARK: - Workout Weight Storage Conversions
    
    /// Convert weight from user's display unit to storage unit (kg)
    /// Use this when saving workout weights entered by the user
    func convertWeightToStorage(_ displayWeight: Double) -> Double {
        switch unitSystem {
        case .metric:
            return displayWeight // Already in kg
        case .imperial:
            return displayWeight / 2.20462 // Convert lbs to kg for storage
        }
    }
    
    /// Convert weight from storage unit (kg) to user's display unit
    /// Use this when displaying workout weights to the user
    func convertWeightFromStorage(_ storageWeight: Double) -> Double {
        switch unitSystem {
        case .metric:
            return storageWeight // Display as kg
        case .imperial:
            return storageWeight * 2.20462 // Convert kg to lbs for display
        }
    }
}

