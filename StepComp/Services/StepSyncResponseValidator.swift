//
//  StepSyncResponseValidator.swift
//  FitComp
//

import Foundation

struct StepSyncEdgeFunctionResponse: Decodable {
    let success: Bool
    let data: EdgeData?
    let error: String?

    struct EdgeData: Decodable {
        let is_suspicious: Bool?
    }
}

enum StepSyncEdgeFunctionError: LocalizedError, Equatable {
    case failed(message: String)
    case sessionRefreshFailed

    var errorDescription: String? {
        switch self {
        case .failed(let message):
            return message
        case .sessionRefreshFailed:
            return "Unable to refresh the session before syncing steps."
        }
    }
}

enum StepSyncEdgeFunctionResponseValidator {
    static func ensureSuccess(_ response: StepSyncEdgeFunctionResponse) throws {
        guard response.success else {
            throw StepSyncEdgeFunctionError.failed(
                message: response.error ?? "Step sync Edge Function reported failure without an error message."
            )
        }
    }
}
