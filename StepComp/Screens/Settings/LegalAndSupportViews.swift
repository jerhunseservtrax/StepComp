//
//  LegalAndSupportViews.swift
//  FitComp
//
//  Legal, Support, and About content views
//

import SwiftUI

// MARK: - Terms of Service

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms of Service")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Effective Date: January 3, 2026")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Text("Welcome to FitComp. By accessing or using the FitComp app, you agree to these Terms of Service (\"Terms\"). If you do not agree, please do not use the app.")
                    .font(.system(size: 15))
                
                // Section 1
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Eligibility")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("You must be at least 13 years old to use FitComp. By using the app, you confirm that you meet this requirement.")
                        .font(.system(size: 15))
                }
                
                // Section 2
                VStack(alignment: .leading, spacing: 12) {
                    Text("2. Account Responsibility")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("You are responsible for:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Keeping your account credentials secure")
                        BulletPoint(text: "All activity under your account")
                        BulletPoint(text: "Providing accurate information")
                    }
                    
                    Text("FitComp is not responsible for unauthorized access caused by user negligence.")
                        .font(.system(size: 15))
                }
                
                // Section 3
                VStack(alignment: .leading, spacing: 12) {
                    Text("3. Health Data Disclaimer")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("FitComp is not a medical app.")
                        .font(.system(size: 15, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "FitComp provides fitness tracking for motivation and entertainment")
                        BulletPoint(text: "Data is sourced from Apple Health")
                        BulletPoint(text: "Do not rely on FitComp for medical advice, diagnosis, or treatment")
                        BulletPoint(text: "Always consult a healthcare professional before making health decisions")
                    }
                }
                
                // Section 4
                VStack(alignment: .leading, spacing: 12) {
                    Text("4. Fair Use & Cheating")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("You agree not to:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Manipulate step data")
                        BulletPoint(text: "Attempt to exploit or reverse-engineer the app")
                        BulletPoint(text: "Circumvent security or validation systems")
                    }
                    
                    Text("Suspicious activity may result in:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Leaderboard exclusion")
                        BulletPoint(text: "Challenge removal")
                        BulletPoint(text: "Account suspension or termination")
                    }
                }
                
                // Section 5
                VStack(alignment: .leading, spacing: 12) {
                    Text("5. User-Generated Content")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("You are responsible for any content you post, including:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Profile details")
                        BulletPoint(text: "Challenge messages")
                        BulletPoint(text: "Feedback submissions")
                    }
                    
                    Text("We reserve the right to remove content that violates these Terms or Community Guidelines.")
                        .font(.system(size: 15))
                }
                
                // Section 6
                VStack(alignment: .leading, spacing: 12) {
                    Text("6. Account Termination")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("We may suspend or terminate accounts for:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Policy violations")
                        BulletPoint(text: "Abuse or harassment")
                        BulletPoint(text: "Cheating or fraud")
                        BulletPoint(text: "Security threats")
                    }
                    
                    Text("You may delete your account at any time.")
                        .font(.system(size: 15))
                }
                
                // Section 7
                VStack(alignment: .leading, spacing: 12) {
                    Text("7. Limitation of Liability")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("FitComp is provided \"as is\". We are not liable for:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Data loss")
                        BulletPoint(text: "Fitness outcomes")
                        BulletPoint(text: "Injuries")
                        BulletPoint(text: "Service interruptions")
                    }
                    
                    Text("Use at your own risk.")
                        .font(.system(size: 15, weight: .semibold))
                }
                
                // Section 8
                VStack(alignment: .leading, spacing: 12) {
                    Text("8. Changes to Terms")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("We may update these Terms from time to time. Continued use constitutes acceptance.")
                        .font(.system(size: 15))
                }
                
                // Section 9
                VStack(alignment: .leading, spacing: 12) {
                    Text("9. Contact")
                        .font(.system(size: 20, weight: .bold))
                    
                    Link("merakidenphotos@gmail.com", destination: URL(string: "mailto:merakidenphotos@gmail.com")!)
                        .font(.system(size: 15))
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Community Guidelines

struct CommunityGuidelinesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Community Guidelines")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("FitComp is a positive, competitive, and respectful space. These guidelines exist to protect the community.")
                        .font(.system(size: 15))
                }
                
                // Be Respectful
                VStack(alignment: .leading, spacing: 12) {
                    Text("Be Respectful")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "No harassment, hate speech, or bullying")
                        BulletPoint(text: "No threats or abusive language")
                    }
                }
                
                // Fair Play
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fair Play")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Do not cheat, spoof steps, or exploit bugs")
                        BulletPoint(text: "Respect challenge rules")
                    }
                }
                
                // Appropriate Content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appropriate Content")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Do not post:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Offensive or explicit content")
                        BulletPoint(text: "Spam or advertisements")
                        BulletPoint(text: "False information")
                    }
                }
                
                // Privacy Respect
                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy Respect")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Do not share others' personal information")
                        BulletPoint(text: "Do not attempt to contact users outside intended app features")
                    }
                }
                
                // Enforcement
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enforcement")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Violations may result in:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Content removal")
                        BulletPoint(text: "Temporary suspension")
                        BulletPoint(text: "Permanent account removal")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Community Guidelines")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Challenge Rules

