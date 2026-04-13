//
//  SettingsSupportLegalCard.swift
//  FitComp
//
//  Support & legal links card extracted from SettingsView.swift.
//

import SwiftUI

struct SupportLegalCard: View {
    @State private var showingFeedback = false
    @State private var showingFAQ = false
    @State private var showingPrivacy = false
    @State private var showingAbout = false
    
    var body: some View {
        SettingsCard(
            icon: "questionmark.circle.fill",
            iconColor: .pink,
            title: "Support & Legal"
        ) {
            VStack(spacing: 8) {
                Button(action: {
                    showingFeedback = true
                }) {
                    SupportLinkRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "Feedback Board"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(FitCompColors.cardBorder)
                
                Button(action: {
                    showingFAQ = true
                }) {
                    SupportLinkRow(
                        icon: "questionmark.circle.fill",
                        title: "FAQ / Help Center"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(FitCompColors.cardBorder)
                
                Button(action: {
                    showingPrivacy = true
                }) {
                    SupportLinkRow(
                        icon: "lock.fill",
                        title: "Privacy Policy"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(FitCompColors.cardBorder)
                
                Button(action: {
                    showingAbout = true
                }) {
                    SupportLinkRow(
                        icon: "info.circle.fill",
                        title: "About Us"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackBoardView()
        }
        .sheet(isPresented: $showingFAQ) {
            FAQView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutUsView()
        }
    }
}

struct SupportLinkRow: View {
    let icon: String
    let title: String
    
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(FitCompColors.surface)
        .cornerRadius(12)
    }
}
