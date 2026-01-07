//
//  DeleteAccountConfirmationView.swift
//  StepComp
//
//  Created by AI Assistant on 1/2/26.
//

import SwiftUI

struct DeleteAccountConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var confirmationText: String
    let onConfirm: () -> Void
    let isDeletingAccount: Bool
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Warning Icon
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.red)
                    
                    Text("Delete Account")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("This action cannot be undone")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                
                // Warning Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("The following will be permanently deleted:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        DeleteWarningItem(icon: "person.2.slash", text: "All friendships and friend requests")
                        DeleteWarningItem(icon: "figure.walk", text: "Challenge memberships and history")
                        DeleteWarningItem(icon: "chart.bar.fill", text: "All step data and statistics")
                        DeleteWarningItem(icon: "message.fill", text: "Challenge messages and chats")
                        DeleteWarningItem(icon: "bell.slash.fill", text: "Notifications and invites")
                        DeleteWarningItem(icon: "person.crop.circle.badge.xmark", text: "Your profile and account")
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                )
                
                // Confirmation Text Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type DELETE to confirm:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("DELETE", text: $confirmationText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.system(size: 16, weight: .bold))
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onConfirm()
                    }) {
                        HStack {
                            if isDeletingAccount {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Deleting...")
                                    .font(.system(size: 16, weight: .bold))
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete Account Forever")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            confirmationText.uppercased() == "DELETE" && !isDeletingAccount 
                                ? Color.red 
                                : Color.gray
                        )
                        .cornerRadius(12)
                    }
                    .disabled(confirmationText.uppercased() != "DELETE" || isDeletingAccount)
                    
                    Button(action: {
                        confirmationText = ""
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .disabled(isDeletingAccount)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .navigationBarHidden(true)
        }
    }
}

struct DeleteWarningItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct DeleteAccountConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteAccountConfirmationView(
            confirmationText: .constant(""),
            onConfirm: {},
            isDeletingAccount: false
        )
    }
}

