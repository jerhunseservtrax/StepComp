//
//  ActiveChallengesTab.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct ActiveChallengesTab: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @ObservedObject var viewModel: ChallengesViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @State private var navigationPath = NavigationPath()
    @AppStorage("challengeViewMode") private var viewMode: ChallengeViewMode = .list
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Adaptive grid columns based on device size
    private var gridColumns: [GridItem] {
        let spacing: CGFloat = 16
        
        // iPad (regular width) - 3 columns
        if horizontalSizeClass == .regular {
            return Array(repeating: GridItem(.flexible(minimum: 200), spacing: spacing), count: 3)
        }
        // iPhone (compact width) - 2 columns
        else {
            return Array(repeating: GridItem(.flexible(minimum: 150), spacing: spacing), count: 2)
        }
    }
    
    // Adaptive padding based on device size
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 40 : 16
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    // View Mode Toggle
                    HStack {
                        Spacer()
                        ActiveViewModeToggle(viewMode: $viewMode)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Challenges View
                    if viewModel.activeChallenges.isEmpty {
                        EmptyActiveChallengesView()
                            .padding(.vertical, 60)
                    } else {
                        if viewMode == .grid {
                            // Grid View - Adaptive columns (2 for iPhone, 3 for iPad)
                            LazyVGrid(
                                columns: gridColumns,
                                spacing: 16
                            ) {
                                ForEach(viewModel.activeChallenges) { challenge in
                                    ActiveChallengeGridCard(
                                        challenge: challenge,
                                        onTap: {
                                            navigationPath.append(AppRoute.groupDetails(challengeId: challenge.id))
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                        } else {
                            // List View
                            VStack(spacing: 16) {
                                ForEach(viewModel.activeChallenges) { challenge in
                                    ActiveChallengeListItem(
                                        challenge: challenge,
                                        onTap: {
                                            navigationPath.append(AppRoute.groupDetails(challengeId: challenge.id))
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(StepCompColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .refreshable {
                await viewModel.loadChallenges()
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .groupDetails(let challengeId):
            if viewModel.activeChallenges.contains(where: { $0.id == challengeId }) {
                GroupDetailsView(
                    sessionViewModel: sessionViewModel,
                    challengeId: challengeId
                )
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }
}

struct ActiveChallengeListItem: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    private func challengeDuration(in challenge: Challenge) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate)
        return max(1, components.day ?? 1)
    }
    
    var iconColor: Color {
        if let category = challenge.category {
            switch category {
            case .corporate: return Color.orange
            case .marathon: return Color.blue
            case .friends: return Color.purple
            case .shortTerm: return Color.green
            case .fun: return StepCompColors.primary
            }
        }
        let colors: [Color] = [Color.orange, Color.blue, StepCompColors.primary, Color.purple, Color.green]
        return colors[abs(challenge.name.hashValue) % colors.count]
    }
    
    var iconName: String {
        if let category = challenge.category {
            switch category {
            case .corporate: return "briefcase.fill"
            case .marathon: return "figure.run"
            case .friends: return "person.2.fill"
            case .shortTerm: return "bolt.fill"
            case .fun: return "party.popper.fill"
            }
        }
        let icons = ["figure.hiking", "drop.fill", "trophy.fill", "moon.fill", "tree.fill"]
        return icons[abs(challenge.name.hashValue) % icons.count]
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Left: Challenge Image/Icon (72x72)
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [iconColor.opacity(0.15), iconColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Middle: Challenge Info
                    VStack(alignment: .leading, spacing: 4) {
                    // Badge and category
                    HStack(spacing: 6) {
                        Text(challenge.category?.displayName.uppercased() ?? "ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(iconColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(iconColor.opacity(0.15))
                            .cornerRadius(6)
                        
                        if let category = challenge.category {
                            Text(category.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(StepCompColors.textTertiary)
                        }
                    }
                    
                    // Challenge name
                    Text(challenge.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(StepCompColors.textPrimary)
                        .lineLimit(1)
                    
                    // Participants count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(StepCompColors.textSecondary)
                        
                        Text("\(challenge.participantIds.count) joined")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(StepCompColors.textSecondary)
                    }
                }
                    
                    Spacer()
                    
                // Right: Time remaining badge
                VStack(spacing: 4) {
                    let daysLeft = challengeDuration(in: challenge)
                    HStack(spacing: 4) {
                        Image(systemName: daysLeft > 7 ? "clock.fill" : "hourglass")
                            .font(.system(size: 14))
                            .foregroundColor(daysLeft > 7 ? iconColor : .red)
                        
                        Text("\(daysLeft)d left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(StepCompColors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(StepCompColors.surfaceElevated)
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    // Subtle dot pattern background
                    StepCompColors.surface
                    
                    // Pattern overlay
                    GeometryReader { geometry in
                        Path { path in
                            let spacing: CGFloat = 10
                            let rows = Int(geometry.size.height / spacing) + 1
                            let cols = Int(geometry.size.width / spacing) + 1
                            
                            for row in 0..<rows {
                                for col in 0..<cols {
                                    let x = CGFloat(col) * spacing
                                    let y = CGFloat(row) * spacing
                                    path.addEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                                }
                            }
                        }
                        .fill(StepCompColors.textPrimary.opacity(0.03))
                    }
                }
            )
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(StepCompColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: StepCompColors.shadowPrimary, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active View Mode Toggle

struct ActiveViewModeToggle: View {
    @Binding var viewMode: ChallengeViewMode
    
    
    var body: some View {
        HStack(spacing: 0) {
            // Grid Button
            Button(action: {
                withAnimation {
                    viewMode = .grid
                }
            }) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewMode == .grid ? StepCompColors.buttonTextOnPrimary : StepCompColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(viewMode == .grid ? StepCompColors.primary : StepCompColors.surfaceElevated)
                    .cornerRadius(8)
            }
            
            // List Button
            Button(action: {
                withAnimation {
                    viewMode = .list
                }
            }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewMode == .list ? StepCompColors.buttonTextOnPrimary : StepCompColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(viewMode == .list ? StepCompColors.primary : StepCompColors.surfaceElevated)
                    .cornerRadius(8)
            }
        }
        .background(StepCompColors.surfaceElevated)
        .cornerRadius(10)
    }
}

// MARK: - Active Challenge Grid Card

struct ActiveChallengeGridCard: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: challenge.endDate)
        return max(0, components.day ?? 0)
    }
    
    private var challengeDuration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate)
        return max(1, components.day ?? 1)
    }
    
    var gradientColors: [Color] {
        if let category = challenge.category {
            switch category {
            case .corporate:
                return [Color(red: 1.0, green: 0.42, blue: 0.29), Color(red: 0.976, green: 0.26, blue: 0.15)]
            case .marathon:
                return [Color(red: 0.23, green: 0.51, blue: 0.96), Color(red: 0.15, green: 0.39, blue: 0.92)]
            case .friends:
                return [Color(red: 0.49, green: 0.23, blue: 0.93), Color(red: 0.43, green: 0.16, blue: 0.85)]
            case .shortTerm:
                return [Color(red: 0.02, green: 0.59, blue: 0.41), Color(red: 0.02, green: 0.47, blue: 0.34)]
            case .fun:
                return [StepCompColors.yellow, Color(red: 0.98, green: 0.76, blue: 0.25)]
            }
        }
        let gradients: [[Color]] = [
            [Color(red: 1.0, green: 0.42, blue: 0.29), Color(red: 0.976, green: 0.26, blue: 0.15)], // Orange
            [Color(red: 0.23, green: 0.51, blue: 0.96), Color(red: 0.15, green: 0.39, blue: 0.92)], // Blue
            [StepCompColors.yellow, Color(red: 0.98, green: 0.76, blue: 0.25)], // Yellow
            [Color(red: 0.49, green: 0.23, blue: 0.93), Color(red: 0.43, green: 0.16, blue: 0.85)], // Purple
            [Color(red: 0.02, green: 0.59, blue: 0.41), Color(red: 0.02, green: 0.47, blue: 0.34)] // Green
        ]
        return gradients[abs(challenge.name.hashValue) % gradients.count]
    }
    
    var iconName: String {
        if let category = challenge.category {
            switch category {
            case .corporate: return "briefcase.fill"
            case .marathon: return "figure.run"
            case .friends: return "person.2.fill"
            case .shortTerm: return "bolt.fill"
            case .fun: return "party.popper.fill"
            }
        }
        let icons = ["figure.hiking", "drop.fill", "trophy.fill", "moon.fill", "tree.fill"]
        return icons[abs(challenge.name.hashValue) % icons.count]
    }
    
    var badgeText: String {
        if let category = challenge.category {
            return category.displayName.uppercased()
        }
        // Default badge based on duration
        if challengeDuration <= 7 {
            return "SHORT"
        } else if challengeDuration <= 14 {
            return "DAILY"
        } else {
            return "\(challengeDuration)D"
        }
    }
    
    var isYellowBackground: Bool {
        if let category = challenge.category {
            return category == .fun
        }
        return gradientColors[0] == StepCompColors.yellow
    }
    
    // Fixed card height for consistent grid layout
    private let cardHeight: CGFloat = 220
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background: User uploaded image OR gradient
                if isValidImageURL(challenge.imageUrl) {
                    // User uploaded image with reduced opacity gradient overlay
                    ZStack {
                        // Challenge image
                        AsyncImage(url: URL(string: challenge.imageUrl!)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipped()
                            case .failure:
                                // Fallback gradient on image load failure
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            case .empty:
                                // Loading state - show gradient
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            @unknown default:
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                        
                        // Gradient overlay for better text readability (reduced opacity)
                        LinearGradient(
                            colors: [
                                gradientColors[0].opacity(0.5),
                                gradientColors[1].opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.multiply)
                    }
                } else {
                    // Default gradient background
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                
                // Decorative blur circles (only if no custom image)
                if !isValidImageURL(challenge.imageUrl) {
                    Circle()
                        .fill(isYellowBackground ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                        .offset(x: 50, y: -40)
                    
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                        .offset(x: -50, y: 40)
                    
                    // Large icon watermark
                    Image(systemName: iconName)
                        .font(.system(size: 100, weight: .medium))
                        .foregroundColor((isYellowBackground ? Color.black : Color.white).opacity(0.1))
                        .rotationEffect(.degrees(-10))
                        .offset(x: 30, y: 40)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // Top: Icon badge and category badge
                    HStack(alignment: .top) {
                        // Icon badge
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    (isYellowBackground ? Color.black : Color.white)
                                        .opacity(0.15)
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: iconName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isYellowBackground ? .black : .white)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        
                        Spacer()
                        
                        // Category badge
                        Text(badgeText)
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.5)
                            .foregroundColor(isYellowBackground ? gradientColors[0] : gradientColors[0])
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        (isYellowBackground ? Color.black : Color.white)
                                            .opacity(0.9)
                                    )
                            )
                    }
                    .padding(.bottom, 12)
                    
                    // Middle: Challenge name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.name.uppercased())
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .tracking(-0.5)
                            .foregroundColor(isYellowBackground ? .black : .white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isYellowBackground ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
                                .frame(width: 4, height: 4)
                            
                            if let category = challenge.category {
                                Text(category.displayName)
                            } else {
                                Text("Challenge")
                            }
                            
                            Text("•")
                            
                            Text("\(challenge.participantIds.count) joined")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isYellowBackground ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Bottom: Avatars and time remaining
                    HStack {
                        // Participant avatars
                        HStack(spacing: -8) {
                            ForEach(0..<min(2, max(1, challenge.participantIds.count)), id: \.self) { index in
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                (isYellowBackground ? Color.white : Color.white)
                                                    .opacity(0.2),
                                                lineWidth: 2
                                            )
                                    )
                            }
                            
                            if challenge.participantIds.count > 2 {
                                ZStack {
                                    Circle()
                                        .fill(isYellowBackground ? Color.black : Color.white)
                                        .frame(width: 28, height: 28)
                                    
                                    Text("\(challenge.participantIds.count)")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(isYellowBackground ? .white : gradientColors[0])
                                }
                                .overlay(
                                    Circle()
                                        .stroke(
                                            (isYellowBackground ? Color.white : Color.white)
                                                .opacity(0.2),
                                            lineWidth: 2
                                        )
                                )
                            }
                        }
                        
                        Spacer()
                        
                        // Time remaining - Translucent pill
                        HStack(spacing: 4) {
                            Image(systemName: daysRemaining > 7 ? "clock.fill" : "hourglass")
                                .font(.system(size: 12))
                            
                            Text("\(daysRemaining)D LEFT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.5)
                        }
                        .foregroundColor(isYellowBackground ? .black.opacity(0.85) : .white)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                (isYellowBackground ? Color.white : Color.white)
                                    .opacity(isYellowBackground ? 0.25 : 0.2)
                            )
                    )
                }
                .padding(16)
            }
            .frame(height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct EmptyActiveChallengesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Active Challenges")
                .font(.system(size: 20, weight: .bold))
            
            Text("Join or create challenges to see them here")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}

