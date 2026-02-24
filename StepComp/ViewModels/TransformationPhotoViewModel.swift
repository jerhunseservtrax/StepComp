//
//  TransformationPhotoViewModel.swift
//  StepComp
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
    
    func addPhoto(image: UIImage, date: Date = Date(), note: String? = nil) {
        // Compress and resize image
        guard let processedImage = processImage(image),
              let imageData = processedImage.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to process image")
            return
        }
        
        // Generate filename
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = photoDirectory.appendingPathComponent(filename)
        
        // Save to disk
        do {
            try imageData.write(to: fileURL)
            
            // Create metadata entry
            let photo = TransformationPhoto(date: date, filename: filename, note: note)
            photos.append(photo)
            photos.sort { $0.date > $1.date } // Newest first
            
            // Update latest photo
            latestPhoto = processedImage
            
            // Save metadata
            savePhotos()
            
            print("✅ Saved transformation photo: \(filename)")
        } catch {
            print("❌ Failed to save photo: \(error)")
        }
    }
    
    func deletePhoto(id: UUID) {
        guard let photo = photos.first(where: { $0.id == id }) else { return }
        
        // Delete file from disk
        let fileURL = photoDirectory.appendingPathComponent(photo.filename)
        try? FileManager.default.removeItem(at: fileURL)
        
        // Remove from array
        photos.removeAll { $0.id == id }
        
        // Update latest photo
        loadLatestPhotoImage()
        
        // Save metadata
        savePhotos()
        
        print("✅ Deleted transformation photo: \(photo.filename)")
    }
    
    func updateNote(id: UUID, note: String?) {
        if let index = photos.firstIndex(where: { $0.id == id }) {
            photos[index].note = note
            savePhotos()
        }
    }
    
    func loadImage(for photo: TransformationPhoto) -> UIImage? {
        let fileURL = photoDirectory.appendingPathComponent(photo.filename)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    // MARK: - Private Methods
    
    private func processImage(_ image: UIImage) -> UIImage? {
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
        latestPhoto = loadImage(for: latest)
    }
}
