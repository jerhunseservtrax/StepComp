//
//  DeepLinkRouter.swift
//  StepComp
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

    func handle(url: URL) {
        let scheme = url.scheme ?? ""
        let host = url.host ?? ""
        
        // Handle friend invite links
        // je.stepcomp://friend-invite?token=ABC123
        if (scheme == "je.stepcomp" || scheme == "stepcomp") && host == "friend-invite" {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let token = comps.queryItems?.first(where: { $0.name == "token" })?.value,
               !token.isEmpty {
                pendingInviteToken = token
                print("🔗 Friend invite token detected: \(token)")
            }
            return
        }
        
        // Handle password reset links
        // je.stepcomp://reset-password#access_token=...&type=recovery
        if (scheme == "je.stepcomp" || scheme == "stepcomp") && host == "reset-password" {
            pendingPasswordResetURL = url
            print("🔑 Password reset URL detected")
            return
        }
        
        // Handle universal links (future)
        // https://stepcomp.app/friend-invite/ABC123
        if scheme == "https" && (host == "stepcomp.app" || host == "www.stepcomp.app") {
            let pathComponents = url.pathComponents
            
            // Friend invite: /friend-invite/TOKEN
            if pathComponents.count >= 3 && pathComponents[1] == "friend-invite" {
                let token = pathComponents[2]
                pendingInviteToken = token
                print("🔗 Universal friend invite link detected: \(token)")
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

