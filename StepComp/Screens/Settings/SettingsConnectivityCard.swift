//
//  SettingsConnectivityCard.swift
//  FitComp
//
//  HealthKit / Apple Watch connectivity card extracted from SettingsView.swift.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ConnectivityCard: View {
    @Binding var healthKitEnabled: Bool
    @Binding var appleWatchSetup: Bool
    @EnvironmentObject var healthKitService: HealthKitService
    
    
    var body: some View {
        SettingsCard(
            icon: "applewatch",
            iconColor: .blue,
            title: "Connectivity"
        ) {
            VStack(spacing: 16) {
                // HealthKit
                SettingItemRow(
                    icon: "heart.fill",
                    title: "HealthKit Sync",
                    subtitle: healthKitEnabled ? "Permissions Granted" : "Not Authorized",
                    trailing: {
                        Toggle("", isOn: Binding(
                            get: { healthKitEnabled },
                            set: { newValue in
                                if newValue {
                                    Task {
                                        do {
                                            try await healthKitService.requestAuthorization()
                                            await MainActor.run {
                                                healthKitEnabled = healthKitService.isAuthorized
                                            }
                                        } catch {
                                            print("⚠️ Error requesting HealthKit authorization: \(error.localizedDescription)")
                                        }
                                    }
                                } else {
                                    // Can't revoke HealthKit permissions from app
                                    // Redirect to Settings
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        ))
                            .toggleStyle(SwitchToggleStyle(tint: FitCompColors.primary))
                            .labelsHidden()
                            .fixedSize()
                    }
                )
                
                // Apple Watch
                SettingItemRow(
                    icon: "applewatch",
                    title: "Apple Watch",
                    subtitle: appleWatchSetup ? "Connected" : "Coming Soon",
                    trailing: {
                        if !appleWatchSetup {
                            Text("Soon")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(FitCompColors.surfaceElevated)
                                .cornerRadius(999)
                        } else {
                            Toggle("", isOn: $appleWatchSetup)
                                .toggleStyle(SwitchToggleStyle(tint: FitCompColors.primary))
                                .labelsHidden()
                                .fixedSize()
                                .disabled(true)
                        }
                    }
                )
            }
        }
    }
}
