//
//  GoalCelebrationView.swift
//  StepComp
//
//  Duolingo-style celebration when user hits their daily step goal
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct GoalCelebrationView: View {
    let steps: Int
    let goal: Int
    let onDismiss: () -> Void
    
    @State private var cardScale: CGFloat = 0.3
    @State private var cardRotationY: Double = 0  // Y-axis rotation for 3D effect
    @State private var cardOffset: CGFloat = 0
    @State private var showConfetti = false
    @State private var confettiTrigger = 0
    @State private var pulseAnimation = false
    @State private var numberScale: CGFloat = 1.0
    @State private var numberOpacity: Double = 0
    
    // Floating decorative elements
    @State private var floatingStars: [(x: CGFloat, y: CGFloat, rotation: Double)] = []
    @State private var floatingCircles: [(x: CGFloat, y: CGFloat, color: Color)] = []
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Semi-transparent background with blur
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // Confetti layer (in front of card via z-index)
            if showConfetti {
                DuolingoConfettiView(trigger: confettiTrigger)
                    .allowsHitTesting(false)
                    .zIndex(10) // Above everything
            }
            
            // Floating decorative elements
            ForEach(floatingStars.indices, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(floatingStars[index].rotation))
                    .position(x: floatingStars[index].x, y: floatingStars[index].y)
                    .opacity(0.6)
                    .zIndex(4)
            }
            
            ForEach(floatingCircles.indices, id: \.self) { index in
                Circle()
                    .fill(floatingCircles[index].color)
                    .frame(width: 12, height: 12)
                    .position(x: floatingCircles[index].x, y: floatingCircles[index].y)
                    .opacity(0.5)
                    .zIndex(4)
            }
            
            // Compact glassmorphic celebration card
            VStack(spacing: 16) {
                // Trophy icon with glow (compact)
                ZStack {
                    // Pulsing glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(0.6),
                                    Color.yellow.opacity(0)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.9)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                    
                    // Trophy circle background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.yellow.opacity(0.6), radius: 12, x: 0, y: 6)
                    
                    // Trophy icon
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Small sparkle star (top right)
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .offset(x: 24, y: -20)
                }
                .padding(.top, 4)
                
                // Title with 3D raised effect (compact)
                Text("Goal\nAchieved!")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-6)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 3)
                    .shadow(color: Color.white.opacity(0.2), radius: 1, x: 0, y: -1)
                
                // Subtitle with raised effect (compact)
                Text("You've absolutely crushed it today.\nKeep up the momentum!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 2)
                
                // Floating steps number (no box!)
                VStack(spacing: 4) {
                    Text("TOTAL STEPS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.4))
                        .tracking(1.2)
                    
                    HStack(spacing: 8) {
                        // Animated number (floating, no box)
                        Text(formatNumber(steps))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .scaleEffect(numberScale)
                            .opacity(numberOpacity)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                        
                        // Green checkmark
                        Circle()
                            .fill(Color.green)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color.green.opacity(0.5), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.vertical, 8)
                
                // Continue button with 3D effect (compact)
                Button(action: {
                    dismissWithAnimation()
                }) {
                    Text("Awesome, continue!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.yellow.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                // Themed glassmorphic background
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        colorScheme == .dark
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.2, blue: 0.35).opacity(0.95),
                                    Color(red: 0.1, green: 0.15, blue: 0.25).opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.98, blue: 1.0).opacity(0.95),
                                    Color(red: 0.95, green: 0.96, blue: 0.98).opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.2)
                                    : Color.black.opacity(0.1),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 25, x: 0, y: 12)
            )
            .frame(maxWidth: 240)  // 1/3 of original size (was 360)
            .padding(.horizontal, 32)
            .scaleEffect(cardScale)
            .rotation3DEffect(
                .degrees(cardRotationY),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                perspective: 0.5
            )
            .offset(y: cardOffset)
            .zIndex(5) // Below confetti but above background
            .onTapGesture {
                // Spin and trigger confetti on tap
                triggerSpinAndConfetti()
            }
        }
        .onAppear {
            startCelebration()
            generateFloatingElements()
            animateNumbers()
        }
    }
    
    // MARK: - Animations
    
    private func startCelebration() {
        // Start pulse animation
        pulseAnimation = true
        
        // Haptic feedback
        HapticManager.shared.achievement()
        
        // Trigger full-screen fireworks effect (iMessage-style)
        ReactionEffectManager.shared.trigger(.fireworks)
        
        // Bounce in animation (Duolingo style)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
            cardScale = 1.0
        }
        
        // Add a little overshoot bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                cardOffset = -10
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                cardOffset = 0
            }
        }
        
        // Show confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showConfetti = true
            confettiTrigger += 1
        }
    }
    
    private func animateNumbers() {
        // Fade in and scale animation for numbers
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
            numberOpacity = 1.0
        }
        
        // Bouncy scale effect
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.6)) {
            numberScale = 1.15
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.8)) {
            numberScale = 1.0
        }
    }
    
    private func generateFloatingElements() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Generate floating stars
        floatingStars = (0..<5).map { _ in
            (
                x: CGFloat.random(in: 40...(screenWidth - 40)),
                y: CGFloat.random(in: 100...(screenHeight - 200)),
                rotation: Double.random(in: 0...360)
            )
        }
        
        // Generate floating circles
        floatingCircles = (0..<8).map { _ in
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
            return (
                x: CGFloat.random(in: 40...(screenWidth - 40)),
                y: CGFloat.random(in: 100...(screenHeight - 200)),
                color: colors.randomElement() ?? .yellow
            )
        }
        
        // Animate floating elements
        animateFloatingElements()
    }
    
    private func animateFloatingElements() {
        // Animate stars rotation
        for index in floatingStars.indices {
            withAnimation(
                .linear(duration: Double.random(in: 3...6))
                .repeatForever(autoreverses: false)
                .delay(Double.random(in: 0...1))
            ) {
                floatingStars[index].rotation += 360
            }
        }
    }
    
    private func triggerSpinAndConfetti() {
        HapticManager.shared.success()
        
        // 360 degree 3D spin on Y-axis
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            cardRotationY += 360
        }
        
        // Trigger new confetti burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            confettiTrigger += 1
        }
        
        // Re-animate numbers
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            numberScale = 1.2
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
            numberScale = 1.0
        }
    }
    
    private func dismissWithAnimation() {
        HapticManager.shared.soft()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            cardScale = 0.8
            cardOffset = 20
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Duolingo-Style Confetti

struct DuolingoConfettiView: View {
    let trigger: Int
    @State private var pieces: [DuolingoConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    DuolingoConfettiPieceView(piece: piece)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: trigger) { _, _ in
                generateConfetti(in: geometry.size)
            }
        }
    }
    
    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink,
            StepCompColors.primary, StepCompColors.accent, StepCompColors.cyan
        ]
        
        let emojis = ["🎉", "⭐️", "💪", "🔥", "✨", "🏆", "👏", "🎊"]
        
        // Center point
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Create 50 confetti pieces from center with radial spread
        let newPieces = (0..<50).map { i -> DuolingoConfettiPiece in
            // Calculate random angle and distance for radial explosion
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 50...150)
            
            // Calculate spread velocity (how far from center they start)
            let spreadX = cos(angle) * distance
            let spreadY = sin(angle) * distance
            
            return DuolingoConfettiPiece(
                id: UUID().uuidString + "\(trigger)-\(i)",
                x: centerX + spreadX,
                startY: centerY + spreadY,
                color: colors.randomElement() ?? .yellow,
                emoji: emojis.randomElement() ?? "🎉",
                size: CGFloat.random(in: 12...24),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.2),
                duration: Double.random(in: 2.5...4.0),
                isEmoji: Bool.random()
            )
        }
        
        pieces.append(contentsOf: newPieces)
        
        // Remove old pieces after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            pieces.removeAll { piece in
                newPieces.contains { $0.id == piece.id }
            }
        }
    }
}

