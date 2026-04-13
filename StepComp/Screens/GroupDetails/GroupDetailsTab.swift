//
//  GroupDetailsTab.swift
//  FitComp
//

import SwiftUI

enum GroupDetailTab: String, CaseIterable {
    case leaderboard
    case members
    case settings

    var displayName: String {
        switch self {
        case .leaderboard: return "Leaderboard"
        case .members: return "Members"
        case .settings: return "Settings"
        }
    }
}
