//
//  WeightEntry.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import Foundation

struct WeightEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let weightKg: Double  // Store in kg internally (matches workout weight storage)
    let source: WeightSource
    
    enum WeightSource: String, Codable {
        case manual      // User entered manually
        case healthKit   // Synced from HealthKit
    }
    
    init(id: UUID = UUID(), date: Date, weightKg: Double, source: WeightSource) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.source = source
    }
}
