import Foundation

enum SupabaseRequestExecutor {
    @MainActor
    static func executeWithAuthRetry<T>(
        context: String,
        expectedUserId: String? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try validateExpectedUser(expectedUserId)
        do {
            return try await operation()
        } catch {
            guard shouldRetryAfter401(error) else {
                throw error
            }

            let refreshed = await AuthService.shared.refreshSessionOn401()
            guard refreshed else {
                throw error
            }

            try validateExpectedUser(expectedUserId)
            return try await operation()
        }
    }

    private static func validateExpectedUser(_ expectedUserId: String?) throws {
        guard let expectedUserId else { return }
        guard AuthService.shared.currentUser?.id == expectedUserId else {
            throw NSError(
                domain: "SupabaseRequestExecutor",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Authenticated user changed before retryable request completed"]
            )
        }
    }

    private static func shouldRetryAfter401(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("401")
            || message.contains("jwt")
            || message.contains("token")
            || message.contains("unauthorized")
    }
}
