//
//  EdgeFunctionService.swift
//  FitComp
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

enum EdgeFunctionError: LocalizedError {
    case invalidResponse
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server."
        case .badStatus(let code):
            return "Request failed with status \(code)."
        }
    }
}

@MainActor
final class EdgeFunctionService {
    static let shared = EdgeFunctionService()
    private init() {}

    func postJSON<T: Decodable>(
        functionName: String,
        payload: [String: Any],
        decodeAs: T.Type
    ) async throws -> T {
        let data = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "edge_post_json") {
            try await self.performRequest(functionName: functionName, payload: payload, timeout: 20)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func postData(
        functionName: String,
        payload: [String: Any]
    ) async throws -> Data {
        try await SupabaseRequestExecutor.executeWithAuthRetry(context: "edge_post_data") {
            try await self.performRequest(functionName: functionName, payload: payload, timeout: 30)
        }
    }

    private func performRequest(
        functionName: String,
        payload: [String: Any],
        timeout: TimeInterval
    ) async throws -> Data {
        var request = URLRequest(url: SupabaseConfig.edgeFunctionsBaseURL.appendingPathComponent(functionName))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(try await bearerToken())", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeout
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw EdgeFunctionError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw EdgeFunctionError.badStatus(http.statusCode)
        }
        return data
    }

    private func bearerToken() async throws -> String {
        #if canImport(Supabase)
        let session = try await supabase.auth.session
        return session.accessToken
        #else
        return SupabaseConfig.supabaseAnonKey
        #endif
    }
}
