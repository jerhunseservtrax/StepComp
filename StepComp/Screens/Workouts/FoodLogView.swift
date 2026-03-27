//
//  FoodLogView.swift
//  FitComp
//

import SwiftUI
import PhotosUI
import AVFoundation
import Foundation

// MARK: - Summary Card (embedded in WorkoutsView)

struct FoodLogSummaryCard: View {
    @ObservedObject var viewModel: FoodLogViewModel
    @Binding var showingFoodLog: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var summary: DailyNutritionSummary { viewModel.todaySummary }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f8f8f5")
    }

    var body: some View {
        Button(action: { showingFoodLog = true }) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("FOOD LOG")
                        .font(.system(size: 13, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(FitCompColors.textSecondary)

                    Spacer()

                    Text(Date.now, style: .date)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                }

                HStack(spacing: 0) {
                    calorieRing
                        .frame(width: 80, height: 80)

                    Spacer().frame(width: 20)

                    VStack(alignment: .leading, spacing: 10) {
                        macroRow(label: "Protein", value: summary.totalProteinG, goal: Double(summary.proteinGoalG), color: FitCompColors.cyan)
                        macroRow(label: "Carbs", value: summary.totalCarbsG, goal: nil, color: FitCompColors.accent)
                        macroRow(label: "Fat", value: summary.totalFatG, goal: nil, color: FitCompColors.purple)
                    }
                    .frame(maxWidth: .infinity)
                }

                if !viewModel.todayEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DAILY LOG")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                            .foregroundColor(FitCompColors.textSecondary)
                        ForEach(viewModel.todayEntries.prefix(2)) { entry in
                            mealPreviewRow(entry)
                        }
                    }
                }

                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Log a Meal")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FitCompColors.textSecondary.opacity(0.5))
                }
                .foregroundColor(FitCompColors.primary)
            }
            .padding(20)
            .background(cardBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var calorieRing: some View {
        ZStack {
            Circle()
                .stroke(FitCompColors.textSecondary.opacity(0.15), lineWidth: 8)

            Circle()
                .trim(from: 0, to: summary.calorieProgress)
                .stroke(FitCompColors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(summary.totalCalories))")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(FitCompColors.textPrimary)
                Text("/ \(summary.calorieGoal)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
                Text("cal")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
            }
        }
    }

    private func macroRow(label: String, value: Double, goal: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(FitCompColors.textSecondary)
                Spacer()
                if let goal {
                    Text("\(Int(value))/\(Int(goal))g")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                } else {
                    Text("\(Int(value))g")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: barWidth(value: value, goal: goal, totalWidth: geo.size.width))
                }
            }
            .frame(height: 5)
        }
    }

    private func barWidth(value: Double, goal: Double?, totalWidth: CGFloat) -> CGFloat {
        let target = goal ?? 200.0
        guard target > 0 else { return 0 }
        return min(CGFloat(value / target), 1.0) * totalWidth
    }

    private func mealPreviewRow(_ entry: FoodLogEntry) -> some View {
        HStack(spacing: 8) {
            Image(systemName: entry.mealType.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.primary)
                .frame(width: 22, height: 22)
                .background(FitCompColors.primary.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.mealType.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
                Text(entry.description)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FitCompColors.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(Int(entry.totalCalories)) kcal")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(FitCompColors.textPrimary)
        }
        .padding(10)
        .background(FitCompColors.textSecondary.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Full Food Log Sheet

struct FoodLogDetailView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAddMeal = false
    @State private var showingCalorieGoalEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        dailySummaryHeader

                        ForEach(MealType.allCases) { mealType in
                            mealSection(mealType)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Food Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddMeal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(FitCompColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCalorieGoalEditor) {
                ManualCalorieGoalSheet()
            }
        }
    }

    private var dailySummaryHeader: some View {
        let summary = viewModel.todaySummary
        return VStack(spacing: 16) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(FitCompColors.textSecondary.opacity(0.15), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: summary.calorieProgress)
                        .stroke(FitCompColors.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(Int(summary.totalCalories))")
                            .font(.system(size: 24, weight: .black))
                        Button {
                            showingCalorieGoalEditor = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("/ \(summary.calorieGoal) cal")
                                    .font(.system(size: 11, weight: .bold))
                                Image(systemName: "pencil")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(FitCompColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    macroStat("Protein", value: summary.totalProteinG, goal: Double(summary.proteinGoalG), color: FitCompColors.cyan)
                    macroStat("Carbs", value: summary.totalCarbsG, goal: nil, color: FitCompColors.accent)
                    macroStat("Fat", value: summary.totalFatG, goal: nil, color: FitCompColors.purple)
                }
            }
        }
        .padding(20)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(24)
    }

    private func macroStat(_ label: String, value: Double, goal: Double?, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.textSecondary)
            Spacer()
            if let goal {
                Text("\(Int(value))/\(Int(goal))g")
                    .font(.system(size: 13, weight: .black))
            } else {
                Text("\(Int(value))g")
                    .font(.system(size: 13, weight: .black))
            }
        }
    }

    @ViewBuilder
    private func mealSection(_ mealType: MealType) -> some View {
        let mealEntries = viewModel.todayEntriesByMeal[mealType] ?? []

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: mealType.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FitCompColors.primary)
                Text(mealType.title.uppercased())
                    .font(.system(size: 13, weight: .black))
                    .tracking(1)
                    .foregroundColor(FitCompColors.textSecondary)
                Spacer()
                if !mealEntries.isEmpty {
                    let totalCal = mealEntries.reduce(0.0) { $0 + $1.totalCalories }
                    Text("\(Int(totalCal)) cal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                }
            }

            if mealEntries.isEmpty {
                Button(action: { showingAddMeal = true }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add \(mealType.title)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(FitCompColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FitCompColors.textSecondary.opacity(0.06))
                    .cornerRadius(12)
                }
            } else {
                ForEach(mealEntries) { entry in
                    MealEntryRow(entry: entry, viewModel: viewModel)
                }
            }
        }
        .padding(14)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

