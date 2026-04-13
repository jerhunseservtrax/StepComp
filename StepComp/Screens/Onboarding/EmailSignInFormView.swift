//
//  EmailSignInFormView.swift
//  FitComp
//
//  Extracted from SignInView.swift for maintainability.
//

import SwiftUI

struct EmailSignInFormView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoading: Bool
    let errorMessage: String?
    @Binding var showingForgotPassword: Bool
    let onSignIn: () -> Void
    let onForgotPassword: () -> Void
    let onBack: () -> Void
    let onSwitchToSignUp: () -> Void
    let onAppleSignIn: () -> Void
    
    @State private var showingPassword: Bool = false
    @Environment(\.colorScheme) private var currentColorScheme
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                FitCompColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        VStack(spacing: 24) {
                            // Circular background with email icon
                            ZStack {
                                // Outer glow circle
                                Circle()
                                    .fill(FitCompColors.primary.opacity(0.2))
                                    .frame(width: 128, height: 128)
                                
                                // Pulsing animation circle
                                Circle()
                                    .fill(FitCompColors.primary.opacity(0.1))
                                    .frame(width: 128, height: 128)
                                    .scaleEffect(1.2)
                                    .opacity(0.5)
                                
                                // Email icon
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 52, weight: .medium))
                                        .foregroundColor(FitCompColors.primary)
                            }
                            
                            // Title and Subtitle
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.system(size: 32, weight: .black))
                                    .tracking(-0.5)
                                
                                Text("Continue your step journey.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    TextField("name@example.com", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    if showingPassword {
                                        TextField("Enter your password", text: $password)
                                            .textContentType(.password)
                                            .foregroundColor(.primary)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .textContentType(.password)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Button(action: {
                                        showingPassword.toggle()
                                    }) {
                                        Image(systemName: showingPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        
                        // Forgot Password Link
                        HStack {
                            Spacer()
                            Button(action: onForgotPassword) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(currentColorScheme == .light ? .black : FitCompColors.primary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Error Message
                        if let errorMessage = errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                        }
                        
                        // Sign In Button
                        Button(action: onSignIn) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 18, weight: .black))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(FitCompColors.primary)
                            .foregroundColor(FitCompColors.buttonTextOnPrimary)
                            .cornerRadius(12)
                            .shadow(color: FitCompColors.primary.opacity(0.39), radius: 14, x: 0, y: 4)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Or sign in with")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Social Login Buttons
                        HStack(spacing: 16) {
                            // Apple Sign In
                            Button(action: onAppleSignIn) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.bottom, 32)
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Button(action: onSwitchToSignUp) {
                                Text("Sign Up")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(currentColorScheme == .light ? .black : FitCompColors.primary)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Sign In")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
