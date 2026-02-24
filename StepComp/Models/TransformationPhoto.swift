//
//  TransformationPhoto.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import Foundation

struct TransformationPhoto: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let filename: String  // Stored in Documents/transformation_photos/{filename}
    var note: String?
    
    init(id: UUID = UUID(), date: Date, filename: String, note: String? = nil) {
        self.id = id
        self.date = date
        self.filename = filename
        self.note = note
    }
}
