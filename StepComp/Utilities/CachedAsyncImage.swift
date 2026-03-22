//
//  CachedAsyncImage.swift
//  FitComp
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class ImageMemoryCache {
    static let shared = NSCache<NSURL, UIImage>()
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let loadedImage {
                content(Image(uiImage: loadedImage))
            } else {
                placeholder()
                    .task(id: url) {
                        await load()
                    }
            }
        }
    }

    private func load() async {
        guard let url else { return }
        if let cached = ImageMemoryCache.shared.object(forKey: url as NSURL) {
            loadedImage = cached
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                ImageMemoryCache.shared.setObject(image, forKey: url as NSURL)
                loadedImage = image
            }
        } catch {
            return
        }
    }
}
