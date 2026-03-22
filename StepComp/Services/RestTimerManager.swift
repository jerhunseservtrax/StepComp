//
//  RestTimerManager.swift
//  FitComp
//
//  Rest timer between sets during active workouts
//

import Foundation
import Combine
import AVFoundation
import AudioToolbox
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(UIKit)
import UIKit
#endif

enum RestTimerPreset: Int, CaseIterable, Identifiable {
    case thirty = 30
    case sixty = 60
    case ninety = 90
    case twoMinutes = 120
    case threeMinutes = 180
    case fiveMinutes = 300

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .thirty: return "0:30"
        case .sixty: return "1:00"
        case .ninety: return "1:30"
        case .twoMinutes: return "2:00"
        case .threeMinutes: return "3:00"
        case .fiveMinutes: return "5:00"
        }
    }
}

enum RestTimerAlertMode: String, CaseIterable {
    case visual = "visual"
    case haptic = "haptic"
    case sound = "sound"
    case hapticAndSound = "hapticAndSound"

    var label: String {
        switch self {
        case .visual: return "Visual Only"
        case .haptic: return "Haptic"
        case .sound: return "Sound"
        case .hapticAndSound: return "Haptic & Sound"
        }
    }

    var icon: String {
        switch self {
        case .visual: return "eye"
        case .haptic: return "iphone.radiowaves.left.and.right"
        case .sound: return "speaker.wave.2"
        case .hapticAndSound: return "waveform"
        }
    }
}

