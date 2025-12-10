//
//  AudioSessionManager.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/10/25.
//

import AVFoundation

enum AudioSessionManager {
    static func configureForPlayback() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
        } catch {
            print("⚠️ Failed to set audio session for playback:", error)
        }
    }
}
