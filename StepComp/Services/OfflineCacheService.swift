//
//  OfflineCacheService.swift
//  FitComp
//
//  Generic disk-backed cache for Codable values.
//  Provides offline resilience: write-through on success, read-back on failure.
//

import Foundation

enum OfflineCacheService {
    private static let fileManager = FileManager.default

    private static var cacheDirectory: URL {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FitCompOfflineCache", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        let url = cacheDirectory.appendingPathComponent(safeName(key) + ".json")
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            #if DEBUG
            print("⚠️ OfflineCache save failed for \(key): \(error.localizedDescription)")
            #endif
        }
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent(safeName(key) + ".json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func remove(key: String) {
        let url = cacheDirectory.appendingPathComponent(safeName(key) + ".json")
        try? fileManager.removeItem(at: url)
    }

    static func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }

    /// Fetch from the network; on success cache the result, on failure return cached data.
    static func fetchWithFallback<T: Codable>(
        key: String,
        fetch: () async throws -> T
    ) async -> T? {
        do {
            let value = try await fetch()
            save(value, key: key)
            return value
        } catch {
            #if DEBUG
            print("⚠️ OfflineCache network failed for \(key), using cached data")
            #endif
            return load(T.self, key: key)
        }
    }

    /// Fetch an array from the network; on success cache, on failure return cached copy or empty.
    static func fetchArrayWithFallback<T: Codable>(
        key: String,
        fetch: () async throws -> [T]
    ) async -> [T] {
        do {
            let value = try await fetch()
            save(value, key: key)
            return value
        } catch {
            #if DEBUG
            print("⚠️ OfflineCache network failed for \(key), using cached data")
            #endif
            return load([T].self, key: key) ?? []
        }
    }

    private static func safeName(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