@MainActor
class RestTimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 90
    @Published var isFinished = false
    @Published var showOverlay = false
    /// Reasoning for the current smart rest suggestion (e.g. "Heavy compound — long rest")
    @Published var restReasoning: String?

    @Published var alertMode: RestTimerAlertMode = .visual

    private var timer: Timer?
    private var sessionSelectedDuration: TimeInterval = 90
    private var targetEndDate: Date?
    private var lifecycleCancellables = Set<AnyCancellable>()
    private let completionNotificationID = "rest_timer_completed"

    // Audio players for background-capable alarm
    private var silencePlayer: AVAudioPlayer?  // keeps app alive in background
    private var alarmPlayer: AVAudioPlayer?    // loud alarm when timer finishes
    private var alarmToneURL: URL?
    private var silenceToneURL: URL?
    private var audioSessionActive = false

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }

    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init() {
        loadAlertPreference()
        setupLifecycleObservers()
        prepareToneFiles()
    }

    deinit {
        lifecycleCancellables.forEach { $0.cancel() }
    }

    func startTimer(duration: TimeInterval? = nil, reasoning: String? = nil) {
        stopTimer()
        loadAlertPreference()

        restReasoning = reasoning
        let restDuration = duration ?? sessionSelectedDuration
        sessionSelectedDuration = restDuration
        totalDuration = restDuration
        timeRemaining = restDuration
        targetEndDate = Date().addingTimeInterval(restDuration)
        isRunning = true
        isFinished = false
        showOverlay = true

        // Start silent background audio to keep the app process alive
        // so the ticker can fire even when backgrounded/locked
        if wantsSound {
            activateAudioSession()
            startSilencePlayback()
        }

        scheduleCompletionNotification(after: restDuration)
        startTicker()
    }

    func stopTimer() {
        invalidateTicker()
        cancelCompletionNotification()
        stopAlarm()
        stopSilencePlayback()
        deactivateAudioSession()
        isRunning = false
        timeRemaining = 0
        isFinished = false
        targetEndDate = nil
    }

    func skipTimer() {
        stopTimer()
        showOverlay = false
    }

    func dismissOverlay() {
        showOverlay = false
    }

    func dismissFinishedAlert() {
        isFinished = false
        showOverlay = false
        stopTimer()
    }

    func selectPreset(_ preset: RestTimerPreset) {
        sessionSelectedDuration = TimeInterval(preset.rawValue)
        startTimer(duration: sessionSelectedDuration)
    }

    func addTime(_ seconds: TimeInterval) {
        timeRemaining += seconds
        totalDuration += seconds
        if isRunning, let targetEndDate {
            self.targetEndDate = targetEndDate.addingTimeInterval(seconds)
            scheduleCompletionNotification(after: timeRemaining)
        }
    }

    func setAlertMode(_ mode: RestTimerAlertMode) {
        alertMode = mode
        saveAlertPreference()
    }

    func resetForNewSession() {
        stopTimer()
        showOverlay = false
        isFinished = false
        sessionSelectedDuration = 90
    }

    /// Whether the current alert mode includes sound
    private var wantsSound: Bool {
        alertMode == .sound || alertMode == .hapticAndSound
    }

    // MARK: - Timer Logic

    private func timerDidFinish() {
        invalidateTicker()
        cancelCompletionNotification()
        stopSilencePlayback()
        isRunning = false
        timeRemaining = 0
        targetEndDate = nil
        isFinished = true
        showOverlay = true

        triggerAlert()
    }

    private func startTicker() {
        invalidateTicker()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncTimerWithWallClock()
            }
        }
        syncTimerWithWallClock()
    }

    private func invalidateTicker() {
        timer?.invalidate()
        timer = nil
    }

    private func syncTimerWithWallClock() {
        guard isRunning, let targetEndDate else { return }

        let remaining = targetEndDate.timeIntervalSinceNow
        if remaining <= 0.05 {
            timerDidFinish()
        } else {
            timeRemaining = remaining
        }
    }

    private func triggerAlert() {
        switch alertMode {
        case .visual:
            break
        case .haptic:
            HapticManager.shared.goalComplete()
        case .sound:
            startAlarm()
        case .hapticAndSound:
            HapticManager.shared.goalComplete()
            startAlarm()
        }
    }

    // MARK: - Audio Session

    private func activateAudioSession() {
        guard !audioSessionActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            audioSessionActive = true
        } catch {
            print("⚠️ Failed to activate audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        guard audioSessionActive else { return }
        audioSessionActive = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Tone Generation

    /// Pre-generates the alarm tone and near-silent tone WAV files.
    private func prepareToneFiles() {
        prepareAlarmTone()
        prepareSilenceTone()
    }

    /// Generates a repeating beep alarm tone (~2s cycle, loops infinitely).
    private func prepareAlarmTone() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rest_alarm.wav")
        alarmToneURL = url
        if FileManager.default.fileExists(atPath: url.path) { return }

        let sampleRate: Double = 44100
        let frequency: Double = 880       // A5
        let beepDuration: Double = 0.15
        let silenceDuration: Double = 0.12
        let beepsPerCycle = 3
        let pauseAfterCycle: Double = 0.6

        let cycleDuration = Double(beepsPerCycle) * (beepDuration + silenceDuration) + pauseAfterCycle
        let totalSamples = Int(sampleRate * cycleDuration)
        var samples = [Int16](repeating: 0, count: totalSamples)

        for beep in 0..<beepsPerCycle {
            let beepStart = Double(beep) * (beepDuration + silenceDuration)
            let startSample = Int(beepStart * sampleRate)
            let beepSamples = Int(beepDuration * sampleRate)
            let fadeLength = min(80, beepSamples / 4)

            for i in 0..<beepSamples {
                let t = Double(i) / sampleRate
                var amplitude = sin(2.0 * .pi * frequency * t)
                amplitude += 0.3 * sin(2.0 * .pi * (frequency * 2) * t)
                amplitude *= 0.7

                if i < fadeLength {
                    amplitude *= Double(i) / Double(fadeLength)
                } else if i > beepSamples - fadeLength {
                    amplitude *= Double(beepSamples - i) / Double(fadeLength)
                }

                let idx = startSample + i
                if idx < totalSamples {
                    samples[idx] = Int16(clamping: Int(amplitude * Double(Int16.max)))
                }
            }
        }

        writeWAV(samples: samples, sampleRate: 44100, to: url)
    }

    /// Generates a near-silent tone that keeps the audio session alive in background.
    private func prepareSilenceTone() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rest_silence.wav")
        silenceToneURL = url
        if FileManager.default.fileExists(atPath: url.path) { return }

        // 1 second of near-silence (amplitude ~0.001 so the OS doesn't kill it)
        let sampleRate: Double = 44100
        let totalSamples = Int(sampleRate * 1.0)
        var samples = [Int16](repeating: 0, count: totalSamples)

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            // Extremely quiet 1Hz hum — inaudible but keeps the audio session active
            let amplitude = sin(2.0 * .pi * 1.0 * t) * 0.001
            samples[i] = Int16(clamping: Int(amplitude * Double(Int16.max)))
        }

        writeWAV(samples: samples, sampleRate: 44100, to: url)
    }

    private func writeWAV(samples: [Int16], sampleRate: Int, to url: URL) {
        let dataSize = UInt32(samples.count * 2)
        var header = Data()
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        header.append(withUnsafeBytes(of: (36 + dataSize).littleEndian) { Data($0) })
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        header.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })  // PCM
        header.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })  // mono
        header.append(withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) })
        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        header.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })

        var audioData = header
        samples.withUnsafeBufferPointer { buffer in
            audioData.append(UnsafeBufferPointer(
                start: UnsafeRawPointer(buffer.baseAddress!).assumingMemoryBound(to: UInt8.self),
                count: samples.count * 2
            ))
        }

        try? audioData.write(to: url)
    }

    // MARK: - Silence Playback (background keep-alive)

    private func startSilencePlayback() {
        guard let url = silenceToneURL else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.01
            player.prepareToPlay()
            player.play()
            silencePlayer = player
        } catch {
            print("⚠️ Failed to start silence playback: \(error)")
        }
    }

    private func stopSilencePlayback() {
        silencePlayer?.stop()
        silencePlayer = nil
    }

    // MARK: - Alarm Playback

    private func startAlarm() {
        guard let url = alarmToneURL else { return }

        // Ensure audio session is active (may not be if mode was visual/haptic)
        activateAudioSession()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // loop until dismissed
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            alarmPlayer = player
        } catch {
            AudioServicesPlaySystemSound(1007)
        }
    }

    private func stopAlarm() {
        alarmPlayer?.stop()
        alarmPlayer = nil
    }

    // MARK: - Preferences

    private func loadAlertPreference() {
        if let saved = UserDefaults.standard.string(forKey: "restTimerAlertMode"),
           let mode = RestTimerAlertMode(rawValue: saved) {
            alertMode = mode
        }
    }

    private func saveAlertPreference() {
        UserDefaults.standard.set(alertMode.rawValue, forKey: "restTimerAlertMode")
    }

    // MARK: - Lifecycle

    private func setupLifecycleObservers() {
        #if canImport(UIKit)
        // When entering background the ticker keeps running because the audio
        // session holds the app alive. No need to invalidate it.
        // On foreground return we just make sure everything is in sync.

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if self.isRunning || self.targetEndDate != nil {
                        self.syncTimerWithWallClock()
                        if self.isRunning, self.timer == nil {
                            self.startTicker()
                        }
                    }
                }
            }
            .store(in: &lifecycleCancellables)
        #endif
    }

    // MARK: - Notifications (fallback for visual/haptic modes without background audio)

    private func scheduleCompletionNotification(after seconds: TimeInterval) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Rest Timer Complete"
            content.body = "Time for your next set."
            content.sound = .default
            content.categoryIdentifier = "REST_TIMER"
            content.interruptionLevel = .timeSensitive

            let triggerSeconds = max(1, seconds)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerSeconds, repeats: false)
            let request = UNNotificationRequest(
                identifier: self.completionNotificationID,
                content: content,
                trigger: trigger
            )

            center.removePendingNotificationRequests(withIdentifiers: [self.completionNotificationID])
            center.add(request) { error in
                if let error {
                    print("⚠️ Failed to schedule rest timer notification: \(error.localizedDescription)")
                }
            }
        }
        #endif
    }

    private func cancelCompletionNotification() {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [completionNotificationID])
        center.removeDeliveredNotifications(withIdentifiers: [completionNotificationID])
        #endif
    }
}
