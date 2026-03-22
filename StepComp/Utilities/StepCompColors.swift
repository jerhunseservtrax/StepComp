//
//  FitCompColors.swift
//  FitComp
//
//  Adaptive color system for FitComp (supports dark & light mode)
//

import SwiftUI

// MARK: - Color Extension for Adaptive Colors

extension Color {
    /// Creates a color that adapts to light and dark mode
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light:
                return UIColor(light)
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(dark) // Default to dark for reference UI
            }
        })
    }
}

enum FitCompColors {
    // MARK: - Adaptive Backgrounds
    /// Main background - adapts to light/dark mode
    static let background = Color(
        light: Color(red: 0.95, green: 0.96, blue: 0.98),  // Light gray #F2F4F9
        dark: Color(red: 0.10, green: 0.14, blue: 0.20)     // Deep dark blue #1A2332
    )
    
    /// Surface/Card background - adapts to light/dark mode
    static let surface = Color(
        light: Color.white,
        dark: Color(red: 0.15, green: 0.19, blue: 0.26)     // Card bg #253342
    )
    
    /// Elevated surface - adapts to light/dark mode
    static let surfaceElevated = Color(
        light: Color(red: 0.98, green: 0.98, blue: 1.0),    // Very light blue-white
        dark: Color(red: 0.18, green: 0.23, blue: 0.31)     // Elevated cards #2E3B4F
    )
    
    // MARK: - Primary Colors (Yellow-first brand system)
    static let primary = Color(
        light: Color(red: 0.98, green: 0.80, blue: 0.08),      // Brand yellow #FACC15
        dark: Color(red: 0.92, green: 0.70, blue: 0.03)        // Amber yellow #EAB308
    )
    
    static let accent = Color(
        light: Color(red: 0.96, green: 0.64, blue: 0.04),      // Orange accent #F59E0B
        dark: Color(red: 0.99, green: 0.76, blue: 0.20)        // Warm yellow #FDC233
    )
    