struct DuolingoConfettiPiece: Identifiable {
    let id: String
    let x: CGFloat
    let startY: CGFloat
    let color: Color
    let emoji: String
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let isEmoji: Bool
}

struct DuolingoConfettiPieceView: View {
    let piece: DuolingoConfettiPiece
    @State private var yPosition: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Group {
            if piece.isEmoji {
                Text(piece.emoji)
                    .font(.system(size: piece.size))
            } else {
                // Geometric shape
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
            }
        }
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .position(x: piece.x, y: piece.startY + yPosition)
        .onAppear {
            withAnimation(
                .easeIn(duration: piece.duration)
                .delay(piece.delay)
            ) {
                yPosition = UIScreen.main.bounds.height + 100
                opacity = 0
            }
            
            withAnimation(
                .linear(duration: piece.duration)
                .repeatCount(10, autoreverses: false)
                .delay(piece.delay)
            ) {
                rotation = piece.rotation + 1080 // 3 full rotations
            }
        }
    }
}

// MARK: - Celebration Manager (unchanged)

final class GoalCelebrationManager: ObservableObject {
    static let shared = GoalCelebrationManager()
    
    @Published var shouldShowCelebration = false
    @Published var celebrationSteps: Int = 0
    @Published var celebrationGoal: Int = 10000
    
