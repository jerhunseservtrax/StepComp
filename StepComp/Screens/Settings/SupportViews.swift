//
//  SupportViews.swift
//  StepComp
//
//  Support & Legal content views
//

import SwiftUI

// MARK: - Feedback Board

struct SimpleFeedbackBoardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackText = ""
    @State private var selectedCategory = "Feature Request"
    @State private var showingGuidelines = false
    
    private let categories = ["Feature Request", "Bug Report", "General", "Other"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We're building StepComp together.")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Share ideas, suggest improvements, and vote on features you'd love to see next.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Guidelines Button
                    Button(action: {
                        showingGuidelines = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("How it works & Community rules")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                    
                    // Status Legend
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status Legend")
                            .font(.system(size: 16, weight: .semibold))
                        
                        HStack(spacing: 12) {
                            StatusChip(title: "Open", color: .blue)
                            StatusChip(title: "Planned", color: .purple)
                            StatusChip(title: "In Progress", color: .orange)
                        }
                        
                        HStack(spacing: 12) {
                            StatusChip(title: "Completed", color: .green)
                            StatusChip(title: "Rejected", color: .red)
                        }
                    }
                    
                    // Feedback Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Submit Feedback")
                            .font(.system(size: 20, weight: .bold))
                        
                        // Category Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 14, weight: .medium))
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Feedback Text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Feedback")
                                .font(.system(size: 14, weight: .medium))
                            
                            TextEditor(text: $feedbackText)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Submit Button
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
                            .padding()
                            .background(feedbackText.isEmpty ? Color.gray : StepCompColors.primary)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        .disabled(feedbackText.isEmpty)
                        
                        Text("Your feedback helps us improve StepComp!")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Feedback Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGuidelines) {
                GuidelinesView()
            }
        }
    }
}

// MARK: - Guidelines View

