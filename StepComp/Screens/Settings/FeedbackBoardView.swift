//
//  FeedbackBoardView.swift
//  StepComp
//
//  Created by Jeffery Erhunse
//

import SwiftUI

struct FeedbackBoardView: View {
    @StateObject private var viewModel = FeedbackBoardViewModel()
    @State private var showingCreateSheet = false
    @State private var showingEditSheet = false
    @State private var selectedPost: FeedbackPost?
    @State private var showingDeleteAlert = false
    @State private var postToDelete: FeedbackPost?
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(searchText: $viewModel.searchText)
                    .padding()
                    .onChange(of: viewModel.searchText) { oldValue, newValue in
                        Task {
                            // Debounce search
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            if viewModel.searchText == newValue {
                                await viewModel.loadFeedback()
                            }
                        }
                    }
                
                // Filter & Sort Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Category Filters
                        FilterChip(
                            title: "All",
                            isSelected: viewModel.selectedCategory == nil,
                            action: {
                                viewModel.selectedCategory = nil
                                Task { await viewModel.loadFeedback() }
                            }
                        )
                        
                        ForEach(FeedbackCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.displayName,
                                icon: category.icon,
                                isSelected: viewModel.selectedCategory == category,
                                action: {
                                    viewModel.selectedCategory = category
                                    Task { await viewModel.loadFeedback() }
                                }
                            )
                        }
                        
                        Divider()
                            .frame(height: 24)
                        
                        // Sort Options
                        Menu {
                            ForEach(FeedbackSortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    viewModel.selectedSort = option
                                    Task { await viewModel.loadFeedback() }
                                }) {
                                    Label(option.displayName, systemImage: option.icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 12))
                                Text(viewModel.selectedSort.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)
                
                Divider()
                
                // Content
                if viewModel.isLoading && viewModel.feedbackPosts.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading feedback...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.feedbackPosts.isEmpty {
                    EmptyFeedbackView(
                        searchText: viewModel.searchText,
                        onClearFilters: {
                            viewModel.clearFilters()
                            Task { await viewModel.loadFeedback() }
                        }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.feedbackPosts) { post in
                                FeedbackPostCard(
                                    post: post,
                                    onUpvote: {
                                        let newVote: VoteType? = post.userVote == .up ? nil : .up
                                        Task { await viewModel.vote(on: post.id, voteType: newVote) }
                                    },
                                    onDownvote: {
                                        let newVote: VoteType? = post.userVote == .down ? nil : .down
                                        Task { await viewModel.vote(on: post.id, voteType: newVote) }
                                    },
                                    onEdit: {
                                        selectedPost = post
                                        showingEditSheet = true
                                    },
                                    onDelete: {
                                        postToDelete = post
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Feedback Board")
            .navigationBarTitleDisplayMode(.large)
            .dismissKeyboardOnTap()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(StepCompColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateFeedbackSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let post = selectedPost {
                    EditFeedbackSheet(viewModel: viewModel, post: post)
                }
            }
            .alert("Delete Feedback", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let post = postToDelete {
                        Task {
                            await viewModel.deleteFeedback(postId: post.id)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this feedback? This action cannot be undone.")
            }
            .task {
                await viewModel.loadFeedback()
            }
        }
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search feedback...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? StepCompColors.primary : Color(.systemGray6))
            .foregroundColor(isSelected ? .black : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Feedback Post Card

struct FeedbackPostCard: View {
    let post: FeedbackPost
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                // Avatar
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.authorDisplayName?.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 16, weight: .bold))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(post.authorDisplayName ?? "Unknown User")
                            .font(.system(size: 14, weight: .semibold))
                        
                        if post.isAuthor {
                            Text("YOU")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(StepCompColors.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(StepCompColors.primary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(post.createdAt.timeAgoDisplay())
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Category Badge
                HStack(spacing: 4) {
                    Image(systemName: post.category.icon)
                        .font(.system(size: 10))
                    Text(post.category.displayName)
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.system(size: 16, weight: .bold))
                
                Text(post.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Divider()
            
            // Actions
            HStack {
                // Voting
                if !post.isAuthor {
                    HStack(spacing: 16) {
                        Button(action: onUpvote) {
                            HStack(spacing: 4) {
                                Image(systemName: post.userVote == .up ? "arrow.up.circle.fill" : "arrow.up.circle")
                                    .font(.system(size: 18))
                                Text("\(post.upvotes)")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(post.userVote == .up ? .green : .primary)
                        }
                        
                        Button(action: onDownvote) {
                            HStack(spacing: 4) {
                                Image(systemName: post.userVote == .down ? "arrow.down.circle.fill" : "arrow.down.circle")
                                    .font(.system(size: 18))
                                Text("\(post.downvotes)")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(post.userVote == .down ? .red : .primary)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14))
                        Text("\(post.upvotes)")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Image(systemName: "arrow.down")
                            .font(.system(size: 14))
                            .padding(.leading, 8)
                        Text("\(post.downvotes)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Net Score
                Text("\(post.netVotes > 0 ? "+" : "")\(post.netVotes)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(post.netVotes > 0 ? .green : post.netVotes < 0 ? .red : .secondary)
                
                // Edit/Delete for author
                if post.isAuthor {
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Empty State

struct EmptyFeedbackView: View {
    let searchText: String
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "bubble.left.and.bubble.right" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No feedback yet" : "No feedback found")
                .font(.system(size: 18, weight: .semibold))
            
            Text(searchText.isEmpty ? "Be the first to share your thoughts!" : "Try adjusting your search or filters")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !searchText.isEmpty {
                Button("Clear Filters", action: onClearFilters)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