    // Fixed colors (don't change with theme)
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.36)         // Always coral #FF6B5C
    static let yellow = Color(red: 0.98, green: 0.80, blue: 0.08)       // True yellow
    static let primaryYellow = Color(red: 0.98, green: 0.80, blue: 0.08)
    
    // MARK: - Adaptive Text Colors
    static let textPrimary = Color(
        light: Color(red: 0.15, green: 0.15, blue: 0.15),   // Dark gray (almost black)
        dark: Color.white
    )
    
    static let textSecondary = Color(
        light: Color(red: 0.40, green: 0.40, blue: 0.45),   // Medium gray
        dark: Color(red: 0.70, green: 0.74, blue: 0.80)     // Muted blue-gray
    )
    
    static let textTertiary = Color(
        light: Color(red: 0.60, green: 0.60, blue: 0.65),   // Light gray
        dark: Color(red: 0.50, green: 0.54, blue: 0.60)     // Darker muted
    )
    
    /// Text color for buttons on primary color backgrounds
    /// Black on yellow (light mode), white on coral (dark mode)
    static let buttonTextOnPrimary = Color(
        light: Color.black,
        dark: Color.white
    )
    
    // MARK: - Accent Colors (Same in both modes)
    static let cyan = Color(red: 0.40, green: 0.76, blue: 0.84)         // Chart cyan #66C2D6
    static let purple = Color(red: 0.67, green: 0.51, blue: 0.85)       // Chart purple #AB82D9
    static let green = Color(red: 0.48, green: 0.82, blue: 0.64)        // Success green #7AD1A3
    static let orange = Color(red: 1.0, green: 0.42, blue: 0.36)        // Same as primary coral
    
    // MARK: - Status Colors
    static let success = green
    static let warning = accent
    static let error = Color(red: 1.0, green: 0.42, blue: 0.36)         // Coral red
    
    // MARK: - Gradients
    
    /// Yellow gradient (brand primary)
    static let yellowGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.80, blue: 0.08),  // #FACC15
            Color(red: 0.96, green: 0.64, blue: 0.04)   // #F59E0B
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Coral gradient (for dark mode buttons/elements)
    static let coralGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.42, blue: 0.36),  // Coral
            Color(red: 1.0, green: 0.52, blue: 0.46)   // Lighter coral
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Adaptive primary gradient - yellow-toned in both modes
    /// Usage: In your view, use @Environment(\.colorScheme) and call primaryGradient(for:)
    static func primaryGradient(for colorScheme: ColorScheme) -> LinearGradient {
        colorScheme == .dark ? yellowGradient : yellowGradient
    }
    
    /// Adaptive progress gradient - yellow-toned in both modes
    static func progressGradient(for colorScheme: ColorScheme) -> LinearGradient {
        colorScheme == .dark ? yellowGradient : yellowGradient
    }
    
    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 0.90, green: 0.70, blue: 0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.14, blue: 0.20),  // Deep dark blue
            Color(red: 0.12, green: 0.16, blue: 0.23)   // Slightly lighter
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let surfaceGradient = LinearGradient(
        colors: [surfaceElevated, surface],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Chart/Progress Gradients (Never flat!)
    
    /// Cyan to blue gradient (for step metrics)
    static let cyanGradient = LinearGradient(
        colors: [
            Color(red: 0.40, green: 0.76, blue: 0.84),  // Cyan
            Color(red: 0.50, green: 0.83, blue: 0.90)   // Lighter cyan
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Purple gradient (for challenges)
    static let purpleGradient = LinearGradient(
        colors: [
            Color(red: 0.67, green: 0.51, blue: 0.85),  // Purple
            Color(red: 0.77, green: 0.61, blue: 0.92)   // Lighter purple
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Green gradient (for success/goals)
    static let greenGradient = LinearGradient(
        colors: [
            Color(red: 0.48, green: 0.82, blue: 0.64),  // Green
            Color(red: 0.58, green: 0.90, blue: 0.74)   // Lighter green
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Angular gradient for circular progress (better visual)
    static let circularProgressGradient = AngularGradient(
        colors: [
            Color(red: 0.98, green: 0.80, blue: 0.08),  // Yellow
            Color(red: 0.96, green: 0.64, blue: 0.04),  // Amber
            Color(red: 0.99, green: 0.76, blue: 0.20),  // Warm yellow
            Color(red: 0.98, green: 0.80, blue: 0.08)   // Back to yellow
        ],
        center: .center,
        startAngle: .degrees(0),
        endAngle: .degrees(360)
    )
    
    // MARK: - Semantic Colors (Adaptive)
    static let cardBackground = surface
    
    static let cardBorder = Color(
        light: Color.black.opacity(0.1),                    // Light subtle border
        dark: Color(red: 0.20, green: 0.25, blue: 0.32).opacity(0.5) // Dark subtle border
    )
    
    static let divider = Color(
        light: Color.black.opacity(0.15),                   // Light divider
        dark: Color(red: 0.25, green: 0.30, blue: 0.38)     // Dark visible divider
    )
    
    static let overlay = Color.black.opacity(0.5)
    
    // MARK: - Shadow Colors (Adaptive)
    static let shadowPrimary = Color.black.opacity(0.4)
    static let shadowSecondary = Color(
        light: Color.black.opacity(0.15),                   // Lighter shadows in light mode
        dark: Color.black.opacity(0.2)                      // Darker shadows in dark mode
    )
}

// MARK: - Color Extensions

extension Color {
    static let stepBackground = FitCompColors.background
    static let stepSurface = FitCompColors.surface
    static let stepPrimary = FitCompColors.primary
    static let stepAccent = FitCompColors.accent
    static let stepTextPrimary = FitCompColors.textPrimary
    static let stepTextSecondary = FitCompColors.textSecondary
}

