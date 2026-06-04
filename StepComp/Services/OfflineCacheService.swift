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
    private static let userScopeDefaultsKey = "fitcomp.offlineCache.userScope"

    private static var cacheDirectory: URL {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FitCompOfflineCache", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        let url = cacheURL(for: key)
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
        let url = cacheURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func remove(key: String) {
        let url = cacheURL(for: key)
        try? fileManager.removeItem(at: url)
    }

    static func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }

    @discardableResult
    static func setUserScope(userId: String?) -> Bool {
        let previousScope = currentScope()
        guard let userId, !userId.isEmpty else {
            UserDefaults.standard.removeObject(forKey: userScopeDefaultsKey)
            return previousScope != currentScope()
        }

        UserDefaults.standard.set(safeName(userId), forKey: userScopeDefaultsKey)
        return previousScope != currentScope()
    }

    static func scopedPersistenceKey(_ key: String) -> String {
        safeName(scopedKey(key, scope: currentScope()))
    }

    static func currentScopeToken() -> String {
        currentScope()
    }

    static func save<T: Encodable>(_ value: T, key: String, scopeToken: String) {
        save(value, key: key, scope: scopeToken)
    }

    static func load<T: Decodable>(_ type: T.Type, key: String, scopeToken: String) -> T? {
        load(type, key: key, scope: scopeToken)
    }

    /// Fetch from the network; on success cache the result, on failure return cached data.
    static func fetchWithFallback<T: Codable>(
        key: String,
        fetch: () async throws -> T
    ) async -> T? {
        let scope = currentScope()
        do {
            let value = try await fetch()
            guard currentScope() == scope else { return nil }
            save(value, key: key, scope: scope)
            return value
        } catch {
            #if DEBUG
            print("⚠️ OfflineCache network failed for \(key), using cached data")
            #endif
            guard currentScope() == scope else { return nil }
            return load(T.self, key: key, scope: scope)
        }
    }

    /// Fetch an array from the network; on success cache, on failure return cached copy or empty.
    static func fetchArrayWithFallback<T: Codable>(
        key: String,
        fetch: () async throws -> [T]
    ) async -> [T] {
        let scope = currentScope()
        do {
            let value = try await fetch()
            guard currentScope() == scope else { return [] }
            save(value, key: key, scope: scope)
            return value
        } catch {
            #if DEBUG
            print("⚠️ OfflineCache network failed for \(key), using cached data")
            #endif
            guard currentScope() == scope else { return [] }
            return load([T].self, key: key, scope: scope) ?? []
        }
    }

    private static func save<T: Encodable>(_ value: T, key: String, scope: String) {
        let url = cacheURL(for: key, scope: scope)
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            #if DEBUG
            print("⚠️ OfflineCache save failed for \(key): \(error.localizedDescription)")
            #endif
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, scope: String) -> T? {
        let url = cacheURL(for: key, scope: scope)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func cacheURL(for key: String) -> URL {
        cacheURL(for: key, scope: currentScope())
    }

    private static func cacheURL(for key: String, scope: String) -> URL {
        cacheDirectory.appendingPathComponent(safeName(scopedKey(key, scope: scope)) + ".json")
    }

    private static func scopedKey(_ key: String, scope: String) -> String {
        "\(scope)_\(key)"
    }

    private static func currentScope() -> String {
        UserDefaults.standard.string(forKey: userScopeDefaultsKey) ?? "anonymous"
    }

    private static func safeName(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
