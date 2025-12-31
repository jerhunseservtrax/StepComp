//
//  DebugLogger.swift
//  StepComp
//
//  Debug logging utility for writing NDJSON logs
//

import Foundation

extension String {
    func appendLineToFile(filePath: String) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Create directory if it doesn't exist
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Append or create file
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            fileHandle.seekToEndOfFile()
            if let data = self.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            // File doesn't exist, create it
            try self.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
    }
}

