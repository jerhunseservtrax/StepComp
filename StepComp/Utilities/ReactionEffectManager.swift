//
//  ReactionEffectManager.swift
//  FitComp
//
//  Triggers full-screen celebration effects similar to iMessage/FaceTime reactions
//  Uses UIKit particle effects and animations
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class ReactionEffectManager {
    static let shared = ReactionEffectManager()
    
    private init() {}
    
    /// Trigger a full-screen celebration effect
    /// - Parameter type: The reaction type (fireworks, balloons, confetti, etc.)
    @MainActor
    func trigger(_ type: ReactionType) {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("⚠️ ReactionEffect: Could not find key window")
            return
        }
        
        print("🎉 Triggering reaction effect: \(type)")
        
        // Create overlay view for the effect
        let overlayView = UIView(frame: window.bounds)
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        overlayView.tag = 999 // For identification
        window.addSubview(overlayView)
        
        // Trigger the appropriate effect
        switch type {
        case .fireworks:
            triggerFireworksEffect(in: overlayView)
        case .confetti:
            triggerConfettiEffect(in: overlayView)
        case .balloons:
            triggerBalloonsEffect(in: overlayView)
        case .hearts:
            triggerHeartsEffect(in: overlayView)
        case .stars:
            triggerStarsEffect(in: overlayView)
        }
        
        // Auto-remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIView.animate(withDuration: 0.5, animations: {
                overlayView.alpha = 0
            }, completion: { _ in
                overlayView.removeFromSuperview()
            })
        }
        #endif
    }
    
    #if canImport(UIKit)
    // MARK: - Fireworks Effect
    
    private func triggerFireworksEffect(in view: UIView) {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        emitterLayer.emitterShape = .point
        emitterLayer.emitterSize = CGSize(width: 1, height: 1)
        emitterLayer.renderMode = .additive
        
        let fireworkCell = CAEmitterCell()
        fireworkCell.birthRate = 3
        fireworkCell.lifetime = 2.5
        fireworkCell.velocity = 300
        fireworkCell.velocityRange = 100
        fireworkCell.emissionRange = .pi * 2
        fireworkCell.scale = 0.0
        fireworkCell.scaleSpeed = 0.8
        
        // Explosion cell
        let explosionCell = CAEmitterCell()
        explosionCell.birthRate = 75
        explosionCell.lifetime = 2.0
        explosionCell.lifetimeRange = 1.0
        explosionCell.velocity = 150
        explosionCell.velocityRange = 100
        explosionCell.emissionRange = .pi * 2
        explosionCell.spin = 2
        explosionCell.spinRange = 3
        explosionCell.scale = 0.8
        explosionCell.scaleSpeed = -0.4
        explosionCell.alphaSpeed = -0.5
        
        // Create colorful particles
        explosionCell.contents = createCircleImage(size: CGSize(width: 10, height: 10), color: .systemYellow).cgImage
        fireworkCell.emitterCells = [explosionCell]
        
        emitterLayer.emitterCells = [fireworkCell]
        view.layer.addSublayer(emitterLayer)
        
        // Add multiple bursts
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                let positions = [
                    CGPoint(x: view.bounds.width * 0.3, y: view.bounds.height * 0.3),
                    CGPoint(x: view.bounds.width * 0.7, y: view.bounds.height * 0.3),
                    CGPoint(x: view.bounds.width * 0.5, y: view.bounds.height * 0.4),
                    CGPoint(x: view.bounds.width * 0.2, y: view.bounds.height * 0.5),
                    CGPoint(x: view.bounds.width * 0.8, y: view.bounds.height * 0.5)
                ]
                emitterLayer.emitterPosition = positions[i]
            }
        }
        
        // Stop emitting after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            emitterLayer.birthRate = 0
        }
    }
    
    // MARK: - Confetti Effect
    
    private func triggerConfettiEffect(in view: UIView) {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -50)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: view.bounds.width, height: 1)
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemPurple, .systemOrange]
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 10.0
            cell.velocity = 200
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 8
            cell.spin = 3
            cell.spinRange = 4
            cell.scaleRange = 0.5
            cell.scale = 0.7
            cell.contents = createConfettiImage(color: color).cgImage
            cells.append(cell)
        }
        
        emitterLayer.emitterCells = cells
        view.layer.addSublayer(emitterLayer)
        
        // Stop after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitterLayer.birthRate = 0
        }
    }
    
    // MARK: - Balloons Effect
    
    private func triggerBalloonsEffect(in view: UIView) {
        for i in 0..<15 {
            let delay = Double(i) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.createBalloon(in: view)
            }
        }
    }
    
    private func createBalloon(in view: UIView) {
        let balloonSize: CGFloat = CGFloat.random(in: 40...80)
        let balloon = UILabel(frame: CGRect(x: CGFloat.random(in: 0...view.bounds.width),
                                           y: view.bounds.height + balloonSize,
                                           width: balloonSize,
                                           height: balloonSize))
        balloon.text = "🎈"
        balloon.font = .systemFont(ofSize: balloonSize)
        view.addSubview(balloon)
        
        let duration = Double.random(in: 3...5)
        let endX = balloon.frame.origin.x + CGFloat.random(in: -50...50)
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
            balloon.frame.origin.y = -balloonSize - 50
            balloon.frame.origin.x = endX
            balloon.alpha = 0.5
        }, completion: { _ in
            balloon.removeFromSuperview()
        })
    }
    
    // MARK: - Hearts Effect
    
    private func triggerHeartsEffect(in view: UIView) {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: view.bounds.height + 50)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: view.bounds.width * 0.6, height: 1)
        
        let cell = CAEmitterCell()
        cell.birthRate = 8
        cell.lifetime = 4.0
        cell.velocity = -150
        cell.velocityRange = 50
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 6
        cell.spin = 1
        cell.spinRange = 2
        cell.scaleRange = 0.3
        cell.scale = 0.8
        cell.contents = createHeartImage().cgImage
        
        emitterLayer.emitterCells = [cell]
        view.layer.addSublayer(emitterLayer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitterLayer.birthRate = 0
        }
    }
    
    // MARK: - Stars Effect
    
    private func triggerStarsEffect(in view: UIView) {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        emitterLayer.emitterShape = .point
        emitterLayer.emitterSize = CGSize(width: 1, height: 1)
        
        let cell = CAEmitterCell()
        cell.birthRate = 30
        cell.lifetime = 3.0
        cell.velocity = 200
        cell.velocityRange = 100
        cell.emissionRange = .pi * 2
        cell.spin = 4
        cell.spinRange = 2
        cell.scaleRange = 0.4
        cell.scale = 0.7
        cell.alphaSpeed = -0.4
        cell.contents = createStarImage().cgImage
        
        emitterLayer.emitterCells = [cell]
        view.layer.addSublayer(emitterLayer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            emitterLayer.birthRate = 0
        }
    }
    
    // MARK: - Helper Methods
    
    private func createCircleImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func createConfettiImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func createHeartImage() -> UIImage {
        let size = CGSize(width: 30, height: 30)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let heartPath = UIBezierPath()
            heartPath.move(to: CGPoint(x: 15, y: 25))
            heartPath.addCurve(to: CGPoint(x: 5, y: 10),
                             controlPoint1: CGPoint(x: 10, y: 20),
                             controlPoint2: CGPoint(x: 5, y: 15))
            heartPath.addCurve(to: CGPoint(x: 15, y: 5),
                             controlPoint1: CGPoint(x: 5, y: 5),
                             controlPoint2: CGPoint(x: 10, y: 5))
            heartPath.addCurve(to: CGPoint(x: 25, y: 10),
                             controlPoint1: CGPoint(x: 20, y: 5),
                             controlPoint2: CGPoint(x: 25, y: 5))
            heartPath.addCurve(to: CGPoint(x: 15, y: 25),
                             controlPoint1: CGPoint(x: 25, y: 15),
                             controlPoint2: CGPoint(x: 20, y: 20))
            heartPath.close()
            
            UIColor.systemPink.setFill()
            heartPath.fill()
        }
    }
    
    private func createStarImage() -> UIImage {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let starPath = UIBezierPath()
            starPath.move(to: CGPoint(x: 10, y: 0))
            starPath.addLine(to: CGPoint(x: 12, y: 7))
            starPath.addLine(to: CGPoint(x: 20, y: 8))
            starPath.addLine(to: CGPoint(x: 14, y: 12))
            starPath.addLine(to: CGPoint(x: 16, y: 20))
            starPath.addLine(to: CGPoint(x: 10, y: 15))
            starPath.addLine(to: CGPoint(x: 4, y: 20))
            starPath.addLine(to: CGPoint(x: 6, y: 12))
            starPath.addLine(to: CGPoint(x: 0, y: 8))
            starPath.addLine(to: CGPoint(x: 8, y: 7))
            starPath.close()
            
            UIColor.systemYellow.setFill()
            starPath.fill()
        }
    }
    #endif
    
    /// Available reaction types
    enum ReactionType: String {
        case fireworks = "Fireworks"
        case confetti = "Confetti"
        case balloons = "Balloons"
        case hearts = "Hearts"
        case stars = "Stars"
    }
}

