//
//  ChallengeCelebrationView.swift
//  FitComp
//
//  Full-screen celebration when challenge completes
//

import SwiftUI

struct ChallengeCelebrationView: View {
    let winner: LeaderboardEntry
    let challengeName: String
    let totalParticipants: Int
    let onDismiss: () -> Void
    let onViewSummary: () -> Void
    
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showButtons = false
    
    private let gradientEnd = Color(red: 0.902, green: 0.761, blue: 0.0)
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.08, blue: 0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Confetti layer
            if showConfetti {
                ChallengeConfettiView()
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Challenge Complete Title
                VStack(spacing: 8) {
                    Text("Challenge Complete!")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    Text(challengeName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(opacity)
                }
                .padding(.bottom, 32)
                
                // Winner's Expanded Card
                ZStack {
                    // Glow effect
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [FitCompColors.primary, gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 40)
                        .scaleEffect(1.1)
                    
                    // Main card
                    VStack(spacing: 24) {
                        // Crown
                        Text("👑")
                            .font(.system(size: 80))
                        
                        // Winner avatar
                        AvatarView(
                            displayName: winner.displayName,
                            avatarURL: winner.avatarURL,
                            size: 140
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 6)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        
                        // Winner info
                        VStack(spacing: 8) {
                            Text(winner.displayName)
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.black)
                            
                            Text("\(winner.steps.formatted()) steps")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        
                        // Winner badge
                        HStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 16))
                            Text("1st Place Winner")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(20)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [FitCompColors.primary, gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action Buttons
                if showButtons {
                    VStack(spacing: 16) {
                        // View Summary Button
                        Button(action: onViewSummary) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                Text("View Summary")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FitCompColors.primary)
                            .cornerRadius(16)
                        }
                        
                        // Dismiss Button
                        Button(action: onDismiss) {
                            Text("Close")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Animate entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Show confetti after slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
            
            // Show buttons after card animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showButtons = true
                }
            }
        }
    }
}

// MARK: - Challenge Confetti View (unique name to avoid conflict with GoalCelebrationView)

struct ChallengeConfettiView: View {
    @State private var confettiPieces: [ChallengeConfettiPiece] = []
    
    private let colors: [Color] = [
        FitCompColors.primary, // Yellow
        Color.orange,
        Color.red,
        Color.blue,
        Color.green,
        Color.purple
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ChallengeConfettiPieceView(piece: piece, geometry: geometry)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        for _ in 0..<100 {
            confettiPieces.append(ChallengeConfettiPiece(colors: colors))
        }
    }
}

struct ChallengeConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    
    init(colors: [Color]) {
        self.color = colors.randomElement() ?? .yellow
        self.x = CGFloat.random(in: -50...50)
        self.y = CGFloat.random(in: -20...10)
        self.rotation = Double.random(in: 0...360)
        self.scale = CGFloat.random(in: 0.5...1.5)
    }
}

struct ChallengeConfettiPieceView: View {
    let piece: ChallengeConfettiPiece
    let geometry: GeometryProxy
    
    @State private var animate = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
            .scaleEffect(piece.scale)
            .offset(
                x: animate ? piece.x * 4 : piece.x,
                y: animate ? geometry.size.height + 100 : piece.y
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(
                    .linear(duration: Double.random(in: 2...4))
                    .delay(Double.random(in: 0...0.5))
                ) {
                    animate = true
                }
            }
    }
}

#Preview {
    ChallengeCelebrationView(
        winner: LeaderboardEntry(
            userId: "1",
            challengeId: "1",
            displayName: "Sarah Johnson",
            steps: 15240,
            rank: 1
        ),
        challengeName: "New Year Sprint",
        totalParticipants: 12,
        onDismiss: {},
        onViewSummary: {}
    )
}
