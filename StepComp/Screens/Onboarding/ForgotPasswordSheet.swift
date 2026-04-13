//
//  ForgotPasswordSheet.swift
//  FitComp
//
//  Extracted from SignInView.swift for maintainability.
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif
import Foundation

struct ForgotPasswordSheet: View {
    @Binding var email: String
    @State private var resetEmail: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(FitCompColors.primary.opacity(0.2))
                                .frame(width: 128, height: 128)
                            
                            Image(systemName: "key.fill")
                                .font(.system(size: 52, weight: .medium))
                                .foregroundColor(FitCompColors.primary)
                        }
                        .padding(.top, 40)
                        
                        // Title and Description
                        VStack(spacing: 12) {
                            Text("Forgot Password?")
                                .font(.system(size: 32, weight: .bold))
                            
                    Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(.system(size: 16))
                        .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 24)
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                                
                                TextField("your.email@example.com", text: $resetEmail)
                        .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // Error or Success Message
                        if let errorMessage = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        if let successMessage = successMessage {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(successMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }
                                
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Got it")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Send Reset Link Button
                        if successMessage == nil {
                    Button(action: {
                        Task {
                            await resetPassword()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .tint(.black)
                            }
                            Text("Send Reset Link")
                                        .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(FitCompColors.primary)
                                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                                .cornerRadius(12)
                    }
                    .disabled(isLoading || resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity((isLoading || resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1.0)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                resetEmail = email
            }
        }
    }
    
    private func resetPassword() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let trimmedEmail = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            isLoading = false
            return
        }
        
        // Validate email format
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            errorMessage = "Please enter a valid email address."
            isLoading = false
            return
        }
        
        do {
            #if canImport(Supabase)
            // Use custom URL scheme for deep link
            let redirectURL = URL(string: "je.fitcomp://reset-password")!
            try await supabase.auth.resetPasswordForEmail(
                trimmedEmail,
                redirectTo: redirectURL
            )
            
            // ✅ Security Best Practice: Never reveal if email exists
            // Always show success message regardless of whether account exists
            successMessage = "If an account with that email exists, you'll receive a password reset link shortly. Please check your inbox and spam folder."
            #else
            // Mock implementation
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            successMessage = "If an account with that email exists, you'll receive a password reset link shortly."
            #endif
        } catch {
            // ✅ Security Best Practice: Generic error message
            // Don't reveal specific errors that might leak information
            print("⚠️ Password reset error: \(error.localizedDescription)")
            successMessage = "If an account with that email exists, you'll receive a password reset link shortly."
        }
        
        isLoading = false
    }
}
