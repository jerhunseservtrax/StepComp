//
//  TransformationPhoto.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import Foundation

enum PhotoAngle: String, Codable, CaseIterable {
    case front = "Front"
    case side = "Side"
    case back = "Back"
}

struct TransformationPhoto: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let frontFilename: String  // Stored in Documents/transformation_photos/{filename}
    let sideFilename: String
    let backFilename: String
    var note: String?
    
    init(id: UUID = UUID(), date: Date, frontFilename: String, sideFilename: String, backFilename: String, note: String? = nil) {
        self.id = id
        self.date = date
        self.frontFilename = frontFilename
        self.sideFilename = sideFilename
        self.backFilename = backFilename
        self.note = note
    }
}
