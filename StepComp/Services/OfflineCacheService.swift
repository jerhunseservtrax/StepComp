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
    private static var userScope: String?

    private static var cacheDirectory: URL {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FitCompOfflineCache", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func setUserScope(_ userId: String) {
        userScope = userId
    }

    static func clearUserScope() {
        userScope = nil
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        save(value, key: key, scope: userScope)
    }

    private static func save<T: Encodable>(_ value: T, key: String, scope: String?) {
        guard scope == userScope else { return }
        guard let fileName = scopedSafeName(key, scope: scope) else { return }
        let url = cacheDirectory.appendingPathComponent(fileName + ".json")
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
        load(type, key: key, scope: userScope)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, scope: String?) -> T? {
        guard scope == userScope else { return nil }
        guard let fileName = scopedSafeName(key, scope: scope) else { return nil }
        let url = cacheDirectory.appendingPathComponent(fileName + ".json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func remove(key: String) {
        let scope = userScope
        guard let fileName = scopedSafeName(key, scope: scope) else { return }
        let url = cacheDirectory.appendingPathComponent(fileName + ".json")
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
        let scope = userScope
        do {
            let value = try await fetch()
            guard scope == userScope else { return nil }
            save(value, key: key, scope: scope)
            return value
        } catch {
            guard scope == userScope else { return nil }
            #if DEBUG
            print("⚠️ OfflineCache network failed for \(key), using cached data")
            #endif
            return load(T.self, key: key, scope: scope)
        }
    }

    /// Fetch an array from the network; on success cache, on failure return cached copy or empty.
    static func fetchArrayWithFallback<T: Codable>(
        key: String,
        fetch: () async throws -> [T]
    ) async -> [T] {
        let scope = userScope
        do {
            let value = try await fetch()
            guard scope == userScope else { return [] }
            save(value, key: key, scope: scope)
            return value
        } catch {
            guard scope == userScope else { return [] }
            #if DEBUG
            print("⚠️ OfflineCache network failed for \(key), using cached data")
            #endif
            return load([T].self, key: key, scope: scope) ?? []
        }
    }

    private static func safeName(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }

    private static func scopedSafeName(_ key: String, scope: String?) -> String? {
        guard let scope, !scope.isEmpty else {
            #if DEBUG
            print("⚠️ OfflineCache skipped unscoped access for \(key)")
            #endif
            return nil
        }
        return safeName("user_\(scope)_\(key)")
    }
}
