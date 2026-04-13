//
//  SettingsMainContent.swift
//  FitComp
//
//  Main settings scroll/grid content extracted from SettingsView.swift.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsMainContent: View {
    @Binding var healthKitEnabled: Bool
    @Binding var appleWatchSetup: Bool
    @Binding var dailyRecap: Bool
    @Binding var leaderboardAlerts: Bool
    @Binding var motivationalNudges: Bool
    @Binding var darkMode: Bool
    
    let sessionViewModel: SessionViewModel?
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void
    let isDeletingAccount: Bool
    
    #if canImport(UIKit)
    private var horizontalContentPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
    }
    #else
    private var horizontalContentPadding: CGFloat { 16 }
    #endif
    
    var body: some View {
        VStack(spacing: 0) {
            // Desktop Header (only visible on iPad/Desktop)
            #if canImport(UIKit)
            if UIDevice.current.userInterfaceIdiom == .pad {
                HStack {
                    Text("Preferences")
                        .font(.system(size: 32, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: onSignOut) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(FitCompColors.surface)
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(FitCompColors.cardBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(
                    Color(.systemBackground)
                        .opacity(0.9)
                        .background(.ultraThinMaterial)
                )
            }
            #endif
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 24) {
                    // Settings Grid
                    #if canImport(UIKit)
                    let columns: [GridItem] = UIDevice.current.userInterfaceIdiom == .pad ? [
                        GridItem(.flexible(minimum: 280), spacing: 24),
                        GridItem(.flexible(minimum: 280), spacing: 24)
                    ] : [
                        GridItem(.flexible())
                    ]
                    #else
                    let columns: [GridItem] = [
                        GridItem(.flexible())
                    ]
                    #endif
                    
                    LazyVGrid(columns: columns, spacing: 24) {
                        // Connectivity Card
                        ConnectivityCard(
                            healthKitEnabled: $healthKitEnabled,
                            appleWatchSetup: $appleWatchSetup
                        )
                        
                        // Notifications Card
                        NotificationsCard(
                            dailyRecap: $dailyRecap,
                            leaderboardAlerts: $leaderboardAlerts,
                            motivationalNudges: $motivationalNudges
                        )
                        
                        // Preferences Card
                        PreferencesCard(
                            darkMode: $darkMode,
                            sessionViewModel: sessionViewModel
                        )
                        
                        // Support & Legal Card
                        SupportLegalCard()
                        
                        // Logout Button
                        Button(action: onSignOut) {
                            HStack {
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Log Out")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(FitCompColors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Delete Account Button
                        Button(action: onDeleteAccount) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete Account")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isDeletingAccount)
                    }
                    .padding(.horizontal, horizontalContentPadding)
                    .padding(.top, 16)
                    
                    // Fun Footer
                    FunFooter()
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                }
            }
        }
        .background(FitCompColors.surface)
    }
}
