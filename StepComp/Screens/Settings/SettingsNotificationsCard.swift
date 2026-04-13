//
//  SettingsNotificationsCard.swift
//  FitComp
//
//  Notification preferences card extracted from SettingsView.swift.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct NotificationsCard: View {
    @Binding var dailyRecap: Bool
    @Binding var leaderboardAlerts: Bool
    @Binding var motivationalNudges: Bool
    
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isRequestingPermission = false
    
    var body: some View {
        SettingsCard(
            icon: "bell.badge.fill",
            iconColor: .yellow,
            title: "Notifications"
        ) {
            VStack(spacing: 16) {
                // Permission status banner
                if notificationManager.authorizationStatus == .notDetermined {
                    Button(action: {
                        Task {
                            isRequestingPermission = true
                            do {
                                try await notificationManager.requestAuthorization()
                            } catch {
                                print("❌ Error requesting notification permission: \(error)")
                            }
                            isRequestingPermission = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "bell.badge")
                                    .font(.system(size: 18))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Notifications")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Get updates on your progress")
                                    .font(.system(size: 12))
                                    .opacity(0.8)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(12)
                        .background(FitCompColors.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isRequestingPermission)
                } else if notificationManager.authorizationStatus == .denied {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications Disabled")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Enable in Settings app")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Open Settings")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(FitCompColors.primary)
                        }
                    }
                    .padding(12)
                    .background(FitCompColors.surfaceElevated)
                    .cornerRadius(12)
                }
                
                // Notification toggles
                SettingItemRow(
                    icon: "doc.text.fill",
                    title: "Daily Recap",
                    subtitle: "8 PM summary",
                    trailing: {
                        Toggle("", isOn: $dailyRecap)
                            .toggleStyle(SwitchToggleStyle(tint: FitCompColors.primary))
                            .labelsHidden()
                            .fixedSize()
                            .disabled(!notificationManager.isAuthorized)
                    }
                )
                
                SettingItemRow(
                    icon: "trophy.fill",
                    title: "Leaderboard Alerts",
                    subtitle: "Rank changes",
                    trailing: {
                        Toggle("", isOn: $leaderboardAlerts)
                            .toggleStyle(SwitchToggleStyle(tint: FitCompColors.primary))
                            .labelsHidden()
                            .fixedSize()
                            .disabled(!notificationManager.isAuthorized)
                    }
                )
                
                SettingItemRow(
                    icon: "bolt.fill",
                    title: "Motivational Nudges",
                    subtitle: "10 AM, 2 PM, 6 PM",
                    trailing: {
                        Toggle("", isOn: $motivationalNudges)
                            .toggleStyle(SwitchToggleStyle(tint: FitCompColors.primary))
                            .labelsHidden()
                            .fixedSize()
                            .disabled(!notificationManager.isAuthorized)
                    }
                )
            }
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
    }
}
