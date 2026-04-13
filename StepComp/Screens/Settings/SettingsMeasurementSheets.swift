//
//  SettingsMeasurementSheets.swift
//  FitComp
//
//  Height/weight editor and wheel pickers extracted from SettingsView.swift.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Edit Height Weight Sheet

struct EditHeightWeightSheet: View {
    let user: User
    let onSave: (Int?, Int?) -> Void
    
    @State private var selectedFeet: Int = 5
    @State private var selectedInches: Int = 9
    @State private var selectedWeight: Int = 150
    @State private var heightUnit: HeightUnit = .imperial
    @State private var weightUnit: WeightUnit = .imperial
    @State private var isLoadingHealthKit = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthKitService: HealthKitService
    @ObservedObject private var unitManager = UnitPreferenceManager.shared
    
    enum HeightUnit {
        case imperial // ft/in
        case metric   // cm
    }
    
    enum WeightUnit {
        case imperial // lbs
        case metric   // kg
    }
    
    // Convert cm to feet/inches
    private func cmToImperial(_ cm: Int) -> (feet: Int, inches: Int) {
        unitManager.heightComponents(fromCm: cm)
    }
    
    // Convert feet/inches to cm
    private func imperialToCm(feet: Int, inches: Int) -> Int {
        unitManager.heightToStorage(feet: feet, inches: inches)
    }
    
    // Convert kg to lbs
    private func kgToLbs(_ kg: Int) -> Int {
        unitManager.weightFromStorage(kg)
    }
    