struct GuidelinesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // How it works
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How it works")
                            .font(.system(size: 20, weight: .bold))
                        
                        BulletPoint(text: "Submit feature ideas or feedback")
                        BulletPoint(text: "Upvote ideas you like")
                        BulletPoint(text: "Downvote ideas you don't find useful")
                        BulletPoint(text: "One vote per user")
                    }
                    
                    Divider()
                    
                    // Community rules
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Community rules")
                            .font(.system(size: 20, weight: .bold))
                        
                        BulletPoint(text: "Be respectful", icon: "hand.raised.fill")
                        BulletPoint(text: "No spam or duplicate posts", icon: "exclamationmark.triangle.fill")
                        BulletPoint(text: "Feature requests only (no support issues)", icon: "lightbulb.fill")
                    }
                }
                .padding()
            }
            .navigationTitle("Guidelines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
                VStack(alignment: .leading, spacing: 16) {
                    Text("Frequently Asked Questions")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                    
                    // Steps & Tracking
                    FAQSection(title: "🏃‍♂️ Steps & Tracking", items: [
                        FAQItem(
                            question: "How does StepComp track my steps?",
                            answer: "StepComp securely reads step data from Apple Health. We never guess or estimate steps."
                        ),
                        FAQItem(
                            question: "Can I manually add steps?",
                            answer: "No. To keep challenges fair, steps must come directly from your device."
                        ),
                        FAQItem(
                            question: "Why do my steps look lower than expected?",
                            answer: "Apple Health may update steps throughout the day. Small adjustments are normal."
                        )
                    ])
                    
                    // Challenges
                    FAQSection(title: "🏆 Challenges", items: [
                        FAQItem(
                            question: "How do challenges work?",
                            answer: "Join or create challenges to compete with friends. Rankings are updated automatically based on verified step data."
                        ),
                        FAQItem(
                            question: "Can I join a challenge late?",
                            answer: "That depends on the challenge settings chosen by the creator."
                        )
                    ])
                    
                    // Friends
                    FAQSection(title: "👥 Friends", items: [
                        FAQItem(
                            question: "How do I add friends?",
                            answer: "You can search public profiles or invite friends with a direct link."
                        ),
                        FAQItem(
                            question: "Can I remove someone from my friends list?",
                            answer: "Yes. Open Friends → Edit → Remove."
                        )
                    ])
                    
                    // Privacy & Security
                    FAQSection(title: "🔒 Privacy & Security", items: [
                        FAQItem(
                            question: "Who can see my activity?",
                            answer: "Only you and people in challenges you join. You control whether your profile is public."
                        ),
                        FAQItem(
                            question: "Is my data sold?",
                            answer: "No. Never."
                        )
                    ])
                    
                    // Account
                    FAQSection(title: "⚙️ Account", items: [
                        FAQItem(
                            question: "How do I reset my password?",
                            answer: "Tap \"Forgot Password\" on the sign-in screen and follow the email instructions."
                        ),
                        FAQItem(
                            question: "Can I delete my account?",
                            answer: "Yes. Go to Settings → Account → Delete Account."
                        )
                    ])
                }
                .padding(.vertical)
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

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Last updated: January 1, 2026")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("StepComp respects your privacy and is committed to protecting your data.")
                        .font(.system(size: 16))
                        .padding(.vertical, 8)
                    
                    Group {
                        PolicySection(title: "Information We Collect", items: [
                            "Account information (email, name, avatar)",
                            "Step data from Apple Health",
                            "App usage analytics",
                            "Device and diagnostic data"
                        ])
                        
                        PolicySection(title: "How We Use Your Data", items: [
                            "Track steps and power challenges",
                            "Rank leaderboards",
                            "Improve app performance",
                            "Prevent cheating and abuse"
                        ])
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Health Data")
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("StepComp reads step data from Apple Health only with your permission. We do not modify, sell, or share your health data.")
                                .font(.system(size: 14))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data Sharing")
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("We do not sell personal data. We only share data when required to operate core features (e.g., leaderboards).")
                                .font(.system(size: 14))
                        }
                        
                        PolicySection(title: "Security", subtitle: "We use:", items: [
                            "Encrypted connections",
                            "Secure authentication",
                            "Server-side validation",
                            "Rate limiting and abuse detection"
                        ])
                        
                        PolicySection(title: "Your Choices", items: [
                            "Make your profile public or private",
                            "Revoke Health access at any time",
                            "Delete your account and data"
                        ])
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact")
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("For privacy questions:")
                                .font(.system(size: 14))
                            
                            Button(action: {
                                if let url = URL(string: "mailto:privacy@stepcomp.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("privacy@stepcomp.app")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon
                    ZStack {
                        Circle()
                            .fill(StepCompColors.primary.opacity(0.2))
                            .frame(width: 160, height: 160)
                        
                        Image(systemName: "figure.walk")
                            .font(.system(size: 80))
                            .foregroundColor(StepCompColors.primary)
                    }
                    .padding(.top, 32)
                    
                    VStack(spacing: 8) {
                        Text("StepComp")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Version 2.4.0 (Build 390)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("About StepComp")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("StepComp was built to turn everyday movement into something fun, social, and motivating.")
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("We believe:")
                                .font(.system(size: 16, weight: .semibold))
                            
                            BulletPoint(text: "Movement should feel rewarding")
                            BulletPoint(text: "Competition should be fair")
                            BulletPoint(text: "Progress should be personal")
                        }
                        
                        Text("Whether you're walking to stay healthy or competing with friends, StepComp helps you stay consistent — one step at a time.")
                            .font(.system(size: 16))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Our Mission")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("To motivate people to move more through friendly competition, transparency, and community.")
                            .font(.system(size: 16))
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
                    .padding(.bottom, 32)
                }
                .padding(.horizontal)
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

// MARK: - Helper Components

struct StatusChip: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .cornerRadius(12)
    }
}

struct BulletPoint: View {
    let text: String
    var icon: String = "circle.fill"
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            Text(text)
                .font(.system(size: 14))
        }
    }
}

struct FAQSection: View {
    let title: String
    let items: [FAQItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal)
            
            ForEach(items) { item in
                FAQItemRow(item: item)
            }
        }
    }
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQItemRow: View {
    let item: FAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(item.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(item.answer)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct PolicySection: View {
    let title: String
    var subtitle: String? = nil
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    BulletPoint(text: item)
                }
            }
        }
    }
}
