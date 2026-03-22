//
//  RetryUtility.swift
//  FitComp
//

import Foundation

enum RetryUtility {
    static func withExponentialBackoff<T>(
        maxAttempts: Int = 3,
        initialDelayNanoseconds: UInt64 = 300_000_000,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var delay = initialDelayNanoseconds
        var lastError: Error?

        while attempt < maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                attempt += 1
                if attempt >= maxAttempts { break }
                try? await Task.sleep(nanoseconds: delay)
                delay *= 2
            }
        }

        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
}
