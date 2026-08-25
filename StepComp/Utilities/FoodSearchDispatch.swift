//
//  FoodSearchDispatch.swift
//  FitComp
//
//  Keeps food-log searches from clobbering each other.
//  Barcode fills must not start a live text search, and only the newest
//  in-flight lookup may publish searchResults.
//

import Foundation

enum FoodQueryChangeSource {
    case userTyping
    case barcodeFill
}

enum FoodSearchDispatch {
    static func shouldScheduleLiveTextSearch(source: FoodQueryChangeSource) -> Bool {
        source == .userTyping
    }
}

struct FoodSearchGeneration {
    private(set) var value: UInt = 0

    mutating func begin() -> UInt {
        value += 1
        return value
    }

    func isCurrent(_ token: UInt) -> Bool {
        token == value
    }
}
