//
//  OAuthLogSanitizer.swift
//  FitComp
//
//  Prevents OAuth credentials from being written to device logs.
//

import Foundation

enum OAuthLogSanitizer {
    static func redactedDescription(for url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "<invalid-url>"
        }

        let hadQuery = components.percentEncodedQuery != nil
        let hadFragment = components.percentEncodedFragment != nil
        components.percentEncodedQuery = nil
        components.percentEncodedFragment = nil

        var description = components.string ?? "<invalid-url>"
        if hadQuery {
            description += "?<redacted>"
        }
        if hadFragment {
            description += "#<redacted>"
        }
        return description
    }
}
