//
//  MainTabView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

class TabSelectionManager: ObservableObject {
    @Published var selectedTab: Int = 0
    
    func switchToCreateTab() {
        selectedTab = 1
    }
}

struct MainTabView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @StateObject private var tabManager = TabSelectionManager()
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            HomeDashboardView(sessionViewModel: sessionViewModel, tabManager: tabManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ChallengesView(sessionViewModel: sessionViewModel)
                .tabItem {
                    Label("Challenges", systemImage: "trophy.fill")
                }
                .tag(1)

            MetricsView(sessionViewModel: sessionViewModel)
                .tabItem {
                    Label("Metrics", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView(sessionViewModel: sessionViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .onAppear {
            setupTabBarAppearance(for: colorScheme)
        }
        .onChange(of: colorScheme) { oldValue, newValue in
            setupTabBarAppearance(for: newValue)
        }
        .onChange(of: tabManager.selectedTab) { oldValue, newValue in
            // Haptic feedback on tab switch
            HapticManager.shared.soft()
        }
        .environmentObject(tabManager)
    }
    
    private func setupTabBarAppearance(for colorScheme: ColorScheme) {
        #if os(iOS)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Use colorScheme parameter instead of UITraitCollection
        let isDarkMode = (colorScheme == .dark)
        
        if isDarkMode {
            // Dark mode: Dark blue background, coral accent
            appearance.backgroundColor = UIColor(red: 0.15, green: 0.19, blue: 0.26, alpha: 1.0)
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.3)
            
            // Coral selected color
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 1.0, green: 0.42, blue: 0.36, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 1.0, green: 0.42, blue: 0.36, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
            
            // Muted unselected
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.50, green: 0.54, blue: 0.60, alpha: 1.0)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.50, green: 0.54, blue: 0.60, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 11, weight: .medium)
            ]
        } else {
            // Light mode: Light background, blue accent
            appearance.backgroundColor = UIColor.systemBackground
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            
            // Blue selected color
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
            
            // Gray unselected
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray,
                .font: UIFont.systemFont(ofSize: 11, weight: .medium)
            ]
        }
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        #endif
    }
}

