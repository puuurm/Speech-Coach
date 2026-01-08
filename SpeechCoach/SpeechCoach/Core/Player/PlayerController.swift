//
//  PlayerController.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/20/25.
//

import AVKit
import Combine

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
        let maxT = max(0, duration() - 0.1)
        let safe = max(0, min(seconds, maxT))
        let time = CMTime(seconds: safe, preferredTimescale: 600)
        
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            if autoplay { self.player.play() }
        }
        print("▶️ seek to:", safe, "cur:", self.player.currentTime().seconds)
    }
    
    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }
}
