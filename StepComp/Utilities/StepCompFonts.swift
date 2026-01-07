//
//  StepCompFonts.swift
//  StepComp
//
//  SF Pro Rounded typography system matching reference UI
//

import SwiftUI

extension Font {
    // MARK: - Display Fonts (Large headings - like "yendo" branding)
    static func stepDisplay() -> Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    static func stepDisplayMedium() -> Font {
        .system(size: 28, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Title Fonts (Card headers, section titles)
    static func stepTitle() -> Font {
        .system(size: 22, weight: .bold, design: .rounded)
    }
    
    static func stepTitleMedium() -> Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }
    
    static func stepTitleSmall() -> Font {
        .system(size: 16, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Body Fonts (Regular text)
    static func stepBody() -> Font {
        .system(size: 15, weight: .medium, design: .rounded)
    }
    
    static func stepBodyRegular() -> Font {
        .system(size: 15, weight: .regular, design: .rounded)
    }
    
    static func stepBodySmall() -> Font {
        .system(size: 13, weight: .regular, design: .rounded)
    }
    
    // MARK: - Caption/Label Fonts (Small labels like "Total Steps", "Deep")
    static func stepCaption() -> Font {
        .system(size: 12, weight: .regular, design: .rounded)
    }
    
    static func stepCaptionBold() -> Font {
        .system(size: 12, weight: .semibold, design: .rounded)
    }
    
    static func stepLabel() -> Font {
        .system(size: 11, weight: .medium, design: .rounded)
    }
    
    static func stepLabelSmall() -> Font {
        .system(size: 10, weight: .medium, design: .rounded)
    }
    
    // MARK: - Number/Stats Fonts (Like "400", "3h45m" from reference)
    /// Large numbers (like main step count "400")
    static func stepNumberLarge() -> Font {
        .system(size: 48, weight: .bold, design: .rounded).monospacedDigit()
    }
    
    /// Medium numbers (like stats in cards "3.0")
    static func stepNumber() -> Font {
        .system(size: 32, weight: .bold, design: .rounded).monospacedDigit()
    }
    
    /// Small numbers (like time values "3h45m")
    static func stepNumberMedium() -> Font {
        .system(size: 22, weight: .semibold, design: .rounded).monospacedDigit()
    }
    
    /// Tiny numbers (like graph labels)
    static func stepNumberSmall() -> Font {
        .system(size: 14, weight: .semibold, design: .rounded).monospacedDigit()
    }
}

// MARK: - Text Style Modifiers

extension View {
    func stepTextPrimary() -> some View {
        self.foregroundColor(StepCompColors.textPrimary)
    }
    
    func stepTextSecondary() -> some View {
        self.foregroundColor(StepCompColors.textSecondary)
    }
    
    func stepTextTertiary() -> some View {
        self.foregroundColor(StepCompColors.textTertiary)
    }
}

// MARK: - Typography Style Combinations

extension View {
    /// Apply heading style (bold, large, rounded)
    func headingStyle() -> some View {
        self
            .font(.stepTitle())
            .foregroundColor(StepCompColors.textPrimary)
    }
    
    /// Apply subheading style
    func subheadingStyle() -> some View {
        self
            .font(.stepTitleMedium())
            .foregroundColor(StepCompColors.textPrimary)
    }
    
    /// Apply body text style
    func bodyStyle() -> some View {
        self
            .font(.stepBody())
            .foregroundColor(StepCompColors.textSecondary)
    }
    
    /// Apply caption/label style (muted, smaller)
    func captionStyle() -> some View {
        self
            .font(.stepCaption())
            .foregroundColor(StepCompColors.textTertiary)
    }
    
    /// Apply large number/stat style
    func statStyle() -> some View {
        self
            .font(.stepNumber())
            .foregroundColor(StepCompColors.textPrimary)
    }
}

// MARK: - UIKit Font Override (for NavigationBar, TabBar, etc.)

#if os(iOS)
import UIKit

struct AppFontConfiguration {
    static func setupGlobalFonts() {
        // Navigation bar fonts
        let navigationBarTitleFont = UIFont.systemFont(ofSize: 20, weight: .semibold).rounded()
        let navigationBarLargeTitleFont = UIFont.systemFont(ofSize: 34, weight: .bold).rounded()
        
        UINavigationBar.appearance().titleTextAttributes = [
            .font: navigationBarTitleFont,
            .foregroundColor: UIColor.white
        ]
        
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: navigationBarLargeTitleFont,
            .foregroundColor: UIColor.white
        ]
        
        // Bar button items
        let barButtonFont = UIFont.systemFont(ofSize: 16, weight: .medium).rounded()
        UIBarButtonItem.appearance().setTitleTextAttributes([
            .font: barButtonFont
        ], for: .normal)
    }
}

extension UIFont {
    func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
#endif

