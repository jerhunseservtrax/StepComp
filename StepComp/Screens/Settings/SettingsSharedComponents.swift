//
//  SettingsSharedComponents.swift
//  FitComp
//
//  Shared settings UI primitives extracted from SettingsView.swift.
//

import SwiftUI

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
            }
            
            // Content
            content()
        }
        .padding(24)
        .background(FitCompColors.surface)
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(FitCompColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Setting Item Row

struct SettingItemRow<Trailing: View>: View {
    enum RowLayout {
        case inline
        case stacked
    }
    
    let icon: String
    var iconBackground: Color = Color(.systemGray6)
    let title: String
    var subtitle: String? = nil
    var layout: RowLayout = .inline
    @ViewBuilder let trailing: () -> Trailing
    
    var body: some View {
        Group {
            if layout == .stacked {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        iconView
                        
                        labels
                        
                        Spacer(minLength: 0)
                    }
                    
                    trailing()
                }
            } else {
                HStack(spacing: 12) {
                    iconView
                    
                    labels
                    
                    Spacer(minLength: 4)
                    
                    trailing()
                        .flexibleFrame(minWidth: 50)
                        .layoutPriority(2)
                }
            }
        }
        .padding(8)
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconBackground)
                .frame(width: 40, height: 40)
            
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconBackground == Color.black ? .white : .primary)
        }
        .flexibleFrame(minWidth: 40)
    }
    
    private var labels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
        }
        .layoutPriority(1)
    }
}

// Helper extension for flexible frames
extension View {
    func flexibleFrame(minWidth: CGFloat) -> some View {
        self.frame(minWidth: minWidth)
    }
}

// MARK: - Fun Footer

struct FunFooter: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.hiking")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("Keep Moving")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
        }
        .opacity(0.5)
        .onAppear {
            isAnimating = true
        }
    }
}
