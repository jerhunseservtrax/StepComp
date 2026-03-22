//
//  FitCompCardStyles.swift
//  FitComp
//
//  Modern card styling matching reference UI
//

import SwiftUI

// MARK: - Dark Card Style

struct DarkCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20
    var showShadow: Bool = true
    
    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        showShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(FitCompColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(FitCompColors.cardBorder, lineWidth: 1)
                    )
            )
            .shadow(
                color: showShadow ? FitCompColors.shadowPrimary : .clear,
                radius: 20,
                y: 10
            )
    }
}

// MARK: - Elevated Card Style

struct ElevatedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20
    
    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(FitCompColors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: FitCompColors.shadowSecondary, radius: 15, y: 8)
    }
}

// MARK: - Gradient Card Style

struct GradientCard<Content: View>: View {
    let content: Content
    let gradient: LinearGradient
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20
    
    init(
        gradient: LinearGradient = FitCompColors.coralGradient,
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
            )
            .shadow(color: FitCompColors.primary.opacity(0.4), radius: 20, y: 10)
    }
}

// MARK: - Glass Card Style (Frosted glass effect)

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20
    
    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.08))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - View Modifiers

struct DarkCardModifier: ViewModifier {
    var padding: CGFloat
    var cornerRadius: CGFloat
    var showShadow: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(FitCompColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(FitCompColors.cardBorder, lineWidth: 1)
                    )
            )
            .shadow(
                color: showShadow ? FitCompColors.shadowPrimary : .clear,
                radius: 20,
                y: 10
            )
    }
}

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.08))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

extension View {
    func darkCard(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        showShadow: Bool = true
    ) -> some View {
        self.modifier(DarkCardModifier(
            padding: padding,
            cornerRadius: cornerRadius,
            showShadow: showShadow
        ))
    }
    
    func glassCard(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20
    ) -> some View {
        self.modifier(GlassCardModifier(
            padding: padding,
            cornerRadius: cornerRadius
        ))
    }
}

