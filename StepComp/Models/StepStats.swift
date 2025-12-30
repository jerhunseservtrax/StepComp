//
//  StepStats.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

struct StepStats: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let challengeId: String?
    var date: Date
    var steps: Int
    var distance: Double // in meters
    var activeMinutes: Int
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        challengeId: String? = nil,
        date: Date = Date(),
        steps: Int = 0,
        distance: Double = 0,
        activeMinutes: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.challengeId = challengeId
        self.date = date
        self.steps = steps
        self.distance = distance
        self.activeMinutes = activeMinutes
    }
}

