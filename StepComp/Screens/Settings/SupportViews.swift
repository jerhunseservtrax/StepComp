//
//  SupportViews.swift
//  StepComp
//
//  Support & Legal content views
//

import SwiftUI

// MARK: - Feedback Board

struct FeedbackBoardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackText = ""
    @State private var selectedCategory = "General"
    
    private let categories = ["General", "Bug Report", "Feature Request", "Other"]
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Your Feedback")) {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                }
                
                Section(footer: Text("Your feedback helps us improve StepComp!")) {
                    Button(action: {
                        // TODO: Submit feedback to backend
                        print("Feedback submitted: \(feedbackText)")
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Submit Feedback")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .disabled(feedbackText.isEmpty)
                }
            }
            .navigationTitle("Feedback Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - FAQ View

struct FAQView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    FAQItem(
                        question: "How do I track my steps?",
                        answer: "StepComp automatically syncs with Apple HealthKit to track your steps. Make sure you've granted HealthKit permissions in Settings."
                    )
                    
                    FAQItem(
                        question: "How do challenges work?",
                        answer: "Create or join challenges to compete with friends! Your daily steps automatically count towards active challenges."
                    )
                    
                    FAQItem(
                        question: "Can I join multiple challenges?",
                        answer: "Yes! You can participate in as many challenges as you like simultaneously."
                    )
                    
                    FAQItem(
                        question: "How do I add friends?",
                        answer: "Go to the Friends tab and tap 'Add Friends'. You can search by username or share your invite link."
                    )
                }
                .padding()
            }
            .navigationTitle("FAQ / Help Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Last updated: January 1, 2026")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Group {
                        SupportSectionHeader(title: "Data Collection")
                        Text("We collect step data from Apple HealthKit with your explicit permission. This data is used solely to provide challenge and social features within the app.")
                        
                        SupportSectionHeader(title: "Data Usage")
                        Text("Your step data is used to calculate challenge rankings and display your progress. We never sell or share your personal data with third parties.")
                        
                        SupportSectionHeader(title: "Data Storage")
                        Text("All data is securely stored and encrypted. You can request deletion of your data at any time by contacting support.")
                        
                        SupportSectionHeader(title: "Your Rights")
                        Text("You have the right to access, modify, or delete your personal data. You can also opt out of data collection at any time.")
                    }
                    .font(.system(size: 14))
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - About Us

struct AboutUsView: View {
    @Environment(\.dismiss) var dismiss
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon
                    Image(systemName: "figure.walk")
                        .font(.system(size: 80))
                        .foregroundColor(primaryYellow)
                        .padding()
                        .background(
                            Circle()
                                .fill(primaryYellow.opacity(0.2))
                                .frame(width: 160, height: 160)
                        )
                    
                    VStack(spacing: 8) {
                        Text("StepComp")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Version 2.4.0 (Build 390)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About StepComp")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("StepComp is a social fitness app that makes walking fun and competitive. Challenge your friends, track your progress, and achieve your step goals together!")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    VStack(spacing: 12) {
                        Text("Made with ❤️ for walkers everywhere")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("© 2026 StepComp. All rights reserved.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("About Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Support Section Header

struct SupportSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .padding(.top, 8)
    }
}

