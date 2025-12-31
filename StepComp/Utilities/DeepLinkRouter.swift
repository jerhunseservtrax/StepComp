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

    func handle(url: URL) {
        guard url.scheme == "je.stepcomp" || url.scheme == "stepcomp",
              url.host == "friend-invite",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = comps.queryItems?.first(where: { $0.name == "token" })?.value,
              !token.isEmpty
        else { return }

        pendingInviteToken = token
    }
}

