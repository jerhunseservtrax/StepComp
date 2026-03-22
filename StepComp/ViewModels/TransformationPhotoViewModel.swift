//
//  TransformationPhotoViewModel.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import Foundation
import UIKit
import Combine

@MainActor
class TransformationPhotoViewModel: ObservableObject {
    static let shared = TransformationPhotoViewModel()
    
    @Published var photos: [TransformationPhoto] = []
    @Published var latestPhoto: UIImage?
    
    private let userDefaultsKey = "transformation_photos"
    private let photoDirectoryName = "transformation_photos"
    
    private var photoDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(photoDirectoryName)
    }
    
    private init() {
        createPhotoDirectoryIfNeeded()
        loadPhotos()
        loadLatestPhotoImage()
    }
    
    // MARK: - Public Methods
    
    func addPhotoSet(frontImage: UIImage, sideImage: UIImage, backImage: UIImage, date: Date = Date(), note: String? = nil) {
        let directory = photoDirectory
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }

            guard let processedFront = self.processImage(frontImage),
                  let processedSide = self.processImage(sideImage),
                  let processedBack = self.processImage(backImage),
                  let frontData = processedFront.jpegData(compressionQuality: 0.8),
                  let sideData = processedSide.jpegData(compressionQuality: 0.8),
                  let backData = processedBack.jpegData(compressionQuality: 0.8) else {
                return
            }

            let baseId = UUID().uuidString
            let frontFilename = "\(baseId)_front.jpg"
            let sideFilename = "\(baseId)_side.jpg"
            let backFilename = "\(baseId)_back.jpg"

            let frontURL = directory.appendingPathComponent(frontFilename)
            let sideURL = directory.appendingPathComponent(sideFilename)
            let backURL = directory.appendingPathComponent(backFilename)

            do {
                try frontData.write(to: frontURL)
                try sideData.write(to: sideURL)
                try backData.write(to: backURL)

                await MainActor.run {
                    let photo = TransformationPhoto(
                        date: date,
                        frontFilename: frontFilename,
                        sideFilename: sideFilename,
                        backFilename: backFilename,
                        note: note
                    )
                    self.photos.append(photo)
                    self.photos.sort { $0.date > $1.date }
                    self.latestPhoto = processedFront
                    self.savePhotos()
                }
            } catch {
                return
            }
        }
    }
    
    func deletePhoto(id: UUID) {
        guard let photo = photos.first(where: { $0.id == id }) else { return }
        
        // Delete all three files from disk
        let frontURL = photoDirectory.appendingPathComponent(photo.frontFilename)
        let sideURL = photoDirectory.appendingPathComponent(photo.sideFilename)
        let backURL = photoDirectory.appendingPathComponent(photo.backFilename)
        
        try? FileManager.default.removeItem(at: frontURL)
        try? FileManager.default.removeItem(at: sideURL)
        try? FileManager.default.removeItem(at: backURL)
        
        // Remove from array
        photos.removeAll { $0.id == id }
        
        // Update latest photo
        loadLatestPhotoImage()
        
        // Save metadata
        savePhotos()
        
        print("✅ Deleted transformation photo set")
    }
    
    func loadImage(for photo: TransformationPhoto, angle: PhotoAngle) -> UIImage? {
        let filename: String
        switch angle {
        case .front:
            filename = photo.frontFilename
        case .side:
            filename = photo.sideFilename
        case .back:
            filename = photo.backFilename
        }
        
        let fileURL = photoDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    // MARK: - Private Methods
    
    nonisolated private func processImage(_ image: UIImage) -> UIImage? {
        // Resize to max dimension of 1200px
        let maxDimension: CGFloat = 1200
        let size = image.size
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func createPhotoDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: photoDirectory.path) {
            try? FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func savePhotos() {
        if let encoded = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadPhotos() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([TransformationPhoto].self, from: data) {
            photos = decoded.sorted { $0.date > $1.date }
        }
    }
    
    private func loadLatestPhotoImage() {
        guard let latest = photos.first else {
            latestPhoto = nil
            return
        }
        latestPhoto = loadImage(for: latest, angle: .front)
    }
}
