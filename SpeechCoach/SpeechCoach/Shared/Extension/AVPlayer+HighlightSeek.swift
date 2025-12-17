//
//  AVPlayer+HighlightSeek.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/17/25.
//

import SwiftUI
import AVFoundation

//extension AVPlayer {
//    func observeHighlightSeek() -> NSObjectProtocol {
//        NotificationCenter.default.addObserver(
//            forName: HighlightSeekBridge.notification,
//            object: nil,
//            queue: .main
//        ) { [weak self] noti in
//            guard let self else { return }
//            guard let sec = noti.userInfo?[HighlightSeekBridge.keySeconds] as? TimeInterval else { return }
//            let time = CMTime(seconds: sec, preferredTimescale: 600)
//            self.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
//            self.play()
//        }
//    }
//}
