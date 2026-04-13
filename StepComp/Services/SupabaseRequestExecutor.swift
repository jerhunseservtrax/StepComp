import Foundation

enum SupabaseRequestExecutor {
    @MainActor
    static func executeWithAuthRetry<T>(
        context: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
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

            return try await operation()
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
