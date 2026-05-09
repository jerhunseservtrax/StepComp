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

    static func save<T: Encodable>(_ value: T, key: String, userId: String?) {
        guard let key = userScopedKey(key, userId: userId) else { return }
        save(value, key: key)
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent(safeName(key) + ".json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func load<T: Decodable>(_ type: T.Type, key: String, userId: String?) -> T? {
        guard let key = userScopedKey(key, userId: userId) else { return nil }
        return load(type, key: key)
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

    /// Fetch user-owned data with an account-scoped cache key.
    /// Without a user id, failures must not fall back to another account's payload.
    static func fetchWithFallback<T: Codable>(
        key: String,
        userId: String?,
        fetch: () async throws -> T
    ) async -> T? {
        do {
            let value = try await fetch()
            save(value, key: key, userId: userId)
            return value
        } catch {
            #if DEBUG
            print("⚠️ OfflineCache network failed for \(key), using user-scoped cached data")
            #endif
            return load(T.self, key: key, userId: userId)
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

    /// Fetch a user-owned array with an account-scoped cache key.
    static func fetchArrayWithFallback<T: Codable>(
        key: String,
        userId: String?,
        fetch: () async throws -> [T]
    ) async -> [T] {
        do {
            let value = try await fetch()
            save(value, key: key, userId: userId)
            return value
        } catch {
            #if DEBUG
            print("⚠️ OfflineCache network failed for \(key), using user-scoped cached data")
            #endif
            return load([T].self, key: key, userId: userId) ?? []
        }
    }

    private static func userScopedKey(_ key: String, userId: String?) -> String? {
        guard let userId, !userId.isEmpty else { return nil }
        return "user_\(safeName(userId))__\(key)"
    }

    private static func safeName(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
