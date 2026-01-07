//
//  ThemeManager.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme?
    
    private let userDefaultsKey = "appColorScheme"
    
    init() {
        loadColorScheme()
    }
    
    func setColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        saveColorScheme()
    }
    
    func toggleDarkMode() {
        switch colorScheme {
        case .dark:
            setColorScheme(.light)
        case .light:
            setColorScheme(.dark)
        case .none:
            // If system, toggle to dark
            setColorScheme(.dark)
        @unknown default:
            setColorScheme(.dark)
        }
    }
    
    var isDarkMode: Bool {
        get {
            switch colorScheme {
            case .dark:
                return true
            case .light:
                return false
            case .none:
                // Use system setting
                #if os(iOS)
                return UITraitCollection.current.userInterfaceStyle == .dark
                #else
                return false
                #endif
            @unknown default:
                return false
            }
        }
        set {
            setColorScheme(newValue ? .dark : .light)
        }
    }
    
    private func saveColorScheme() {
        let value: String?
        switch colorScheme {
        case .dark:
            value = "dark"
        case .light:
            value = "light"
        case .none:
            value = "system"
        @unknown default:
            value = "system"
        }
        UserDefaults.standard.set(value, forKey: userDefaultsKey)
    }
    
    private func loadColorScheme() {
        guard let value = UserDefaults.standard.string(forKey: userDefaultsKey) else {
            // On first launch, default to dark mode (matching reference UI)
            colorScheme = .dark
            saveColorScheme() // Save the default
            return
        }
        
        switch value {
        case "dark":
            colorScheme = .dark
        case "light":
            colorScheme = .light
        case "system":
            colorScheme = nil
        default:
            colorScheme = .dark // Default to dark to match reference UI
        }
    }
}