    // Convert lbs to kg
    private func lbsToKg(_ lbs: Int) -> Int {
        unitManager.weightToStorage(lbs)
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("Measurements")
                        .font(.system(size: 18, weight: .heavy))
                    
                    Spacer()
                    
                    Button("Save") {
                        saveData()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .fontWeight(.bold)
                    .clipShape(Capsule())
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Subtitle
                        Text("UPDATE YOUR STATS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .tracking(2)
                        
                        // Height Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Height")
                                    .font(.system(size: 20, weight: .heavy))
                                
                                Spacer()
                                
                                // Unit Toggle
                                HStack(spacing: 0) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            heightUnit = .imperial
                                        }
                                    } label: {
                                        Text("FT")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(heightUnit == .imperial ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(heightUnit == .imperial ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            heightUnit = .metric
                                        }
                                    } label: {
                                        Text("CM")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(heightUnit == .metric ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(heightUnit == .metric ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(4)
                                .background(FitCompColors.cardBorder)
                                .clipShape(Capsule())
                            }
                            
                            // Height Picker
                            if heightUnit == .imperial {
                                HeightPickerImperial(selectedFeet: $selectedFeet, selectedInches: $selectedInches)
                            } else {
                                HeightPickerMetric(selectedCm: Binding(
                                    get: { imperialToCm(feet: selectedFeet, inches: selectedInches) },
                                    set: { cm in
                                        let (feet, inches) = cmToImperial(cm)
                                        selectedFeet = feet
                                        selectedInches = inches
                                    }
                                ))
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                        
                        // Weight Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Weight")
                                    .font(.system(size: 20, weight: .heavy))
                                
                                Spacer()
                                
                                // Unit Toggle
                                HStack(spacing: 0) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            weightUnit = .imperial
                                        }
                                    } label: {
                                        Text("LBS")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(weightUnit == .imperial ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(weightUnit == .imperial ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            weightUnit = .metric
                                        }
                                    } label: {
                                        Text("KG")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(weightUnit == .metric ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(weightUnit == .metric ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(4)
                                .background(FitCompColors.cardBorder)
                                .clipShape(Capsule())
                            }
                            
                            // Weight Picker
                            if weightUnit == .imperial {
                                WeightPickerImperial(selectedWeight: $selectedWeight)
                            } else {
                                WeightPickerMetric(selectedWeight: Binding(
                                    get: { lbsToKg(selectedWeight) },
                                    set: { kg in selectedWeight = kgToLbs(kg) }
                                ))
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                        
                        // Footer Text
                        Text("These values are used for calculating calories burned and other health metrics accurately. Your data is private.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 16)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadSavedData()
            
            // Try to load from HealthKit if no saved data
            let height = UserDefaults.standard.integer(forKey: "userHeight")
            let weight = UserDefaults.standard.integer(forKey: "userWeight")
            if height == 0 || weight == 0 {
                Task {
                    await loadFromHealthKit()
                }
            }
        }
    }
    
    private func loadSavedData() {
        let heightCm = UserDefaults.standard.integer(forKey: "userHeight")
        let weightKg = UserDefaults.standard.integer(forKey: "userWeight")
        
        if heightCm > 0 {
            let (feet, inches) = cmToImperial(heightCm)
            selectedFeet = feet
            selectedInches = inches
        }
        
        if weightKg > 0 {
            selectedWeight = kgToLbs(weightKg)
        }
    }
    
    private func loadFromHealthKit() async {
        isLoadingHealthKit = true
        defer { isLoadingHealthKit = false }
        
        do {
            if let heightCm = try await healthKitService.getHeight() {
                let (feet, inches) = cmToImperial(Int(heightCm))
                selectedFeet = feet
                selectedInches = inches
            }
            
            if let weightKg = try await healthKitService.getWeight() {
                selectedWeight = kgToLbs(Int(weightKg))
            }
        } catch {
            print("⚠️ Failed to load from HealthKit: \(error)")
        }
    }
    
    private func saveData() {
        let heightCm = imperialToCm(feet: selectedFeet, inches: selectedInches)
        let weightKg = lbsToKg(selectedWeight)
        
        onSave(heightCm, weightKg)
        dismiss()
    }
}

// MARK: - Height Picker (Imperial - Feet/Inches)

struct HeightPickerImperial: View {
    @Binding var selectedFeet: Int
    @Binding var selectedInches: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Highlight Rectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow)
                    .frame(width: geometry.size.width - 32, height: 56)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                HStack(spacing: 0) {
                    // Feet Picker
                    VStack(spacing: 4) {
                        Picker("Feet", selection: $selectedFeet) {
                            ForEach(3...8, id: \.self) { foot in
                                Text("\(foot)")
                                    .font(.system(size: 32, weight: .black))
                                    .tag(foot)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: geometry.size.width / 2 - 16, height: 192)
                        .compositingGroup()
                        .clipped()
                        
                        Text("ft")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.gray)
                    }
                    
                    // Inches Picker
                    VStack(spacing: 4) {
                        Picker("Inches", selection: $selectedInches) {
                            ForEach(0...11, id: \.self) { inch in
                                Text("\(inch)")
                                    .font(.system(size: 32, weight: .black))
                                    .tag(inch)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: geometry.size.width / 2 - 16, height: 192)
                        .compositingGroup()
                        .clipped()
                        
                        Text("in")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: geometry.size.width, height: 192)
            }
        }
        .frame(height: 240)
    }
}

// MARK: - Height Picker (Metric - CM)

struct HeightPickerMetric: View {
    @Binding var selectedCm: Int
    
    var body: some View {
        ZStack {
            // Highlight Rectangle
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow)
                .frame(height: 56)
                .padding(.horizontal, 16)
            
            HStack {
                Picker("Height", selection: $selectedCm) {
                    ForEach(120...220, id: \.self) { cm in
                        Text("\(cm)")
                            .font(.system(size: selectedCm == cm ? 32 : 24, weight: selectedCm == cm ? .black : .bold))
                            .foregroundColor(selectedCm == cm ? .black : .gray.opacity(0.3))
                            .tag(cm)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 120, height: 192)
                .clipped()
                
                Text("cm")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.gray)
                    .offset(x: -20)
            }
        }
        .frame(height: 192)
    }
}

// MARK: - Weight Picker (Imperial - LBS)

struct WeightPickerImperial: View {
    @Binding var selectedWeight: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Highlight Rectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow)
                    .frame(width: geometry.size.width - 32, height: 56)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                HStack(spacing: 8) {
                    Picker("Weight", selection: $selectedWeight) {
                        ForEach(80...400, id: \.self) { lbs in
                            Text("\(lbs)")
                                .font(.system(size: 32, weight: .black))
                                .tag(lbs)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: geometry.size.width - 80, height: 192)
                    .compositingGroup()
                    .clipped()
                    
                    Text("lbs")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                }
                .frame(width: geometry.size.width, height: 192)
            }
        }
        .frame(height: 240)
    }
}

// MARK: - Weight Picker (Metric - KG)

struct WeightPickerMetric: View {
    @Binding var selectedWeight: Int
    
    var body: some View {
        ZStack {
            // Highlight Rectangle
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow)
                .frame(height: 56)
                .padding(.horizontal, 16)
            
            HStack {
                Picker("Weight", selection: $selectedWeight) {
                    ForEach(35...180, id: \.self) { kg in
                        Text("\(kg)")
                            .font(.system(size: selectedWeight == kg ? 32 : 24, weight: selectedWeight == kg ? .black : .bold))
                            .foregroundColor(selectedWeight == kg ? .black : .gray.opacity(0.3))
                            .tag(kg)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 140, height: 192)
                .clipped()
                
                Text("kg")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.gray)
                    .offset(x: -20)
            }
        }
        .frame(height: 192)
    }
}
