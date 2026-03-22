//
//  PlatformColors.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

enum PlatformColor {
    static var cardBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    static var secondaryBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    static var subtleFill: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray6)
        #elseif canImport(AppKit)
        return Color.gray.opacity(0.12)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }
    
    static var systemGray5: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray5)
        #elseif canImport(AppKit)
        return Color.gray.opacity(0.2)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
    
    static var systemGray4: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray4)
        #elseif canImport(AppKit)
        return Color.gray.opacity(0.3)
        #else
        return Color.gray.opacity(0.3)
        #endif
    }
}