    private init() {}
    
    // Check if celebration should trigger (must be called from main thread)
    @MainActor
    func checkForCelebration(previousSteps: Int, currentSteps: Int, dailyGoal: Int) {
        let today = todayKey()
        let alreadyCelebrated = UserDefaults.standard.bool(forKey: "goalCelebrated_\(today)")
        
        print("🎊 Celebration Check:")
        print("  - Previous steps: \(previousSteps)")
        print("  - Current steps: \(currentSteps)")
        print("  - Daily goal: \(dailyGoal)")
        print("  - Already celebrated today: \(alreadyCelebrated)")
        print("  - Condition 1 (prev < goal): \(previousSteps < dailyGoal)")
        print("  - Condition 2 (current >= goal): \(currentSteps >= dailyGoal)")
        print("  - Condition 3 (not celebrated): \(!alreadyCelebrated)")
        
        // Only celebrate if:
        // 1. Previous steps were below goal
        // 2. Current steps are at or above goal
        // 3. Haven't celebrated today yet
        if previousSteps < dailyGoal && currentSteps >= dailyGoal && !alreadyCelebrated {
            celebrationSteps = currentSteps
            celebrationGoal = dailyGoal
            shouldShowCelebration = true
            
            // Mark as celebrated
            UserDefaults.standard.set(true, forKey: "goalCelebrated_\(today)")
            
            // Trigger haptic feedback
            HapticManager.shared.achievement()
            
            print("🎉 Goal celebration triggered: \(currentSteps)/\(dailyGoal) steps")
        } else {
            print("⚠️ Celebration NOT triggered")
        }
    }
    
    @MainActor
    func dismissCelebration() {
        shouldShowCelebration = false
    }
    
    // Force trigger celebration (for testing or manual trigger)
    @MainActor
    func forceTriggerCelebration(steps: Int, goal: Int) {
        celebrationSteps = steps
        celebrationGoal = goal
        shouldShowCelebration = true
        HapticManager.shared.achievement()
        print("🎉 Celebration FORCE triggered: \(steps)/\(goal) steps")
    }
    
    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // Reset for testing
    #if DEBUG
    @MainActor
    func resetTodaysCelebration() {
        let today = todayKey()
        UserDefaults.standard.removeObject(forKey: "goalCelebrated_\(today)")
        print("🔄 Reset today's celebration flag")
    }
    #endif
}

// MARK: - Preview

#Preview {
    GoalCelebrationView(
        steps: 10500,
        goal: 10000,
        onDismiss: {}
    )
}
