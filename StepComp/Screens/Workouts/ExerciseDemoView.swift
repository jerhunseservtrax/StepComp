//
//  ExerciseDemoView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 3/12/26.
//

import SwiftUI

struct AnimatedGifView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        applyGif(to: imageView)
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        applyGif(to: imageView)
    }

    private func applyGif(to imageView: UIImageView) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }
        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))

            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
               let gifProps = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                let delay = (gifProps[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                    ?? (gifProps[kCGImagePropertyGIFDelayTime] as? Double)
                    ?? 0.1
                totalDuration += delay
            } else {
                totalDuration += 0.1
            }
        }

        imageView.animationImages = images
        imageView.animationDuration = totalDuration
        imageView.animationRepeatCount = 0
        imageView.startAnimating()
    }
}

struct ExerciseGifThumbnail: View {
    let exercise: Exercise
    let size: CGFloat

    @State private var gifData: Data?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.286)
                .fill(FitCompColors.textSecondary.opacity(0.1))
                .frame(width: size, height: size)

            if let gifData {
                AnimatedGifView(data: gifData)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.286))
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "dumbbell")
                    .foregroundColor(FitCompColors.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .task {
            guard gifData == nil, !isLoading,
                  let dbId = exercise.exerciseDBId else { return }
            isLoading = true
            gifData = await ExerciseDBService.shared.loadGif(exerciseDBId: dbId)
            isLoading = false
        }
    }
}

struct ExerciseDemoSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @State private var gifData: Data?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    if let gifData {
                        AnimatedGifView(data: gifData)
                            .frame(maxWidth: .infinity)
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 20)
                    } else if isLoading {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(FitCompColors.textSecondary.opacity(0.1))
                            .frame(height: 320)
                            .overlay(ProgressView())
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 48))
                                .foregroundColor(FitCompColors.textSecondary)
                            Text("No demo available")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                        .frame(height: 320)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(FitCompColors.textPrimary)

                        HStack(spacing: 6) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 14))
                                .foregroundColor(FitCompColors.primary)
                            Text(exercise.targetMuscles)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .task {
            guard let dbId = exercise.exerciseDBId else {
                isLoading = false
                return
            }
            gifData = await ExerciseDBService.shared.loadGif(exerciseDBId: dbId, resolution: 360)
            isLoading = false
        }
    }
}

struct ExerciseDemoButton: View {
    let exercise: Exercise
    let size: CGFloat

    @State private var showingDemo = false

    init(exercise: Exercise, size: CGFloat = 56) {
        self.exercise = exercise
        self.size = size
    }

    var body: some View {
        Button {
            showingDemo = true
            HapticManager.shared.light()
        } label: {
            ZStack {
                ExerciseGifThumbnail(exercise: exercise, size: size)

                if exercise.exerciseDBId != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: size * 0.32))
                                .foregroundColor(FitCompColors.primary)
                                .background(
                                    Circle()
                                        .fill(FitCompColors.surface)
                                        .frame(width: size * 0.28, height: size * 0.28)
                                )
                        }
                    }
                    .frame(width: size, height: size)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(exercise.exerciseDBId == nil)
        .sheet(isPresented: $showingDemo) {
            ExerciseDemoSheet(exercise: exercise)
        }
    }
}

#Preview {
    ExerciseDemoButton(
        exercise: Exercise(name: "Barbell Bench Press", targetMuscles: "Chest, Triceps")
    )
}
