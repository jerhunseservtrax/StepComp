//
//  JoinChallengeView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct JoinChallengeView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @StateObject private var viewModel: JoinChallengeViewModel
    @EnvironmentObject var challengeService: ChallengeService
    
    @State private var inviteCode: String = ""
    @State private var selectedChallenge: Challenge?
    @State private var showingChallengeDetails = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let userId = sessionViewModel.currentUser?.id ?? ""
        _viewModel = StateObject(
            wrappedValue: JoinChallengeViewModel(
                challengeService: ChallengeService(),
                userId: userId
            )
        )
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Top Navigation (no back button needed in TabView)
                    TopNavigationBar(onBack: {})
                    
                    // Main Content
                    VStack(spacing: 24) {
                        // Header Text
                        VStack(spacing: 8) {
                            Text("Ready to Step Up?")
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("You've been invited by **Sarah** to join the fun!")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        .padding(.horizontal)
                        
                        // Hero Card
                        if let challenge = selectedChallenge ?? viewModel.availableChallenges.first {
                            ChallengeInviteCard(challenge: challenge)
                                .padding(.horizontal)
                        } else {
                            // Placeholder card
                            ChallengeInviteCard(challenge: createPlaceholderChallenge())
                                .padding(.horizontal)
                        }
                        
                        // Timer Section
                        CountdownTimerView(
                            startDate: selectedChallenge?.startDate ?? Date().addingTimeInterval(4 * 3600 + 22 * 60)
                        )
                        .padding(.horizontal)
                        
                        // Invite Code Input
                        InviteCodeInputView(inviteCode: $inviteCode)
                            .padding(.horizontal)
                        
                        // Action Buttons
                        ActionButtonsView(
                            onJoin: {
                                if let challenge = selectedChallenge ?? viewModel.availableChallenges.first {
                                    Task {
                                        await viewModel.joinChallenge(challenge)
                                    }
                                }
                            },
                            onScanQR: {
                                // Handle QR scan
                            }
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .frame(maxWidth: 500)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.updateService(challengeService)
        }
    }
    
    private func createPlaceholderChallenge() -> Challenge {
        Challenge(
            name: "Summer Beach Walk '24",
            description: "Join us for a fun summer challenge!",
            startDate: Date().addingTimeInterval(4 * 3600 + 22 * 60),
            endDate: Date().addingTimeInterval(7 * 24 * 3600),
            targetSteps: 10000,
            creatorId: "",
            participantIds: []
        )
    }
}

// MARK: - Top Navigation

struct TopNavigationBar: View {
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            // Back button hidden in TabView (onBack is empty closure)
            Spacer()
            
            Text("Join Challenge")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(
            Color(.systemBackground)
                .opacity(0.8)
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Challenge Invite Card

struct ChallengeInviteCard: View {
    let challenge: Challenge
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Section
            ZStack(alignment: .topTrailing) {
                // Placeholder gradient background
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Intensity Badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("High Intensity")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Color(UIColor.systemBackground)
                        .opacity(0.9)
                        .background(.ultraThinMaterial)
                )
                .cornerRadius(999)
                .padding(12)
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Card Details
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.name)
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Level 3 • \(challenge.targetSteps.formatted()) Steps Goal")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(primaryYellow)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                Divider()
                    .background(PlatformColor.systemGray5)
                
                // Members Section
                HStack {
                    // Avatar stack
                    HStack(spacing: -12) {
                        let colors: [Color] = [.blue, .purple, .green]
                        let initials = ["JD", "AS", "MK"]
                        let maxAvatars = 3
                        ForEach(0..<min(maxAvatars, colors.count), id: \.self) { index in
                            Circle()
                                .fill(colors[index])
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(index < initials.count ? initials[index] : "")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemBackground), lineWidth: 2)
                                )
                        }
                        
                        Circle()
                            .fill(primaryYellow)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text("+8")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                    
                    Spacer()
                    
                    Text("\(challenge.participantIds.count + 8) Members active")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
    }
}

// MARK: - Countdown Timer

struct CountdownTimerView: View {
    let startDate: Date
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var hours: Int {
        Int(timeRemaining) / 3600
    }
    
    var minutes: Int {
        (Int(timeRemaining) % 3600) / 60
    }
    
    var seconds: Int {
        Int(timeRemaining) % 60
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Starting In")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
            
            HStack(spacing: 12) {
                TimerDigit(value: hours, label: "Hours")
                
                Text(":")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
                
                TimerDigit(value: minutes, label: "Minutes")
                
                Text(":")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
                
                TimerDigit(value: seconds, label: "Seconds", isHighlighted: true)
            }
        }
        .onAppear {
            updateTimeRemaining()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        if startDate > now {
            timeRemaining = startDate.timeIntervalSince(now)
        } else {
            timeRemaining = 0
        }
    }
}

struct TimerDigit: View {
    let value: Int
    let label: String
    var isHighlighted: Bool = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%02d", value))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(isHighlighted ? primaryYellow : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Invite Code Input

struct InviteCodeInputView: View {
    @Binding var inviteCode: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Have an invite code?")
                .font(.system(size: 14, weight: .bold))
                .padding(.leading, 16)
            
            HStack {
                TextField("X Y 7 - B 2", text: $inviteCode)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(PlatformColor.cardBackground)
                    .cornerRadius(999)
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(inviteCode.isEmpty ? Color.clear : primaryYellow, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                
                Button(action: {
                    // Handle paste
                    #if os(iOS)
                    if let clipboard = UIPasteboard.general.string {
                        inviteCode = clipboard
                    }
                    #endif
                }) {
                    Text("Paste")
                        .font(.system(size: 11, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(999)
                }
                .offset(x: -8)
            }
        }
    }
}

// MARK: - Action Buttons

struct ActionButtonsView: View {
    let onJoin: () -> Void
    let onScanQR: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 20) {
            // Primary Join Button
            Button(action: onJoin) {
                HStack(spacing: 8) {
                    Text("Join Group")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(primaryYellow)
                .cornerRadius(999)
                .shadow(color: primaryYellow.opacity(0.3), radius: 30, x: 0, y: 8)
            }
            
            // Divider
            HStack(spacing: 16) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(PlatformColor.systemGray4)
                
                Text("Or")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(2)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(PlatformColor.systemGray4)
            }
            .padding(.horizontal)
            
            // QR Code Button
            Button(action: onScanQR) {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 18))
                    Text("Scan QR Code")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(PlatformColor.systemGray4, lineWidth: 2)
                )
                .cornerRadius(999)
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Move RectCorner outside to avoid MainActor isolation issues
struct RectCorner: OptionSet {
    let rawValue: UInt
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Extract corner values to avoid MainActor isolation issues
        let cornerValue = corners.rawValue
        let topLeft = (cornerValue & 1) != 0
        let topRight = (cornerValue & 2) != 0
        let bottomLeft = (cornerValue & 4) != 0
        let bottomRight = (cornerValue & 8) != 0
        
        let topLeftRadius = topLeft ? radius : 0
        let topRightRadius = topRight ? radius : 0
        let bottomLeftRadius = bottomLeft ? radius : 0
        let bottomRightRadius = bottomRight ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY))
        
        if topRight {
            path.addLine(to: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + topRightRadius),
                            control: CGPoint(x: rect.maxX, y: rect.minY))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        
        if bottomRight {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRightRadius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - bottomRightRadius, y: rect.maxY),
                            control: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        
        if bottomLeft {
            path.addLine(to: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeftRadius),
                            control: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        
        if topLeft {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeftRadius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY),
                            control: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        
        path.closeSubpath()
        return path
    }
}
