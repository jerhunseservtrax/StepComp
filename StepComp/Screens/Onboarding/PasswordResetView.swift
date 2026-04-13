//
//  PasswordResetView.swift
//  FitComp
//
//  Extracted from SignInView.swift for maintainability.
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct PasswordResetView: View {
    let resetURL: URL
    let onComplete: () -> Void
    
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showingPassword: Bool = false
    @State private var showingConfirmPassword: Bool = false
    
    @EnvironmentObject var authService: AuthService
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 64))
                                .foregroundColor(FitCompColors.primary)
                            
                            Text("Reset Your Password")
                                .font(.system(size: 32, weight: .bold))
                            
                            Text("Enter your new password below")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Password Fields
                        VStack(spacing: 20) {
                            // New Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New Password")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    if showingPassword {
                                        TextField("Enter new password", text: $newPassword)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Enter new password", text: $newPassword)
                                            .textContentType(.newPassword)
                                    }
                                    
                                    Button(action: {
                                        showingPassword.toggle()
                                    }) {
                                        Image(systemName: showingPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    if showingConfirmPassword {
                                        TextField("Confirm new password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Confirm new password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    }
                                    
                                    Button(action: {
                                        showingConfirmPassword.toggle()
                                    }) {
                                        Image(systemName: showingConfirmPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error Message
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
                
                        // Success Message
                if let successMessage = successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                    .font(.system(size: 14))
                                .foregroundColor(.green)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Reset Button
                        Button(action: {
                            Task {
                                await resetPassword()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Reset Password")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(FitCompColors.primary)
                            .foregroundColor(FitCompColors.buttonTextOnPrimary)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Password Requirements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password Requirements:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Text("• At least 8 characters")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("• At least one letter")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("• At least one number")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete()
                    }
                }
            }
        }
    }
    
    private func resetPassword() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Validate passwords
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password"
            isLoading = false
            return
        }
        
        // ✅ Security Best Practice: Enforce strong password requirements
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return
        }
        
        // Validate password strength
        let hasLetter = newPassword.rangeOfCharacter(from: .letters) != nil
        let hasNumber = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
        
        guard hasLetter && hasNumber else {
            errorMessage = "Password must contain at least one letter and one number"
            isLoading = false
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }
        
        do {
            #if canImport(Supabase)
            // Supabase password reset URLs contain tokens in the fragment
            // Parse the URL to extract tokens
            let components = URLComponents(url: resetURL, resolvingAgainstBaseURL: false)
            var accessToken: String?
            var refreshToken: String?
            
            // Extract tokens from URL fragment (common format)
            if let fragment = components?.fragment {
                let params = fragment.components(separatedBy: "&")
                for param in params {
                    let parts = param.components(separatedBy: "=")
                    if parts.count == 2 {
                        if parts[0] == "access_token" {
                            accessToken = parts[1].removingPercentEncoding
                        } else if parts[0] == "refresh_token" {
                            refreshToken = parts[1].removingPercentEncoding
                        }
                    }
                }
            }
            
            // Extract from query parameters (alternative format)
            if accessToken == nil, let queryItems = components?.queryItems {
                for item in queryItems {
                    if item.name == "access_token" {
                        accessToken = item.value
                    } else if item.name == "refresh_token" {
                        refreshToken = item.value
                    }
                }
            }
            
            guard let accessToken = accessToken, let refreshToken = refreshToken else {
                errorMessage = "Invalid reset link. Please request a new password reset email."
                isLoading = false
                return
            }
            
            // Set the session with tokens from reset URL
            try await supabase.auth.setSession(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
            
            // Wait a moment for session to be established
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Update the password
            try await supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )
            
            successMessage = "Password updated successfully! You can now sign in with your new password."
            
            // ✅ Security Best Practice: Invalidate old sessions after password reset
            // Supabase automatically invalidates old sessions when password is updated
            
            // Wait to show success message
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                onComplete()
            }
            #else
            errorMessage = "Password reset is not available in mock mode"
            #endif
        } catch {
            let errorMsg = error.localizedDescription
            print("⚠️ Password reset error: \(errorMsg)")
            
            // Provide user-friendly error messages
            if errorMsg.contains("session") || errorMsg.contains("expired") {
                errorMessage = "Your reset link has expired. Please request a new password reset link."
            } else if errorMsg.contains("same") {
                errorMessage = "New password must be different from your current password."
            } else {
                errorMessage = errorMsg.isEmpty ? "Failed to reset password. Please try again." : errorMsg
            }
        }
        
        isLoading = false
    }
}
