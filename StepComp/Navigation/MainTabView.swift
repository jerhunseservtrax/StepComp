//
//  MainTabView.swift
//  StepComp
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
        selectedTab = 2
    }
}

struct MainTabView: View {
    @StateObject private var sessionViewModel: SessionViewModel
    @StateObject private var tabManager = TabSelectionManager()
    
    init(sessionViewModel: SessionViewModel) {
        _sessionViewModel = StateObject(wrappedValue: sessionViewModel)
    }
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            HomeDashboardView(sessionViewModel: sessionViewModel, tabManager: tabManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            FriendsView(sessionViewModel: sessionViewModel)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(1)
            
            ChallengesView(sessionViewModel: sessionViewModel)
                .tabItem {
                    Label("Challenges", systemImage: "trophy.fill")
                }
                .tag(2)
            
            SettingsView(sessionViewModel: sessionViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(primaryYellow)
        .onAppear {
            setupTabBarAppearance()
        }
        .environmentObject(tabManager)
    }
    
    private func setupTabBarAppearance() {
        #if os(iOS)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Set selected item color to yellow
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(primaryYellow)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(primaryYellow)
        ]
        
        // Set unselected item color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // Apply to all tab bar instances
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        #endif
    }
}

