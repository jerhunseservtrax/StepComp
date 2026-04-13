//
//  EmailAuthSheet.swift
//  FitComp
//
//  Extracted from SignInView.swift for maintainability.
//

import SwiftUI

struct EmailAuthSheet: View {
    @Binding var isSignUp: Bool
    @Binding var email: String
    @Binding var password: String
    @Binding var username: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var height: String
    @Binding var weight: String
    @Binding var isLoading: Bool
    let errorMessage: String?
    @Binding var showingForgotPassword: Bool
    let onSignIn: () -> Void
    let onSignUp: () -> Void
    let onForgotPassword: () -> Void
    let onAppleSignIn: () -> Void
    
    @State private var confirmPassword: String = ""
    @State private var showingPassword: Bool = false
    @State private var showingConfirmPassword: Bool = false
    @Environment(\.colorScheme) private var currentColorScheme
    
    @Environment(\.dismiss) var dismiss
    
    private let backgroundDark = Color(red: 0.137, green: 0.133, blue: 0.059) // #23220f
    private let inputDark = Color(red: 0.208, green: 0.204, blue: 0.094) // #353418
    private let inputBorder = Color(red: 0.416, green: 0.412, blue: 0.184) // #6a692f
    
    var body: some View {
        if isSignUp {
            SignUpView(
                email: $email,
                password: $password,
                confirmPassword: $confirmPassword,
                username: $username,
                firstName: $firstName,
                lastName: $lastName,
                height: $height,
                weight: $weight,
                isLoading: $isLoading,
                errorMessage: errorMessage,
                showingPassword: $showingPassword,
                showingConfirmPassword: $showingConfirmPassword,
                onSignUp: onSignUp,
                onBack: { dismiss() },
                onSwitchToSignIn: {
                    isSignUp = false
                },
                onAppleSignIn: onAppleSignIn
            )
        } else {
            EmailSignInFormView(
                email: $email,
                password: $password,
                isLoading: $isLoading,
                errorMessage: errorMessage,
                showingForgotPassword: $showingForgotPassword,
                onSignIn: onSignIn,
                onForgotPassword: onForgotPassword,
                onBack: { dismiss() },
                onSwitchToSignUp: {
                    isSignUp = true
                },
                onAppleSignIn: onAppleSignIn
            )
        }
    }
}
