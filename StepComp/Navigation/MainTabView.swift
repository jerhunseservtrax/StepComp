//
//  MainTabView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

class TabSelectionManager: ObservableObject {
    @Published var selectedTab: Int = 0
    
    func switchToCreateTab() {
        selectedTab = 2
    }
}

struct MainTabView: View {
    @StateObject private var sessionViewModel: SessionViewModel
    @StateObject private var tabManager = TabSelectionManager()
    @State private var dragStartLocation: CGPoint = .zero
    
    init(sessionViewModel: SessionViewModel) {
        _sessionViewModel = StateObject(wrappedValue: sessionViewModel)
    }
    
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
            
            ProfileView(sessionViewModel: sessionViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .environmentObject(tabManager)
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    dragStartLocation = value.startLocation
                }
                .onEnded { value in
                    handleSwipe(value: value)
                }
        )
    }
    
    private func handleSwipe(value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        
        // Only handle horizontal swipes (more horizontal than vertical, and significant movement)
        // Require at least 80 points of horizontal movement to avoid conflicts with scrolling
        guard abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 80 else {
            return
        }
        
        #if canImport(UIKit)
        // Check if swipe started near the edge (within 50 points from left/right edge)
        // This helps avoid conflicts with content scrolling
        // Use a reasonable default screen width if UIScreen is not available
        let screenWidth: CGFloat = 390 // Default iPhone width, will be adjusted by actual gesture
        let startX = dragStartLocation.x
        let isNearEdge = startX < 50 || startX > screenWidth - 50
        
        // Only trigger if swipe is significant and started near edge or is very horizontal
        if abs(horizontalAmount) > 100 || isNearEdge {
            if horizontalAmount > 0 {
                // Swipe right - go to previous tab
                if tabManager.selectedTab > 0 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        tabManager.selectedTab -= 1
                    }
                }
            } else {
                // Swipe left - go to next tab
                if tabManager.selectedTab < 3 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        tabManager.selectedTab += 1
                    }
                }
            }
        }
        #else
        // Fallback for non-iOS platforms
        if abs(horizontalAmount) > 100 {
            if horizontalAmount > 0 {
                if tabManager.selectedTab > 0 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        tabManager.selectedTab -= 1
                    }
                }
            } else {
                if tabManager.selectedTab < 3 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        tabManager.selectedTab += 1
                    }
                }
            }
        }
        #endif
    }
}

