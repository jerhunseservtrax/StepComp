//
//  SplashScreenView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct SplashScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var progress: Double = 0.0
    @State private var currentMessage: String = "Lacing up..."
    @State private var nextMessage: String = "Stretching muscles..."
    @State private var isComplete: Bool = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024) // #f9f506
    private let backgroundLight = Color(red: 0.973, green: 0.973, blue: 0.961) // #f8f8f5
    private let backgroundDark = Color(red: 0.137, green: 0.133, blue: 0.059) // #23220f
    private let progressBgLight = Color(red: 0.914, green: 0.910, blue: 0.808) // #e9e8ce
    private let progressBgDark = Color(red: 0.243, green: 0.239, blue: 0.141) // #3e3d24
    private let textColorLight = Color(red: 0.110, green: 0.110, blue: 0.051) // #1c1c0d
    private let textColorDark = Color(red: 0.973, green: 0.973, blue: 0.961) // #f8f8f5
    private let subtitleColorLight = Color(red: 0.620, green: 0.616, blue: 0.278) // #9e9d47
    private let subtitleColorDark = Color(red: 0.749, green: 0.745, blue: 0.337) // #bfbe56
    
    var backgroundColor: Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }
    
    var textColor: Color {
        colorScheme == .dark ? textColorDark : textColorLight
    }
    
    var subtitleColor: Color {
        colorScheme == .dark ? subtitleColorDark : subtitleColorLight
    }
    
    var progressBgColor: Color {
        colorScheme == .dark ? progressBgDark : progressBgLight
    }
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            // Decorative blur circles
            decorativeCircles
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and content
                VStack(spacing: 32) {
                    // Logo section
                    logoSection
                    
                    // Title and subtitle
                    titleSection
                    
                    // Progress section
                    progressSection
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer with version
                footerSection
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            startLoading()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            backgroundColor
            
            LinearGradient(
                colors: [
                    primaryYellow.opacity(colorScheme == .dark ? 0.05 : 0.1),
                    backgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Decorative Circles
    
    private var decorativeCircles: some View {
        ZStack {
            // Top right circle
            Circle()
                .fill(primaryYellow.opacity(0.2))
                .frame(width: 256, height: 256)
                .blur(radius: 60)
                .offset(x: 100, y: -100)
            
            // Bottom left circle
            Circle()
                .fill(primaryYellow.opacity(0.1))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -100, y: 200)
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(primaryYellow.opacity(0.6))
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .scaleEffect(0.95)
                .opacity(0.5)
            
            // Main circle with border
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 192, height: 192)
                
                // Shoe image
                AsyncImage(url: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBZH1fSQOXaJH8FQsIeYNuVfa0tw8D8x-vvhUyMu7NXTt21DYO7lmoALIdef4T-RIPydtUmikjr_h1LT7vRDXphDD4hb2VA4xFj7YM9pmCMkOkJ22D8jTk-bLzsPN1-8GAlxkYkbUS-GD_7EgpXD8JanBFZ6QHolhp0E5_yNZvsmu1uQ3liz0XF2of4fnXzqvvwUVTO-CONqIiIMjZHXYumc2fdfwsKRUbYz5Sr7mFyjruiYIODieMB37nuPapIUFMuMkjNEjONMQ")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(1.1)
                } placeholder: {
                    // Placeholder shoe icon
                    Image(systemName: "figure.walk")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
                .frame(width: 192, height: 192)
                .clipShape(Circle())
            }
            .overlay(
                Circle()
                    .stroke(backgroundColor, lineWidth: 8)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.2), radius: 20, x: 0, y: 10)
            
            // Floating status badge
            ZStack {
                Circle()
                    .fill(primaryYellow)
                    .frame(width: 48, height: 48)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            .overlay(
                Circle()
                    .stroke(backgroundColor, lineWidth: 4)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 8, x: 0, y: 4)
            .offset(x: 24, y: 24)
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 4) {
            Text("Step Comp")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .tracking(-0.5)
            
            Text("WALKING TRACKER")
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .tracking(2)
                .textCase(.uppercase)
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            // Progress header
            HStack {
                Text(currentMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(primaryYellow.opacity(0.2))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 4)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressBgColor)
                        .frame(height: 16)
                    
                    // Progress fill
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(primaryYellow)
                            .frame(width: geometry.size.width * progress, height: 16)
                        
                        // Stripe pattern overlay (diagonal stripes)
                        if progress > 0 {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color.white.opacity(0.5), location: 0),
                                            .init(color: Color.white.opacity(0.5), location: 0.125),
                                            .init(color: Color.clear, location: 0.125),
                                            .init(color: Color.clear, location: 0.25),
                                            .init(color: Color.white.opacity(0.5), location: 0.25),
                                            .init(color: Color.white.opacity(0.5), location: 0.375),
                                            .init(color: Color.clear, location: 0.375),
                                            .init(color: Color.clear, location: 0.5),
                                            .init(color: Color.white.opacity(0.5), location: 0.5),
                                            .init(color: Color.white.opacity(0.5), location: 0.625),
                                            .init(color: Color.clear, location: 0.625),
                                            .init(color: Color.clear, location: 0.75),
                                            .init(color: Color.white.opacity(0.5), location: 0.75),
                                            .init(color: Color.white.opacity(0.5), location: 0.875),
                                            .init(color: Color.clear, location: 0.875),
                                            .init(color: Color.clear, location: 1)
                                        ],
                                        startPoint: UnitPoint(x: 0, y: 0),
                                        endPoint: UnitPoint(x: 1, y: 1)
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 16)
                                .opacity(0.3)
                                .mask(
                                    RoundedRectangle(cornerRadius: 8)
                                        .frame(width: geometry.size.width * progress, height: 16)
                                )
                        }
                    }
                }
            }
            .frame(height: 16)
            
            // Next message
            Text(nextMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(subtitleColor)
                .padding(.top, 4)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text("v1.0.2")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            (colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
                .blur(radius: 10)
        )
        .cornerRadius(20)
    }
    
    
    // MARK: - Loading Logic
    
    private func startLoading() {
        // Simulate loading progress
        let duration: Double = 2.5 // Total loading time
        let steps = 100
        let stepDuration = duration / Double(steps)
        
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            withAnimation(.linear(duration: stepDuration)) {
                progress += 1.0 / Double(steps)
                
                // Update messages based on progress
                if progress >= 0.45 && currentMessage == "Lacing up..." {
                    currentMessage = "Lacing up..."
                } else if progress >= 0.7 {
                    currentMessage = "Stretching muscles..."
                    nextMessage = "Almost ready..."
                } else if progress >= 0.9 {
                    nextMessage = "Ready to go!"
                }
                
                if progress >= 1.0 {
                    timer.invalidate()
                    isComplete = true
                    // Small delay before transitioning
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView {
        print("Loading complete!")
    }
}

