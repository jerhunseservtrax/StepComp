//
//  ExerciseDBService.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 3/12/26.
//

import Foundation
import UIKit

enum ExerciseDBConfig {
    static let functionName = SupabaseConfig.exerciseDBEdgeFunctionName
}

final class ExerciseDBService {
    static let shared = ExerciseDBService()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("exercise_gifs", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        memoryCache.countLimit = 50
    }

    func loadGif(exerciseDBId: String, resolution: Int = 180) async -> Data? {
        let cacheKey = "\(exerciseDBId)_\(resolution)"

        if let cached = loadFromDiskCache(key: cacheKey) {
            return cached
        }

        do {
            let data = try await EdgeFunctionService.shared.postData(
                functionName: ExerciseDBConfig.functionName,
                payload: [
                    "exerciseId": exerciseDBId,
                    "resolution": resolution
                ]
            )
            saveToDiskCache(data: data, key: cacheKey)
            return data
        } catch {
            return nil
        }
    }

    private func diskCachePath(for key: String) -> URL {
        cacheDirectory.appendingPathComponent("\(key).gif")
    }

    private func loadFromDiskCache(key: String) -> Data? {
        let path = diskCachePath(for: key)
        guard fileManager.fileExists(atPath: path.path) else { return nil }
        return try? Data(contentsOf: path)
    }

    private func saveToDiskCache(data: Data, key: String) {
        let path = diskCachePath(for: key)
        try? data.write(to: path)
    }
}
