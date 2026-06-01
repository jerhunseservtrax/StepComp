//
//  DeepLinkRouter.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine

final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    static let passwordResetRedirectURL = URL(string: "fitcomp://reset-password")!
    private init() {}

    @Published var pendingInviteToken: String?
    @Published var pendingPasswordResetURL: URL?

    private func isValidInviteToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (8...128).contains(trimmed.count) else { return false }
        let pattern = "^[A-Za-z0-9_-]+$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    static func isPasswordResetURL(_ url: URL) -> Bool {
        let scheme = url.scheme ?? ""
        let host = url.host ?? ""

        if (scheme == "je.fitcomp" || scheme == "fitcomp") && host == "reset-password" {
            return true
        }

        if scheme == "https" && (host == "fitcomp.app" || host == "www.fitcomp.app" || host == "stepcomp.app" || host == "www.stepcomp.app") {
            return url.pathComponents.contains("reset-password")
        }

        return false
    }

    func handle(url: URL) {
        let scheme = url.scheme ?? ""
        let host = url.host ?? ""
        
        if (scheme == "je.fitcomp" || scheme == "fitcomp") && host == "friend-invite" {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let token = comps.queryItems?.first(where: { $0.name == "token" })?.value,
               isValidInviteToken(token) {
                pendingInviteToken = token
                #if DEBUG
                print("🔗 Friend invite token detected: \(token)")
                #endif
            }
            return
        }
        
        if Self.isPasswordResetURL(url) {
            pendingPasswordResetURL = url
            #if DEBUG
            print("🔑 Password reset URL detected")
            #endif
            return
        }
        
        if scheme == "https" && (host == "fitcomp.app" || host == "www.fitcomp.app" || host == "stepcomp.app" || host == "www.stepcomp.app") {
            let pathComponents = url.pathComponents
            
            if pathComponents.count >= 4 && pathComponents[1] == "invite" && pathComponents[2] == "friend" {
                let token = pathComponents[3]
                if isValidInviteToken(token) {
                    pendingInviteToken = token
                    #if DEBUG
                    print("🔗 Universal friend invite link detected")
                    #endif
                }
                return
            }
            
            if pathComponents.count >= 3 && pathComponents[1] == "friend-invite" {
                let token = pathComponents[2]
                if isValidInviteToken(token) {
                    pendingInviteToken = token
                    #if DEBUG
                    print("🔗 Universal friend invite link detected (legacy)")
                    #endif
                }
                return
            }
            
        }
    }
}

