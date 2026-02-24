//
//  WeightEntryView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import SwiftUI
import Charts

struct WeightEntryView: View {
    @ObservedObject var viewModel: WeightViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedDate = Date()
    @State private var weightInput: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f8f8f5")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Picker
                    datePicker
                    
                    // Weight Input
                    weightInputSection
                    
                    // Graph
                    weightGraphSection
                    
                    // Recent Entries
                    recentEntriesSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(StepCompColors.background.ignoresSafeArea())
            .navigationTitle("Weight Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Invalid Weight", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DATE")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundColor(StepCompColors.textSecondary)
            
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(StepCompColors.primary)
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(24)
    }
    
    private var weightInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WEIGHT")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundColor(StepCompColors.textSecondary)
            
            HStack(spacing: 16) {
                TextField("Enter weight", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold))
                    .padding()
                    .background(StepCompColors.textSecondary.opacity(0.1))
                    .cornerRadius(12)
                
                Text(unitManager.weightUnit)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(StepCompColors.textSecondary)
                    .frame(width: 50)
            }
            
            Button(action: saveWeight) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Weight")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(StepCompColors.primary)
                .foregroundColor(.black)
                .cornerRadius(28)
            }
            .disabled(weightInput.isEmpty)
            .opacity(weightInput.isEmpty ? 0.5 : 1.0)
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(24)
    }
    
    private var weightGraphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TREND (LAST 90 DAYS)")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundColor(StepCompColors.textSecondary)
            
            let graphData = viewModel.getEntriesForGraph(days: 90)
            
            if graphData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("Add weight entries to see trends")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                Chart(graphData) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", unitManager.convertWeightFromStorage(entry.weightKg))
                    )
                    .foregroundStyle(StepCompColors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", unitManager.convertWeightFromStorage(entry.weightKg))
                    )
                    .foregroundStyle(StepCompColors.primary)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 15)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(24)
    }
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT ENTRIES")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundColor(StepCompColors.textSecondary)
            
            if viewModel.entries.isEmpty {
                Text("No weight entries yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(StepCompColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.entries.prefix(10)) { entry in
                    WeightEntryRow(entry: entry, unitManager: unitManager, onDelete: {
                        viewModel.deleteEntry(id: entry.id)
                    })
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(24)
    }
    
    private func saveWeight() {
        guard let weight = Double(weightInput) else {
            alertMessage = "Please enter a valid number"
            showingAlert = true
            return
        }
        
        // Convert to kg for storage
        let weightKg = unitManager.convertWeightToStorage(weight)
        
        // Validate range (20-500 kg / 44-1100 lbs)
        if weightKg < 20 || weightKg > 500 {
            alertMessage = "Weight must be between \(unitManager.formatWeight(20, decimals: 0)) and \(unitManager.formatWeight(500, decimals: 0)) \(unitManager.weightUnit)"
            showingAlert = true
            return
        }
        
        viewModel.addEntry(weightKg: weightKg, date: selectedDate, source: .manual)
        
        // Clear input and reset date
        weightInput = ""
        selectedDate = Date()
        
        // Haptic feedback
        HapticManager.shared.success()
    }
}

struct WeightEntryRow: View {
    let entry: WeightEntry
    @ObservedObject var unitManager: UnitPreferenceManager
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: entry.date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(StepCompColors.textPrimary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(unitManager.formatWeight(entry.weightKg, decimals: 1))
                        .font(.system(size: 18, weight: .bold))
                    Text(unitManager.weightUnit.lowercased())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Source badge
            Text(entry.source == .healthKit ? "HealthKit" : "Manual")
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(entry.source == .healthKit ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(entry.source == .healthKit ? .green : .blue)
                .cornerRadius(8)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}
