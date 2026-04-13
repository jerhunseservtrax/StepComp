//
//  MetricsView.swift
//  FitComp
//

import SwiftUI

struct MetricsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @EnvironmentObject private var challengeService: ChallengeService
    @EnvironmentObject private var healthKitService: HealthKitService
    @StateObject private var viewModel = MetricsViewModel()

    var body: some View {
        ZStack {
            FitCompColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    timePeriodPicker

                    if viewModel.isLoading {
                        ProgressView("Loading metrics...")
                            .accessibilityLabel("Loading metrics")
                            .accessibilityHint("Waits until your workout and activity data finishes loading.")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 30)
                    } else {
                        PerformancePillarSection(viewModel: viewModel)
                        InsightsPillarSection(viewModel: viewModel)
                        ExerciseHistorySection(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
        .task {
            await refreshData()
        }
        .onChange(of: viewModel.selectedTimePeriod) { _, _ in
            Task {
                await refreshData()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Metrics")
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(FitCompColors.textPrimary)
        }
    }

    private var timePeriodPicker: some View {
        Picker("Time Period", selection: $viewModel.selectedTimePeriod) {
            ForEach(MetricsTimePeriod.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Time range for metrics")
        .accessibilityValue(viewModel.selectedTimePeriod.title)
        .accessibilityHint("Chooses how far back to load steps, workouts, and strength metrics.")
    }

    private func refreshData() async {
        await viewModel.loadData(
            challengeService: challengeService,
            healthKitService: healthKitService,
            currentUserId: sessionViewModel.currentUser?.id
        )
    }
}
