//
//  SensitiveURLRedactor.swift
//  FitComp
//
//  Keeps OAuth and deep-link logging from exposing bearer credentials.
//

import Foundation

enum SensitiveURLRedactor {
    private static let sensitiveNames: Set<String> = [
        "access_token",
        "refresh_token",
        "id_token",
        "token",
        "code",
        "provider_token",
        "provider_refresh_token"
    ]

    static func redacted(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "[invalid-url]"
        }

        components.queryItems = redactedItems(components.queryItems)

        if let fragment = components.percentEncodedFragment {
            components.percentEncodedFragment = redactedFragment(fragment)
        }

        return components.string ?? "[invalid-url]"
    }

    private static func redactedItems(_ items: [URLQueryItem]?) -> [URLQueryItem]? {
        items?.map { item in
            if sensitiveNames.contains(item.name.lowercased()) {
                return URLQueryItem(name: item.name, value: "[REDACTED]")
            }
            return item
        }
    }

    private static func redactedFragment(_ fragment: String) -> String {
        var fragmentComponents = URLComponents()
        fragmentComponents.percentEncodedQuery = fragment
        fragmentComponents.queryItems = redactedItems(fragmentComponents.queryItems)
        return fragmentComponents.percentEncodedQuery ?? "[REDACTED]"
    }
}
