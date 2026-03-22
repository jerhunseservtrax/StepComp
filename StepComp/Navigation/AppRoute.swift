//
//  AppRoute.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine

enum AppRoute: Hashable {
    case home
    case leaderboard(challengeId: String)
    case createChallenge
    case joinChallenge
    case groupDetails(challengeId: String)
    case profile
    case settings
}