struct ChallengeRulesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge Rules Policy")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("All challenges operate under the following rules to ensure fairness and integrity.")
                        .font(.system(size: 15))
                }
                
                // Rule 1
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Step Source")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Only steps synced from approved sources (e.g., Apple Health)")
                        BulletPoint(text: "Manual entry is not allowed")
                    }
                }
                
                // Rule 2
                VStack(alignment: .leading, spacing: 12) {
                    Text("2. Validation")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Step data is validated server-side")
                        BulletPoint(text: "Suspicious patterns may be flagged or excluded")
                    }
                }
                
                // Rule 3
                VStack(alignment: .leading, spacing: 12) {
                    Text("3. Leaderboards")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Rankings are calculated from verified step data")
                        BulletPoint(text: "Flagged steps may be excluded without notice")
                    }
                }
                
                // Rule 4
                VStack(alignment: .leading, spacing: 12) {
                    Text("4. Participation")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Only challenge members can view challenge chat and rankings")
                        BulletPoint(text: "Leaving a challenge may remove your data from that challenge")
                    }
                }
                
                // Rule 5
                VStack(alignment: .leading, spacing: 12) {
                    Text("5. Enforcement")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("FitComp reserves the right to:")
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Adjust rankings")
                        BulletPoint(text: "Remove participants")
                        BulletPoint(text: "Cancel challenges if abuse is detected")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Challenge Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Contact Support

struct ContactSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedCategory = "General Question"
    
    private let categories = ["General Question", "Bug Report", "Feature Request", "Account Issue", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact Support")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("We're here to help. Send us a message and we'll get back to you as soon as possible.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                
                // Quick Help
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Help")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Check our FAQ first—you might find your answer instantly.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Contact Form
                VStack(alignment: .leading, spacing: 16) {
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Subject
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextField("Brief summary of your issue", text: $subject)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextEditor(text: $message)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Email Link
                    Link(destination: URL(string: "mailto:merakidenphotos@gmail.com?subject=\(selectedCategory): \(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                        HStack {
                            Spacer()
                            Text("Send Email")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                        .padding()
                        .background(FitCompColors.primary)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                }
                
                // Direct Contact
                VStack(alignment: .leading, spacing: 12) {
                    Text("Direct Contact")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Link("merakidenphotos@gmail.com", destination: URL(string: "mailto:merakidenphotos@gmail.com")!)
                        .font(.system(size: 15))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - App Version

struct AppVersionView: View {
    @Environment(\.dismiss) var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(buildNumber)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Link("View on App Store", destination: URL(string: "https://apps.apple.com/app/fitcomp")!)
                Link("Rate FitComp", destination: URL(string: "https://apps.apple.com/app/fitcomp")!)
            }
            
            Section(footer: Text("© 2026 FitComp. All rights reserved.")) {
                HStack {
                    Text("Made with")
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("for fitness lovers")
                }
            }
        }
        .navigationTitle("App Version")
    }
}
