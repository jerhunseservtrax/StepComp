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
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 30)
                    } else {
                        PerformancePillarSection(viewModel: viewModel)
                        InsightsPillarSection(viewModel: viewModel)
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Metrics")
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(FitCompColors.textPrimary)
            Text("DATA -> SCORE -> STATUS -> ACTION")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(FitCompColors.textSecondary)
        }
    }

    private var timePeriodPicker: some View {
        Picker("Time Period", selection: $viewModel.selectedTimePeriod) {
            ForEach(MetricsTimePeriod.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private func refreshData() async {
        await viewModel.loadData(
            challengeService: challengeService,
            healthKitService: healthKitService,
            currentUserId: sessionViewModel.currentUser?.id
        )
    }
}
