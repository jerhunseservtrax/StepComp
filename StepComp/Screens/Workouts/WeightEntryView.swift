//
//  WeightEntryView.swift
//  FitComp
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
    @State private var currentMonth = Date()
    
    private var datesWithEntries: Set<String> {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return Set(viewModel.entries.map { entry in
            dateFormatter.string(from: calendar.startOfDay(for: entry.date))
        })
    }
    
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
            .background(FitCompColors.background.ignoresSafeArea())
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .scrollDismissesKeyboard(.immediately)
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
                .foregroundColor(FitCompColors.textSecondary)
            
            CustomCalendarView(
                selectedDate: $selectedDate,
                currentMonth: $currentMonth,
                datesWithEntries: datesWithEntries,
                colorScheme: colorScheme
            )
            
            // Legend showing days with entries
            if !viewModel.entries.isEmpty {
                HStack(spacing: 6) {
                    Circle()
                        .fill(FitCompColors.primary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Days with weight entries")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }
                .padding(.top, 8)
            }
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
                .foregroundColor(FitCompColors.textSecondary)
            
            HStack(spacing: 16) {
                TextField("Enter weight", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold))
                    .padding()
                    .background(FitCompColors.textSecondary.opacity(0.1))
                    .cornerRadius(12)
                
                Text(unitManager.weightUnit)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FitCompColors.textSecondary)
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
                .background(FitCompColors.primary)
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
                .foregroundColor(FitCompColors.textSecondary)

            let graphData = viewModel.getEntriesForGraph(days: 90)
            let historyPoints = graphData.map { entry in
                WeightHistoryPoint(entry: entry)
            }

            WeightTrendChart(points: historyPoints)
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
                .foregroundColor(FitCompColors.textSecondary)
            
            if viewModel.entries.isEmpty {
                Text("No weight entries yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitCompColors.textSecondary)
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
                    .foregroundColor(FitCompColors.textPrimary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(unitManager.formatWeight(entry.weightKg, decimals: 1))
                        .font(.system(size: 18, weight: .bold))
                    Text(unitManager.weightUnit.lowercased())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
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

// MARK: - Custom Calendar View

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    let datesWithEntries: Set<String>
    let colorScheme: ColorScheme
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let numberOfDays = monthRange.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FitCompColors.primary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FitCompColors.textPrimary)
                
                Spacer()
                
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canGoForward ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.3))
                        .frame(width: 44, height: 44)
                }
                .disabled(!canGoForward)
            }
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEntry: datesWithEntries.contains(dateFormatter.string(from: date)),
                            isFuture: date > Date(),
                            colorScheme: colorScheme
                        )
                        .onTapGesture {
                            if date <= Date() {
                                selectedDate = date
                                HapticManager.shared.light()
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }
    
    private var canGoForward: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        return nextMonth <= Date()
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            if newMonth <= Date() || value < 0 {
                currentMonth = newMonth
                HapticManager.shared.light()
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEntry: Bool
    let isFuture: Bool
    let colorScheme: ColorScheme
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            // Selection background
            if isSelected {
                Circle()
                    .fill(FitCompColors.primary)
                    .frame(width: 40, height: 40)
            } else if isToday {
                Circle()
                    .stroke(FitCompColors.primary, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
            
            // Entry indicator (dot below number)
            if hasEntry && !isSelected {
                VStack(spacing: 2) {
                    Text(dayNumber)
                        .font(.system(size: 16, weight: isToday ? .bold : .medium))
                        .foregroundColor(
                            isFuture ? FitCompColors.textSecondary.opacity(0.3) :
                            isToday ? FitCompColors.primary :
                            FitCompColors.textPrimary
                        )
                    
                    Circle()
                        .fill(FitCompColors.primary)
                        .frame(width: 6, height: 6)
                }
                .frame(width: 44, height: 44)
            } else {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday || isSelected ? .bold : .medium))
                    .foregroundColor(
                        isSelected ? FitCompColors.buttonTextOnPrimary :
                        isFuture ? FitCompColors.textSecondary.opacity(0.3) :
                        isToday ? FitCompColors.primary :
                        FitCompColors.textPrimary
                    )
                    .frame(width: 44, height: 44)
            }
        }
    }
}
