//
//  FeedbackSheets.swift
//  StepComp
//
//  Created by Jeffery Erhunse
//

import SwiftUI

// MARK: - Create Feedback Sheet

struct CreateFeedbackSheet: View {
    @ObservedObject var viewModel: FeedbackBoardViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: FeedbackCategory = .feature
    @State private var isSubmitting = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Share Your Feedback")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Help us improve StepComp by sharing your ideas, reporting bugs, or suggesting improvements.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(FeedbackCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: {
                                            selectedCategory = category
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextField("Brief summary of your feedback", text: $title)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text("\(title.count)/200")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextEditor(text: $description)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text("\(description.count)/2000")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // Guidelines
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Guidelines")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            GuidelineRow(text: "Be specific and constructive")
                            GuidelineRow(text: "One feedback per submission")
                            GuidelineRow(text: "Check if similar feedback exists")
                            GuidelineRow(text: "Be respectful to the community")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("New Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: submitFeedback) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Submit")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
        }
    }
    
    private var isValid: Bool {
        title.count >= 3 && title.count <= 200 &&
        description.count >= 10 && description.count <= 2000
    }
    
    private func submitFeedback() {
        isSubmitting = true
        
        Task {
            let success = await viewModel.createFeedback(
                title: title,
                description: description,
                category: selectedCategory
            )
            
            isSubmitting = false
            
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Edit Feedback Sheet

struct EditFeedbackSheet: View {
    @ObservedObject var viewModel: FeedbackBoardViewModel
    let post: FeedbackPost
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: FeedbackCategory
    @State private var isSubmitting = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(viewModel: FeedbackBoardViewModel, post: FeedbackPost) {
        self.viewModel = viewModel
        self.post = post
        _title = State(initialValue: post.title)
        _description = State(initialValue: post.description)
        _selectedCategory = State(initialValue: post.category)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Category Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(FeedbackCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: {
                                            selectedCategory = category
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextField("Brief summary of your feedback", text: $title)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text("\(title.count)/200")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextEditor(text: $description)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text("\(description.count)/2000")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: updateFeedback) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Save")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
        }
    }
    
    private var isValid: Bool {
        title.count >= 3 && title.count <= 200 &&
        description.count >= 10 && description.count <= 2000
    }
    
    private func updateFeedback() {
        isSubmitting = true
        
        Task {
            let success = await viewModel.updateFeedback(
                postId: post.id,
                title: title,
                description: description,
                category: selectedCategory
            )
            
            isSubmitting = false
            
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: FeedbackCategory
    let isSelected: Bool
    let action: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? primaryYellow : Color(.systemGray6))
                    )
                
                Text(category.displayName)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .black : .primary)
        }
    }
}

// MARK: - Guideline Row

struct GuidelineRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text(text)
        }
    }
}

