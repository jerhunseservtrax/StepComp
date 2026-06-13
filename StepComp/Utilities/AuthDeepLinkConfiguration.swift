//
//  AuthDeepLinkConfiguration.swift
//  FitComp
//

import Foundation

enum AuthDeepLinkConfiguration {
    static let oauthCallbackScheme = "fitcomp"
    static let passwordResetRedirectURL = URL(string: "\(oauthCallbackScheme)://reset-password")!
}
