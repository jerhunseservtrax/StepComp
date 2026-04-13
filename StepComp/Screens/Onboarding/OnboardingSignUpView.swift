//
//  OnboardingSignUpView.swift
//  FitComp
//
//  Extracted from SignInView.swift for maintainability.
//

import SwiftUI

struct SignUpView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var username: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var height: String
    @Binding var weight: String
    @Binding var isLoading: Bool
    let errorMessage: String?
    @Binding var showingPassword: Bool
    @Binding var showingConfirmPassword: Bool
    let onSignUp: () -> Void
    let onBack: () -> Void
    let onSwitchToSignIn: () -> Void
    let onAppleSignIn: () -> Void
    
    @State private var fullName: String = ""
    @ObservedObject private var unitManager = UnitPreferenceManager.shared
    
    
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
                                Text("Join the Step Squad")
                                    .font(.system(size: 32, weight: .black))
                                    .tracking(-0.5)
                                
                                Text("Track every step, reach every goal.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Full Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    TextField("What should we call you?", text: $fullName)
                                        .textContentType(.name)
                                        .foregroundColor(.primary)
                                        .onChange(of: fullName) { oldValue, newValue in
                                            // Split full name into first and last
                                            let components = newValue.split(separator: " ", maxSplits: 1)
                                            firstName = components.first.map(String.init) ?? ""
                                            lastName = components.count > 1 ? String(components[1]) : ""
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
                            
                            // Username
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "at")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    TextField("Choose a username", text: $username)
                                        .textContentType(.username)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .foregroundColor(.primary)
                                        .onChange(of: username) { oldValue, newValue in
                                            // Auto-lowercase and remove spaces
                                            username = newValue.lowercased().replacingOccurrences(of: " ", with: "")
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
                                        TextField("Create a password", text: $password)
                                            .textContentType(.newPassword)
                                            .foregroundColor(.primary)
                                    } else {
                                        SecureField("Create a password", text: $password)
                                            .textContentType(.newPassword)
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
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    SecureField("Repeat password", text: $confirmPassword)
                                        .textContentType(.newPassword)
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
                            
                            // Height and Weight
                            VStack(spacing: 16) {
                                // Height
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(unitManager.unitSystem == .metric ? "Height (cm)" : "Height")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    if unitManager.unitSystem == .metric {
                                        HStack {
                                            Image(systemName: "ruler")
                                                .foregroundColor(.secondary)
                                                .frame(width: 24)
                                            
                                            TextField("175", text: $height)
                                                .keyboardType(.numberPad)
                                                .foregroundColor(.primary)
                                            
                                            Text("cm")
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 56)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    } else {
                                        HStack(spacing: 12) {
                                            HStack {
                                                Image(systemName: "ruler")
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 24)
                                                
                                                TextField("5", text: Binding(
                                                    get: {
                                                        guard let cm = Int(height), cm > 0 else { return "" }
                                                        return "\(unitManager.heightComponents(fromCm: cm).feet)"
                                                    },
                                                    set: { newValue in
                                                        guard let feet = Int(newValue) else { return }
                                                        let currentCm = Int(height) ?? 0
                                                        let current = unitManager.heightComponents(fromCm: currentCm)
                                                        height = "\(unitManager.heightToStorage(feet: feet, inches: current.inches))"
                                                    }
                                                ))
                                                .keyboardType(.numberPad)
                                                .foregroundColor(.primary)
                                                
                                                Text("ft")
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.horizontal, 16)
                                            .frame(height: 56)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(.systemGray4), lineWidth: 1)
                                            )
                                            
                                            HStack {
                                                TextField("10", text: Binding(
                                                    get: {
                                                        guard let cm = Int(height), cm > 0 else { return "" }
                                                        return "\(unitManager.heightComponents(fromCm: cm).inches)"
                                                    },
                                                    set: { newValue in
                                                        guard let inches = Int(newValue) else { return }
                                                        let currentCm = Int(height) ?? 0
                                                        let current = unitManager.heightComponents(fromCm: currentCm)
                                                        height = "\(unitManager.heightToStorage(feet: current.feet, inches: inches))"
                                                    }
                                                ))
                                                .keyboardType(.numberPad)
                                                .foregroundColor(.primary)
                                                
                                                Text("in")
                                                    .foregroundColor(.gray)
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
                                }
                                
                                // Weight
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(unitManager.unitSystem == .metric ? "Weight (kg)" : "Weight (lbs)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Image(systemName: "scalemass")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)
                                        
                                        TextField(unitManager.unitSystem == .metric ? "70" : "150", text: Binding(
                                            get: {
                                                if let kg = Int(weight), kg > 0 {
                                                    return "\(unitManager.weightFromStorage(kg))"
                                                }
                                                return ""
                                            },
                                            set: { newValue in
                                                if let displayWeight = Int(newValue) {
                                                    weight = "\(unitManager.weightToStorage(displayWeight))"
                                                }
                                            }
                                        ))
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.primary)

                                        Text(unitManager.unitSystem == .metric ? "kg" : "lbs")
                                            .foregroundColor(.gray)
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
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Terms and Conditions
                        Text("By signing up, you agree to our Terms of Service and Privacy Policy in Settings > Legal and Support.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 24)
                        
                        // Error Message
                        if let errorMessage = errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                        }
                        
                        // Start Walking Button
                        Button(action: {
                            // Validate passwords match
                            if password != confirmPassword {
                                // Error will be shown
                                return
                            }
                            onSignUp()
                        }) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Start Walking")
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
                        .disabled(isLoading || fullName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Or sign up with")
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
                        
                        // Log In Link
                        HStack {
                            Text("Already have an account?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Button(action: onSwitchToSignIn) {
                                Text("Log In")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FitCompColors.primary)
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
                    Text("Sign Up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
