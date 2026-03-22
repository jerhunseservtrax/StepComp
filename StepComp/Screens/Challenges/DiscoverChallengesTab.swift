//
//  DiscoverChallengesTab.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct DiscoverChallengesTab: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @ObservedObject var viewModel: ChallengesViewModel
    @EnvironmentObject var challengeService: ChallengeService
    
    @State private var searchText: String = ""
    @State private var selectedCategory: ChallengeCategory = .all
    @State private var navigationPath = NavigationPath()
    @AppStorage("challengeViewMode") private var viewMode: ChallengeViewMode = .grid
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
    
    
    enum ChallengeCategory: String, CaseIterable {
        case all = "All"
        case corporate = "Corporate"
        case marathon = "Marathon"
        case friends = "Friends"
        case shortTerm = "Short Term"
    }
    
    var filteredChallenges: [Challenge] {
        let currentUserId = sessionViewModel.currentUser?.id ?? ""
        
        // Start with public challenges, excluding ones user is already in
        var challenges = viewModel.publicChallenges.filter { challenge in
            // Exclude challenges where user is creator or already a participant
            challenge.creatorId != currentUserId && !challenge.participantIds.contains(currentUserId)
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            challenges = challenges.filter { challenge in
                challenge.name.localizedCaseInsensitiveContains(searchText) ||
                challenge.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if selectedCategory != .all {
            challenges = challenges.filter { challenge in
                guard let challengeCategory = challenge.category else {
                    return false // Don't show challenges without category if filtering
                }
                
                switch selectedCategory {
                case .all:
                    return true
                case .corporate:
                    return challengeCategory == .corporate
                case .marathon:
                    return challengeCategory == .marathon
                case .friends:
                    return challengeCategory == .friends
                case .shortTerm:
                    return challengeCategory == .shortTerm
                }
            }
        }
        
        return challenges
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                // Search Bar
                DiscoverSearchBarView(searchText: $searchText)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                // Category Filters and View Toggle
                HStack {
                    CategoryFiltersView(
                        selectedCategory: $selectedCategory
                    )
                    
                    // View Mode Toggle
                    ViewModeToggle(viewMode: $viewMode)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 16)
                
                // Challenges View (Grid or List)
                if filteredChallenges.isEmpty {
                    EmptyDiscoverView()
                        .padding(.vertical, 60)
                } else {
                    VStack(spacing: 16) {
                        if viewMode == .grid {
                            // Grid View - Adaptive columns (2 for iPhone, 3 for iPad)
                            LazyVGrid(
                                columns: gridColumns,
                                spacing: 16
                            ) {
                                ForEach(filteredChallenges) { challenge in
                                    DiscoverChallengeCard(
                                        challenge: challenge,
                                        onTap: {
                                            navigationPath.append(AppRoute.groupDetails(challengeId: challenge.id))
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        } else {
                            // List View (Vertical Stack)
                            VStack(spacing: 16) {
                                ForEach(filteredChallenges) { challenge in
                                    DiscoverChallengeListCard(
                                        challenge: challenge,
                                        onTap: {
                                            navigationPath.append(AppRoute.groupDetails(challengeId: challenge.id))
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 100)
                }
                }
            }
            .background(FitCompColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
        }
        .refreshable {
            await viewModel.loadChallenges()
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .groupDetails(let challengeId):
            if viewModel.publicChallenges.contains(where: { $0.id == challengeId }) {
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

// MARK: - Search Bar

struct DiscoverSearchBarView: View {
    @Binding var searchText: String
    
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            
            TextField("Search challenges, friends, goals...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled(true)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
        }
        .padding(.vertical, 14)
        .background(FitCompColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(searchText.isEmpty ? Color.clear : FitCompColors.primary, lineWidth: 2)
        )
    }
}

// MARK: - Category Filters

struct CategoryFiltersView: View {
    @Binding var selectedCategory: DiscoverChallengesTab.ChallengeCategory
    
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DiscoverChallengesTab.ChallengeCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isSelected ? .black : Color(red: 0.620, green: 0.616, blue: 0.278))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? FitCompColors.primary : FitCompColors.surface)
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(isSelected ? Color.clear : Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: isSelected ? FitCompColors.primary.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Discover Challenge Card

struct DiscoverChallengeCard: View {
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
                return [FitCompColors.yellow, Color(red: 0.98, green: 0.76, blue: 0.25)]
            }
        }
        let gradients: [[Color]] = [
            [Color(red: 1.0, green: 0.42, blue: 0.29), Color(red: 0.976, green: 0.26, blue: 0.15)], // Orange
            [Color(red: 0.23, green: 0.51, blue: 0.96), Color(red: 0.15, green: 0.39, blue: 0.92)], // Blue
            [FitCompColors.yellow, Color(red: 0.98, green: 0.76, blue: 0.25)], // Yellow
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
        return gradientColors[0] == FitCompColors.yellow
    }
    
    // Fixed card height for consistent grid layout
    private let cardHeight: CGFloat = 220
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background: User uploaded image OR gradient
                if let imageUrl = challenge.imageUrl, !imageUrl.isEmpty {
                    // User uploaded image with reduced opacity gradient overlay
                    ZStack {
                        // Challenge image
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                if challenge.imageUrl == nil || challenge.imageUrl!.isEmpty {
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

// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - View Mode Toggle

struct ViewModeToggle: View {
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
                    .foregroundColor(viewMode == .grid ? FitCompColors.buttonTextOnPrimary : FitCompColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(viewMode == .grid ? FitCompColors.primary : FitCompColors.surfaceElevated)
                    .cornerRadius(8)
            }
            
            // List View Button
            Button(action: {
                withAnimation {
                    viewMode = .list
                }
            }) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewMode == .list ? FitCompColors.buttonTextOnPrimary : FitCompColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(viewMode == .list ? FitCompColors.primary : FitCompColors.surfaceElevated)
                    .cornerRadius(8)
            }
        }
        .background(FitCompColors.surfaceElevated)
        .cornerRadius(10)
        .padding(.leading, 8)
    }
}

// MARK: - Discover Challenge List Card (Horizontal)

struct DiscoverChallengeListCard: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    
    private func challengeDuration(in challenge: Challenge) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate)
        return max(1, components.day ?? 1)
    }
    
    var iconColor: Color {
        let colors: [Color] = [
            Color.orange,
            Color.blue,
            FitCompColors.primary,
            Color.purple,
            Color.green
        ]
        return colors[abs(challenge.name.hashValue) % colors.count]
    }
    
    var iconName: String {
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
                        Text(challenge.category?.displayName.uppercased() ?? "CHALLENGE")
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
                                .foregroundColor(FitCompColors.textTertiary)
                        }
                    }
                    
                    // Challenge name
                    Text(challenge.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(FitCompColors.textPrimary)
                        .lineLimit(1)
                    
                    // Participants count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(FitCompColors.textSecondary)
                        
                        Text("\(challenge.participantIds.count) joined")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FitCompColors.textSecondary)
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
                            .foregroundColor(FitCompColors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(FitCompColors.surfaceElevated)
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    // Subtle dot pattern background
                    FitCompColors.surface
                    
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
                        .fill(FitCompColors.textPrimary.opacity(0.03))
                    }
                }
            )
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(FitCompColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: FitCompColors.shadowPrimary, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Empty Discover View

struct EmptyDiscoverView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Challenges Found")
                .font(.system(size: 20, weight: .bold))
            
            Text("Try adjusting your search or filters")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

