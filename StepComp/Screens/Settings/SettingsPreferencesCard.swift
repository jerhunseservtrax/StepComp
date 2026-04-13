//
//  SettingsPreferencesCard.swift
//  FitComp
//
//  App preferences card extracted from SettingsView.swift.
//

import SwiftUI

struct PreferencesCard: View {
    @Binding var darkMode: Bool
    @ObservedObject private var unitPreferenceManager = UnitPreferenceManager.shared
    let sessionViewModel: SessionViewModel?
    @State private var showingDailyStepGoalEditor = false
    @State private var refreshTrigger = UUID()
    @State private var selectedAlertMode: RestTimerAlertMode = {
        if let saved = UserDefaults.standard.string(forKey: "restTimerAlertMode"),
           let mode = RestTimerAlertMode(rawValue: saved) {
            return mode
        }
        return .visual
    }()
    @State private var restTimerAlertsEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "restTimerAlertsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "restTimerAlertsEnabled")
            return true
        }
        return UserDefaults.standard.bool(forKey: "restTimerAlertsEnabled")
    }()
    @EnvironmentObject var themeManager: ThemeManager
    
    private var unitSystemPicker: some View {
        Picker(
            "Unit System",
            selection: Binding(
                get: { unitPreferenceManager.unitSystem },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        unitPreferenceManager.unitSystem = newValue
                    }
                }
            )
        ) {
            Text("Metric").tag(UnitSystem.metric)
            Text("Imperial").tag(UnitSystem.imperial)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .tint(FitCompColors.primary)
    }
    
    var body: some View {
        SettingsCard(
            icon: "slider.horizontal.3",
            iconColor: .purple,
            title: "App Preferences"
        ) {
            VStack(spacing: 16) {
                SettingItemRow(
                    icon: "moon.fill",
                    iconBackground: Color.black,
                    title: "Dark Mode",
                    subtitle: "Change app appearance",
                    trailing: {
                        Toggle("", isOn: Binding(
                            get: { themeManager.isDarkMode },
                            set: { newValue in
                                darkMode = newValue
                                themeManager.isDarkMode = newValue
                            }
                        ))
                            .toggleStyle(SwitchToggleStyle(tint: FitCompColors.primary))
                            .labelsHidden()
                            .fixedSize()
                    }
                )
                
                SettingItemRow(
                    icon: "ruler.fill",
                    title: "Unit System",
                    subtitle: "Metric or imperial measurements",
                    layout: .stacked,
                    trailing: {
                        unitSystemPicker
                    }
                )
                
                SettingItemRow(
                    icon: "timer",
                    iconBackground: .orange,
                    title: "Rest Timer Alerts",
                    subtitle: "Enable sound/haptics/notifications when rest completes",
                    trailing: {
                        Toggle("", isOn: $restTimerAlertsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: FitCompColors.primary))
                            .labelsHidden()
                            .fixedSize()
                    }
                )

                SettingItemRow(
                    icon: "bell.badge",
                    iconBackground: .orange,
                    title: "Rest Timer Alert",
                    subtitle: restTimerAlertsEnabled ? selectedAlertMode.label : "Disabled",
                    trailing: {
                        Menu {
                            ForEach(RestTimerAlertMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    selectedAlertMode = mode
                                    UserDefaults.standard.set(mode.rawValue, forKey: "restTimerAlertMode")
                                }) {
                                    Label(mode.label, systemImage: mode.icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: selectedAlertMode.icon)
                                    .font(.system(size: 12))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(FitCompColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(FitCompColors.surfaceElevated)
                            .cornerRadius(999)
                        }
                    }
                )
                .disabled(!restTimerAlertsEnabled)
                .opacity(restTimerAlertsEnabled ? 1.0 : 0.5)
                
                // Daily Step Goal
                if let sessionViewModel = sessionViewModel {
                    Button(action: {
                        showingDailyStepGoalEditor = true
                    }) {
                        SettingItemRow(
                            icon: "target",
                            iconBackground: .green,
                            title: "Daily Step Goal",
                            subtitle: {
                                let goal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
                                if goal > 0 {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    return "\(formatter.string(from: NSNumber(value: goal)) ?? "\(goal)") steps"
                                } else {
                                    return "10,000 steps (default)"
                                }
                            }(),
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showingDailyStepGoalEditor) {
                        if let user = sessionViewModel.currentUser {
                            EditDailyStepGoalSheet(
                                user: user,
                                currentGoal: UserDefaults.standard.integer(forKey: "dailyStepGoal") > 0
                                    ? UserDefaults.standard.integer(forKey: "dailyStepGoal")
                                    : 10000,
                                onSave: { goal in
                                    Task {
                                        await sessionViewModel.authServiceAccess.updateDailyStepGoal(goal)
                                        // Trigger view refresh
                                        DispatchQueue.main.async {
                                            refreshTrigger = UUID()
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .id(refreshTrigger) // Add id modifier to force refresh when trigger changes
        .onChange(of: restTimerAlertsEnabled) { _, enabled in
            UserDefaults.standard.set(enabled, forKey: "restTimerAlertsEnabled")
        }
    }
}
