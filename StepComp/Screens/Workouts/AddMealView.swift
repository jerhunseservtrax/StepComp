//
//  AddMealView.swift
//  FitComp
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - Add Meal Sheet

struct AddMealView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMealType: MealType = .lunch
    @State private var foodQuery = ""
    @State private var selectedItems: [FoodItem] = []
    @State private var selectedResultKeys: Set<String> = []
    @State private var pendingWeightItem: NutritionItem?
    @State private var pendingBackgroundURL: URL?
    @State private var pendingWeightText = ""
    @State private var weightInputUnit: AddMealWeightInputUnit = .grams
    @State private var showingWeightPrompt = false
    @State private var liveSearchTask: Task<Void, Never>?
    @State private var mealPhoto: UIImage?
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingBarcodeScanner = false
    @State private var manualBarcode = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var didAutoScan = false

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        RecentMealsSectionView(
                            viewModel: viewModel,
                            isMealSelected: { isMealSelected($0) },
                            onTapMeal: { addRecentMeal($0) }
                        )
                        AddMealMealTypePicker(selectedMealType: $selectedMealType)
                        AddMealPhotoSection(
                            viewModel: viewModel,
                            mealPhoto: $mealPhoto,
                            showingCamera: $showingCamera,
                            showingBarcodeScanner: $showingBarcodeScanner,
                            manualBarcode: $manualBarcode,
                            foodQuery: $foodQuery,
                            photoPickerItem: $photoPickerItem,
                            didAutoScan: $didAutoScan,
                            onManualBarcodeLookup: performManualBarcodeLookup,
                            onSearch: performSearch,
                            onClearPhotoAndScan: clearPhotoAndScan
                        )
                        FoodSearchSection(foodQuery: $foodQuery, viewModel: viewModel, onSearch: performSearch)
                        FoodSearchResultsSection(
                            viewModel: viewModel,
                            selectedResultKeys: selectedResultKeys,
                            selectionKey: { selectionKey(for: $0) },
                            onToggle: { toggleItem($0) }
                        )
                        RecentFoodsSectionView(
                            viewModel: viewModel,
                            selectedResultKeys: selectedResultKeys,
                            selectionKey: { selectionKey(for: $0) },
                            onToggle: { toggleCachedItem($0) }
                        )
                        SelectedFoodItemsSectionView(
                            selectedItems: $selectedItems,
                            selectedResultKeys: $selectedResultKeys,
                            selectionKey: { selectionKey(for: $0) }
                        )
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
                AddMealWeightPromptSheet(
                    pendingWeightItem: $pendingWeightItem,
                    pendingBackgroundURL: $pendingBackgroundURL,
                    pendingWeightText: $pendingWeightText,
                    weightInputUnit: $weightInputUnit,
                    onConfirm: { addPendingItemWithWeight() },
                    onCancel: {
                        pendingWeightItem = nil
                        showingWeightPrompt = false
                    }
                )
            }
            .onChange(of: foodQuery) { _, newQuery in
                scheduleLiveSearch(for: newQuery)
            }
            .onDisappear {
                liveSearchTask?.cancel()
            }
        }
    }

    // MARK: - Actions

    private func clearPhotoAndScan() {
        mealPhoto = nil
        didAutoScan = false
        viewModel.resetScanStatus()
        viewModel.searchResults = []
        viewModel.errorMessage = nil
    }

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

    private func defaultAmountForUnit(item: NutritionItem, unit: AddMealWeightInputUnit) -> Double {
        switch unit {
        case .grams:
            return max(item.servingSizeG, 1)
        case .ounces:
            return max(item.servingSizeG, 1) / 28.3495
        case .serving:
            return 1
        }
    }
}
