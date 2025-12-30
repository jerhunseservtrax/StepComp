//
//  Extensions.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Date {
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

extension View {
    func iPadAdaptivePadding() -> some View {
        #if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return AnyView(self.padding(.horizontal, 40))
        } else {
            return AnyView(self.padding(.horizontal, 20))
        }
        #else
        return AnyView(self.padding(.horizontal, 20))
        #endif
    }
}

