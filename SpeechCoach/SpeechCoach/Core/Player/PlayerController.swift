//
//  PlayerController.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/20/25.
//

import AVKit
import Combine
import FirebaseCrashlytics

final class PlayerController: ObservableObject {
    let player = AVPlayer()

    @Published var fallbackDuration: TimeInterval = 0
    @Published var isReadyToPlay: Bool = false
    @Published var didReachEnd: Bool = false
    
    @Published var isPlaying: Bool = false
    
    private var endObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?

    func bindPlaybackEnd() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        didReachEnd = false
        
        guard let item = player.currentItem else { return }
        endObserver = NotificationCenter.default
            .addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.didReachEnd = true
                self?.isPlaying = false
            }
    }
    
    private func bindPlaybackState() {
        timeControlObserver = player.observe(
            \.timeControlStatus,
             options: [.initial, .new]
        ) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isPlaying = (player.timeControlStatus == .playing)
            }
        }
    }
    
    func load(url: URL) {
        if timeControlObserver == nil {
            bindPlaybackState()
        }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        isReadyToPlay = false
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isReadyToPlay = item.status == .readyToPlay
            }
        }
        bindPlaybackEnd()
        didReachEnd = false
    }
    
    func duration() -> TimeInterval {
        if let duration = player.currentItem?.duration.seconds, duration.isFinite, duration > 0 {
            return duration
        }
        return fallbackDuration
    }
    
    func seek(to seconds: TimeInterval, autoplay: Bool) {
        let normalized = normalizedSecond(seconds)
        let maxT = max(0, duration() - 0.1)
        let safe = max(0, min(normalized, maxT))
        let time = CMTime(seconds: safe, preferredTimescale: 600)
        
        logPlayer("seek requested seconds=\(seconds) normalized=\(safe) autoplay=\(autoplay)")
    
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard let self else { return }
            self.logPlayer("seek finished=\(finished) time=\(safe)")

            if autoplay { self.player.play() }
        }
    }
    
    func stopAndTearDown(deactivateAudioSession: Bool = false) {
        player.pause()
        player.replaceCurrentItem(with: nil)
        
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
        
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        
        DispatchQueue.main.async {
            self.isReadyToPlay = false
            self.didReachEnd = false
            self.isPlaying = false
        }
        
        if deactivateAudioSession {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setActive(false, options: [.notifyOthersOnDeactivation])
            } catch {
                print("AudioSession deactivate failed:", error)
            }
        }
    }
    
    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }
    
    private func logPlayer(_ message: String) {
        Crashlytics.crashlytics().log("Player: \(message)")
    }
}
