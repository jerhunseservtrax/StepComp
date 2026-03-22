//
//  ProfileMetricsBuilder.swift
//  FitComp
//

import Foundation

struct ProfileMetricsBuilder {
    func weeklyFallback(maxSteps: Int = 10_000) -> [Int] {
        [
            Int(Double(maxSteps) * 0.45),
            Int(Double(maxSteps) * 0.65),
            Int(Double(maxSteps) * 0.30),
            Int(Double(maxSteps) * 0.85),
            maxSteps,
            Int(Double(maxSteps) * 0.20),
            Int(Double(maxSteps) * 0.10)
        ]
    }

    func monthlyFallback(days: Int = 30) -> [Int] {
        (0..<days).map { _ in Int.random(in: 2000...12_000) }
    }
}