struct MealEntryRow: View {
    let entry: FoodLogEntry
    @ObservedObject var viewModel: FoodLogViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.description)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)

                    HStack(spacing: 12) {
                        Text("\(Int(entry.totalCalories)) cal")
                            .font(.system(size: 12, weight: .black))
                        Text("P: \(Int(entry.totalProteinG))g")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FitCompColors.cyan)
                        Text("C: \(Int(entry.totalCarbsG))g")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FitCompColors.accent)
                        Text("F: \(Int(entry.totalFatG))g")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FitCompColors.purple)
                    }

                    Text(timeString(entry.loggedAt))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(FitCompColors.textTertiary)
                }

                Spacer()

                if let photoName = entry.photoFileName,
                   let image = viewModel.loadPhoto(named: photoName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if entry.items.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.items) { item in
                        HStack {
                            Text(item.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                            Spacer()
                            Text("\(Int(item.calories)) cal")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Add Meal Sheet

struct AddMealView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedMealType: MealType = .lunch
    @State private var foodQuery = ""
    @State private var selectedItems: [FoodItem] = []
    @State private var selectedResultKeys: Set<String> = []
    @State private var pendingWeightItem: NutritionItem?
    @State private var pendingBackgroundURL: URL?
    @State private var pendingWeightText = ""
    @State private var weightInputUnit: WeightInputUnit = .grams
    @State private var showingWeightPrompt = false
    @State private var liveSearchTask: Task<Void, Never>?
    @State private var mealPhoto: UIImage?
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingBarcodeScanner = false
    @State private var manualBarcode = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var didAutoScan = false

    private enum WeightInputUnit: String, CaseIterable, Identifiable {
        case grams
        case ounces
        case serving

        var id: String { rawValue }

        var title: String {
            switch self {
            case .grams: return "Grams"
            case .ounces: return "Ounces"
            case .serving: return "Serving"
            }
        }

        var shortLabel: String {
            switch self {
            case .grams: return "g"
            case .ounces: return "oz"
            case .serving: return "srv"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        mealTypePicker
                        photoSection
                        searchSection
                        recentMealsSection
                        recentFoodsSection
                        resultsSection
                        selectedItemsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveMeal() }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(selectedItems.isEmpty ? FitCompColors.textSecondary : FitCompColors.primary)
                        .disabled(selectedItems.isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerSheet { scannedCode in
                    handleScannedBarcode(scannedCode)
                }
            }
            .sheet(isPresented: $showingWeightPrompt) {
                weightPromptSheet
            }
            .onChange(of: foodQuery) { _, newQuery in
                scheduleLiveSearch(for: newQuery)
            }
            .onDisappear {
                liveSearchTask?.cancel()
            }
        }
    }

    private var mealTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEAL TYPE")
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundColor(FitCompColors.textSecondary)

            HStack(spacing: 8) {
                ForEach(MealType.allCases) { meal in
                    Button(action: { selectedMealType = meal }) {
                        VStack(spacing: 4) {
                            Image(systemName: meal.icon)
                                .font(.system(size: 16, weight: .bold))
                            Text(meal.title)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedMealType == meal ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.08))
                        .foregroundColor(selectedMealType == meal ? FitCompColors.buttonTextOnPrimary : FitCompColors.textSecondary)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SNAP & SCAN")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .foregroundColor(FitCompColors.textSecondary)
                Spacer()
                if mealPhoto != nil {
                    Text("Photo attached")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(FitCompColors.green)
                }
            }

            if mealPhoto == nil {
                HStack(spacing: 12) {
                    Button(action: { showingCamera = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 28, weight: .semibold))
                            Text("Take Photo")
                                .font(.system(size: 12, weight: .bold))
                            Text("of your meal")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FitCompColors.textTertiary)
                        }
                        .foregroundColor(FitCompColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(FitCompColors.primary.opacity(0.08))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(FitCompColors.primary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $showingCamera) {
                        CameraPickerView(image: $mealPhoto)
                    }

                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28, weight: .semibold))
                            Text("From Gallery")
                                .font(.system(size: 12, weight: .bold))
                            Text("pick a photo")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FitCompColors.textTertiary)
                        }
                        .foregroundColor(FitCompColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(FitCompColors.textSecondary.opacity(0.06))
                        .cornerRadius(16)
                    }
                    .onChange(of: photoPickerItem) { _, newItem in
                        Task {
                            if let newItem,
                               let data = try? await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                mealPhoto = uiImage
                            }
                        }
                    }
                }

                Button(action: { showingBarcodeScanner = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18, weight: .bold))
                        Text("Scan Barcode")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(FitCompColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 14)
                    .background(FitCompColors.textSecondary.opacity(0.06))
                    .cornerRadius(12)
                }

                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(FitCompColors.textSecondary)
                        TextField("Enter barcode manually", text: $manualBarcode)
                            .font(.system(size: 14, weight: .medium))
                            .keyboardType(.numberPad)
                            .submitLabel(.search)
                            .onSubmit { performManualBarcodeLookup() }
                    }
                    .padding(12)
                    .background(FitCompColors.textSecondary.opacity(0.08))
                    .cornerRadius(12)

                    Button(action: performManualBarcodeLookup) {
                        if viewModel.isSearching {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(FitCompColors.primary)
                        }
                    }
                    .disabled(viewModel.isSearching || manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                photoPreviewAndScanResult
            }
        }
        .onChange(of: mealPhoto) { _, newPhoto in
            guard let newPhoto, !didAutoScan else { return }
            didAutoScan = true
            Task { await viewModel.scanImage(newPhoto) }
        }
    }

    @ViewBuilder
    private var photoPreviewAndScanResult: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    if let photo = mealPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: {
                        mealPhoto = nil
                        didAutoScan = false
                        viewModel.resetScanStatus()
                        viewModel.searchResults = []
                        viewModel.errorMessage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                    .offset(x: 6, y: -6)
                }

                VStack(alignment: .leading, spacing: 6) {
                    switch viewModel.scanStatus {
                    case .scanning:
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Scanning photo...")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                    case .foundItems:
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(FitCompColors.green)
                            Text("Found \(viewModel.searchResults.count) item(s)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FitCompColors.green)
                        }
                        Text("Select items below to add them")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FitCompColors.textSecondary)
                    case .noTextDetected:
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "eye.fill")
                                    .foregroundColor(FitCompColors.accent)
                                Text("Describe your meal")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                            }
                            Text("Type what you see (e.g. \"grilled chicken with rice\") and we'll look up the nutrition.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .idle:
                        Text("Photo attached")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(FitCompColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.scanStatus == .noTextDetected {
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(FitCompColors.textSecondary)
                        TextField("Describe what you see...", text: $foodQuery)
                            .font(.system(size: 14, weight: .medium))
                            .submitLabel(.search)
                            .onSubmit { performSearch() }
                    }
                    .padding(12)
                    .background(FitCompColors.primary.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FitCompColors.primary.opacity(0.2), lineWidth: 1)
                    )

                    Button(action: performSearch) {
                        if viewModel.isSearching {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(FitCompColors.primary)
                        }
                    }
                    .disabled(viewModel.isSearching || foodQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SEARCH FOOD")
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundColor(FitCompColors.textSecondary)

            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(FitCompColors.textSecondary)
                    TextField("e.g. 2 eggs and toast", text: $foodQuery)
                        .font(.system(size: 14, weight: .medium))
                        .submitLabel(.search)
                        .onSubmit { performSearch() }
                }
                .padding(12)
                .background(FitCompColors.textSecondary.opacity(0.08))
                .cornerRadius(12)

                Button(action: performSearch) {
                    if viewModel.isSearching {
                        ProgressView()
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(FitCompColors.primary)
                    }
                }
                .disabled(viewModel.isSearching || foodQuery.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var recentMealsSection: some View {
        if !viewModel.recentMealEntries.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RECENT MEALS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(FitCompColors.textSecondary)
                    Spacer()
                    Text("Tap to reuse full meal")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(FitCompColors.textTertiary)
                }

                ForEach(viewModel.recentMealEntries) { entry in
                    let isSelected = isMealSelected(entry)
                    Button(action: { addRecentMeal(entry) }) {
                        HStack(spacing: 10) {
                            Image(systemName: entry.mealType.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(FitCompColors.primary)
                                .frame(width: 28, height: 28)
                                .background(FitCompColors.primary.opacity(0.12))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.description)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                                    .lineLimit(1)
                                Text("\(entry.mealType.title) • \(entry.items.count) item(s)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Spacer()
                            Text("\(Int(entry.totalCalories)) cal")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(FitCompColors.textPrimary)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.55))
                        }
                        .padding(12)
                        .background(isSelected ? FitCompColors.primary.opacity(0.08) : FitCompColors.textSecondary.opacity(0.04))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var recentFoodsSection: some View {
        if !viewModel.cachedFoods.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RECENT FOODS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(FitCompColors.textSecondary)
                    Spacer()
                    Text("Tap to reuse")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(FitCompColors.textTertiary)
                }

                ForEach(viewModel.cachedFoods.prefix(15)) { item in
                    let key = selectionKey(for: item)
                    let isSelected = selectedResultKeys.contains(key)
                    Button(action: { toggleCachedItem(item) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text("\(Int(item.servingSizeG))g • P:\(Int(item.proteinG)) C:\(Int(item.carbsG)) F:\(Int(item.fatG))")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Spacer()
                            Text("\(Int(item.calories)) cal")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(FitCompColors.textPrimary)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.55))
                                .padding(.leading, 6)
                        }
                        .padding(12)
                        .background(isSelected ? FitCompColors.primary.opacity(0.08) : FitCompColors.textSecondary.opacity(0.04))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if !viewModel.searchResults.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("RESULTS")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .foregroundColor(FitCompColors.textSecondary)

                ForEach(Array(viewModel.searchResults.enumerated()), id: \.offset) { _, item in
                    let key = selectionKey(for: item)
                    let isSelected = selectedResultKeys.contains(key)
                    Button(action: { toggleItem(item) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name.capitalized)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text("Tap to set weight (\(Int(item.servingSizeG))g default)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("\(Int(item.calories)) cal")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text("P:\(Int(item.proteinG)) C:\(Int(item.carbohydratesTotalG)) F:\(Int(item.fatTotalG))")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.3))
                                .padding(.leading, 6)
                        }
                        .padding(12)
                        .background(isSelected ? FitCompColors.primary.opacity(0.08) : FitCompColors.textSecondary.opacity(0.04))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? FitCompColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var selectedItemsSection: some View {
        if !selectedItems.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("SELECTED (\(selectedItems.count))")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(FitCompColors.textSecondary)
                    Spacer()
                    let totalCal = selectedItems.reduce(0.0) { $0 + $1.calories }
                    Text("\(Int(totalCal)) cal total")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(FitCompColors.primary)
                }

                ForEach(selectedItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FitCompColors.textPrimary)
                            Text("\(Int(item.consumedWeightG ?? item.servingSizeG))g")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                        Spacer()
                        Text("\(Int(item.calories)) cal")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FitCompColors.textSecondary)
                        Button(action: {
                            let key = selectionKey(for: item)
                            selectedResultKeys.remove(key)
                            selectedItems.removeAll { $0.id == item.id }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(FitCompColors.textSecondary.opacity(0.5))
                        }
                    }
                    .padding(10)
                    .background(FitCompColors.textSecondary.opacity(0.06))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Actions

    private func performSearch() {
        liveSearchTask?.cancel()
        Task { await viewModel.searchFood(query: foodQuery) }
    }

    private func toggleItem(_ item: NutritionItem) {
        let key = selectionKey(for: item)
        if selectedResultKeys.contains(key),
           let idx = selectedItems.firstIndex(where: { selectionKey(for: $0) == key }) {
            selectedResultKeys.remove(key)
            selectedItems.remove(at: idx)
        } else {
            pendingWeightItem = item
            pendingBackgroundURL = nil
            pendingWeightText = "\(Int(max(item.servingSizeG, 1)))"
            weightInputUnit = .grams
            showingWeightPrompt = true
            Task {
                pendingBackgroundURL = await UnsplashService.shared.fetchFoodImageURL(for: item.name)
            }
        }
    }

    private func toggleCachedItem(_ item: FoodItem) {
        let key = selectionKey(for: item)
        if selectedResultKeys.contains(key),
           let idx = selectedItems.firstIndex(where: { selectionKey(for: $0) == key }) {
            selectedResultKeys.remove(key)
            selectedItems.remove(at: idx)
            return
        }

        let cloned = FoodItem(
            id: UUID(),
            name: item.name,
            sourceKey: item.sourceKey,
            calories: item.calories,
            proteinG: item.proteinG,
            carbsG: item.carbsG,
            fatG: item.fatG,
            servingSizeG: item.servingSizeG,
            consumedWeightG: item.consumedWeightG ?? item.servingSizeG,
            fiberG: item.fiberG,
            sugarG: item.sugarG
        )
        selectedResultKeys.insert(key)
        selectedItems.append(cloned)
    }

    private func isMealSelected(_ entry: FoodLogEntry) -> Bool {
        !entry.items.isEmpty && entry.items.allSatisfy { selectedResultKeys.contains(selectionKey(for: $0)) }
    }

    private func addRecentMeal(_ entry: FoodLogEntry) {
        selectedMealType = entry.mealType
        for item in entry.items {
            let key = selectionKey(for: item)
            guard !selectedResultKeys.contains(key) else { continue }
            let cloned = FoodItem(
                id: UUID(),
                name: item.name,
                sourceKey: item.sourceKey,
                calories: item.calories,
                proteinG: item.proteinG,
                carbsG: item.carbsG,
                fatG: item.fatG,
                servingSizeG: item.servingSizeG,
                consumedWeightG: item.consumedWeightG ?? item.servingSizeG,
                fiberG: item.fiberG,
                sugarG: item.sugarG
            )
            selectedResultKeys.insert(key)
            selectedItems.append(cloned)
        }
    }

    private func saveMeal() {
        let description = selectedItems.map(\.name).joined(separator: ", ")
        viewModel.addEntry(
            mealType: selectedMealType,
            description: description,
            items: selectedItems,
            photo: mealPhoto
        )
        dismiss()
    }

    private func handleScannedBarcode(_ code: String) {
        liveSearchTask?.cancel()
        manualBarcode = code
        foodQuery = code
        Task {
            await viewModel.searchFoodByBarcode(code)
        }
    }

    private func performManualBarcodeLookup() {
        let code = manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        handleScannedBarcode(code)
    }

    private func scheduleLiveSearch(for query: String) {
        liveSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            viewModel.searchResults = []
            viewModel.errorMessage = nil
            return
        }

        liveSearchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await viewModel.searchFood(query: trimmed)
        }
    }

    private func selectionKey(for item: NutritionItem) -> String {
        FoodItem.makeSourceKey(for: item)
    }

    private func selectionKey(for item: FoodItem) -> String {
        if let sourceKey = item.sourceKey {
            return sourceKey
        }
        return [
            item.name.lowercased(),
            String(format: "%.3f", item.calories),
            String(format: "%.3f", item.servingSizeG),
            String(format: "%.3f", item.proteinG),
            String(format: "%.3f", item.carbsG),
            String(format: "%.3f", item.fatG)
        ].joined(separator: "|")
    }

    private var weightPromptSheet: some View {
        let preview = currentPreviewValues()
        return VStack(spacing: 0) {
            HStack {
                Button {
                    pendingWeightItem = nil
                    showingWeightPrompt = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                        .padding(10)
                        .background(FitCompColors.textSecondary.opacity(0.08))
                        .clipShape(Circle())
                }
                Spacer()
                Text("Add to Log")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FitCompColors.textPrimary)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            ZStack {
                backgroundForWeightPrompt

                ScrollView {
                    VStack(spacing: 20) {
                    if let item = pendingWeightItem {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(FitCompColors.primary.opacity(0.2))
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                            }
                            .frame(width: 62, height: 62)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name.capitalized)
                                    .font(.system(size: 28, weight: .black))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text("\(Int(item.caloriesPer100G.rounded())) kcal per 100g")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(colorScheme == .dark ? Color(hex: "1a1a1a").opacity(0.85) : Color.white.opacity(0.92))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
                        )
                    }

                    VStack(spacing: 10) {
                        Text("AMOUNT")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1)
                            .foregroundColor(FitCompColors.textSecondary)

                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            TextField("0", text: $pendingWeightText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 72, weight: .black))
                                .frame(maxWidth: 220)
                                .foregroundColor(FitCompColors.textPrimary)
                            Text(weightInputUnit.shortLabel)
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(FitCompColors.textSecondary.opacity(0.55))
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(WeightInputUnit.allCases) { unit in
                            Button {
                                switchUnit(to: unit)
                            } label: {
                                Text(unit.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(weightInputUnit == unit ? FitCompColors.primary : Color.clear)
                                    .foregroundColor(weightInputUnit == unit ? FitCompColors.textPrimary : FitCompColors.textSecondary)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(FitCompColors.textSecondary.opacity(0.08))
                    .cornerRadius(14)

                        HStack(spacing: 10) {
                            previewChip("Protein", value: preview.protein)
                            previewChip("Carbs", value: preview.carbs)
                            previewChip("Fat", value: preview.fat)
                        }

                        Button {
                            addPendingItemWithWeight()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Add to Log")
                                    .font(.system(size: 20, weight: .black))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(FitCompColors.primary)
                            .foregroundColor(FitCompColors.textPrimary)
                            .cornerRadius(14)
                        }

                        Button("Cancel") {
                            pendingWeightItem = nil
                            showingWeightPrompt = false
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : FitCompColors.textSecondary)
                        .padding(.top, 2)
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(FitCompColors.background.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }

    private var backgroundForWeightPrompt: some View {
        ZStack {
            if let url = pendingBackgroundURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } placeholder: {
                    LinearGradient(
                        colors: [FitCompColors.primary.opacity(0.3), FitCompColors.background],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                LinearGradient(
                    colors: [FitCompColors.primary.opacity(0.25), FitCompColors.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.45 : 0.15),
                    FitCompColors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private func addPendingItemWithWeight() {
        guard let item = pendingWeightItem else {
            showingWeightPrompt = false
            return
        }

        let grams = currentWeightInGrams(item: item)
        let key = selectionKey(for: item)
        let foodItem = FoodItem(from: item, consumedWeightG: grams)

        selectedResultKeys.insert(key)
        selectedItems.append(foodItem)
        pendingWeightItem = nil
        showingWeightPrompt = false
    }

    private func switchUnit(to newUnit: WeightInputUnit) {
        guard let item = pendingWeightItem, newUnit != weightInputUnit else {
            weightInputUnit = newUnit
            return
        }

        let grams = currentWeightInGrams(item: item)
        let convertedAmount: Double
        switch newUnit {
        case .grams:
            convertedAmount = grams
        case .ounces:
            convertedAmount = grams / 28.3495
        case .serving:
            convertedAmount = grams / max(item.servingSizeG, 1)
        }

        pendingWeightText = formatAmount(convertedAmount)
        weightInputUnit = newUnit
    }

    private func currentWeightInGrams(item: NutritionItem) -> Double {
        let numeric = Double(pendingWeightText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
        let amount = max(numeric ?? defaultAmountForUnit(item: item, unit: weightInputUnit), 0.1)
        let grams: Double
        switch weightInputUnit {
        case .grams:
            grams = amount
        case .ounces:
            grams = amount * 28.3495
        case .serving:
            grams = amount * max(item.servingSizeG, 1)
        }
        return min(max(grams, 1), 2000)
    }

    private func defaultAmountForUnit(item: NutritionItem, unit: WeightInputUnit) -> Double {
        switch unit {
        case .grams:
            return max(item.servingSizeG, 1)
        case .ounces:
            return max(item.servingSizeG, 1) / 28.3495
        case .serving:
            return 1
        }
    }

    private func currentPreviewValues() -> (protein: Double, carbs: Double, fat: Double) {
        guard let item = pendingWeightItem else {
            return (0, 0, 0)
        }
        let grams = currentWeightInGrams(item: item)
        let baseServing = max(item.servingSizeG, 1)
        let scale = grams / baseServing
        return (
            item.proteinG * scale,
            item.carbohydratesTotalG * scale,
            item.fatTotalG * scale
        )
    }

    private func previewChip(_ title: String, value: Double) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.textSecondary)
            Text("\(formatMacro(value))g")
                .font(.system(size: 30, weight: .black))
                .foregroundColor(FitCompColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private func formatMacro(_ value: Double) -> String {
        if value >= 10 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }

    private func formatAmount(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.01 {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%.1f", value)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private extension NutritionItem {
    var caloriesPer100G: Double {
        let serving = max(servingSizeG, 1)
        return calories * (100.0 / serving)
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Barcode Scanner

struct BarcodeScannerSheet: View {
    let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BarcodeScannerCameraView { code in
                onScanned(code)
                dismiss()
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct BarcodeScannerCameraView: UIViewControllerRepresentable {
    let onScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onScanned = onScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScanned: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    private let overlayLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureOverlayLabel()
        checkCameraPermissionAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func configureOverlayLabel() {
        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayLabel.text = "Point the camera at a barcode"
        overlayLabel.textColor = .white
        overlayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        overlayLabel.textAlignment = .center
        overlayLabel.numberOfLines = 2
        overlayLabel.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        overlayLabel.layer.cornerRadius = 10
        overlayLabel.clipsToBounds = true
        overlayLabel.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        view.addSubview(overlayLabel)
        NSLayoutConstraint.activate([
            overlayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            overlayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            overlayLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            overlayLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])
    }

    private func checkCameraPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.overlayLabel.text = "Camera access is required to scan barcodes."
                    }
                }
            }
        default:
            overlayLabel.text = "Enable camera access in Settings to scan barcodes."
        }
    }

    private func setupCaptureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            overlayLabel.text = "Unable to access camera."
            return
        }
        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else {
            overlayLabel.text = "Barcode scanning is unavailable."
            return
        }
        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [
            .ean8, .ean13, .upce, .code39, .code93, .code128, .pdf417, .qr
        ]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer

        captureSession.startRunning()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue,
              !value.isEmpty else { return }

        hasScanned = true
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        onScanned?(value)
    }
}
