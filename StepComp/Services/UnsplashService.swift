//
//  UnsplashService.swift
//  FitComp
//

import Foundation

private enum UnsplashConfig {
    static let searchURL = URL(string: "https://api.unsplash.com/search/photos")!

    static var accessKey: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "UNSPLASH_ACCESS_KEY") as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

private struct UnsplashPhoto: Decodable {
    let urls: UnsplashURLs
}

private struct UnsplashURLs: Decodable {
    let regular: String
}

@MainActor
final class UnsplashService {
    static let shared = UnsplashService()
    private init() {}

    func fetchFoodImageURL(for foodName: String) async -> URL? {
        guard let accessKey = UnsplashConfig.accessKey else {
            return nil
        }

        let trimmedFoodName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFoodName.isEmpty else {
            return nil
        }

        var components = URLComponents(url: UnsplashConfig.searchURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: "\(trimmedFoodName) food"),
            URLQueryItem(name: "per_page", value: "1"),
            URLQueryItem(name: "orientation", value: "portrait")
        ]

        guard let url = components?.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }

            let decoded = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
            guard let imageURLString = decoded.results.first?.urls.regular else {
                return nil
            }

            return URL(string: imageURLString)
        } catch {
            return nil
        }
    }
}
