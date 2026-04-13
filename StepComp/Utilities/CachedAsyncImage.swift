//
//  CachedAsyncImage.swift
//  FitComp
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class ImageMemoryCache {
    static let shared: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()
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
                let downsampled = image.downsampled(maxPixelSize: 768) ?? image
                let cost = Int(downsampled.size.width * downsampled.size.height * downsampled.scale * downsampled.scale * 4)
                ImageMemoryCache.shared.setObject(downsampled, forKey: url as NSURL, cost: cost)
                loadedImage = downsampled
            }
        } catch {
            return
        }
    }
}

private extension UIImage {
    func downsampled(maxPixelSize: CGFloat) -> UIImage? {
        let maxDimension = max(size.width, size.height)
        guard maxDimension > maxPixelSize else { return self }
        let scale = maxPixelSize / maxDimension
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
