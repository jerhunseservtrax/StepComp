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
    private init() {}

    @Published var pendingInviteToken: String?
    @Published var pendingPasswordResetURL: URL?

    private func isValidInviteToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (8...128).contains(trimmed.count) else { return false }
        let pattern = "^[A-Za-z0-9_-]+$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    func handle(url: URL) {
        let scheme = url.scheme ?? ""
        let host = url.host ?? ""
        
        // Handle friend invite links
        // je.fitcomp://friend-invite?token=ABC123
        if (scheme == "je.fitcomp" || scheme == "fitcomp") && host == "friend-invite" {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let token = comps.queryItems?.first(where: { $0.name == "token" })?.value,
               isValidInviteToken(token) {
                pendingInviteToken = token
                print("🔗 Friend invite token detected: \(token)")
            }
            return
        }
        
        // Handle password reset links
        // je.fitcomp://reset-password#access_token=...&type=recovery
        if (scheme == "je.fitcomp" || scheme == "fitcomp") && host == "reset-password" {
            pendingPasswordResetURL = url
            print("🔑 Password reset URL detected")
            return
        }
        
        // Handle universal links (future)
        // https://fitcomp.app/invite/friend/ABC123
        if scheme == "https" && (host == "fitcomp.app" || host == "www.fitcomp.app") {
            let pathComponents = url.pathComponents
            
            // Friend invite: /invite/friend/TOKEN
            if pathComponents.count >= 4 && pathComponents[1] == "invite" && pathComponents[2] == "friend" {
                let token = pathComponents[3]
                if isValidInviteToken(token) {
                    pendingInviteToken = token
                    print("🔗 Universal friend invite link detected: \(token)")
                }
                return
            }
            
            // Legacy format: /friend-invite/TOKEN (for backward compatibility)
            if pathComponents.count >= 3 && pathComponents[1] == "friend-invite" {
                let token = pathComponents[2]
                if isValidInviteToken(token) {
                    pendingInviteToken = token
                    print("🔗 Universal friend invite link detected (legacy): \(token)")
                }
                return
            }
            
            // Password reset: /reset-password
            if pathComponents.contains("reset-password") {
                pendingPasswordResetURL = url
                print("🔑 Universal password reset link detected")
                return
            }
        }
    }
}

