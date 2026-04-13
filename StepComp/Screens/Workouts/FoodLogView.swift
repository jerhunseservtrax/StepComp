//
//  FoodLogView.swift
//  FitComp
//
//  Coordinates the food log experience: full-screen detail sheet composes
//  `FoodLogDailySummaryHeader` and per-meal sections. Related UI lives in sibling files
//  (`FoodLogSummaryCard`, `AddMealView`, barcode/camera helpers, etc.).
//

import SwiftUI

// MARK: - Full Food Log Sheet

struct FoodLogDetailView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddMeal = false
    @State private var showingCalorieGoalEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FoodLogDailySummaryHeader(
                            summary: viewModel.todaySummary,
                            onEditCalorieGoal: { showingCalorieGoalEditor = true }
                        )

                        ForEach(MealType.allCases) { mealType in
                            FoodLogMealSectionView(
                                mealType: mealType,
                                mealEntries: viewModel.todayEntriesByMeal[mealType] ?? [],
                                viewModel: viewModel,
                                onAddMeal: { showingAddMeal = true }
                            )
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
}
