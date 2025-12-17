//
//  HighlightSeekBridge.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/17/25.
//

import Foundation
import Combine

//enum HighlightSeekBridge {
//    static let notification = Notification.Name("HighlightSeekBridge.seek")
//    static let keySeconds = "seconds"
//    
//    static func requestSeek(to seconds: TimeInterval) {
//        NotificationCenter.default.post(
//            name: notification,
//                object: nil,
//                userInfo: [keySeconds: seconds]
//            )
//    }
//}

@MainActor
final class HighlightSeekBridge: ObservableObject {
    static let shared = HighlightSeekBridge()

    @Published var request: SeekRequest? = nil

    struct SeekRequest: Equatable {
        let seconds: TimeInterval
        let autoplay: Bool
    }

    private init() {}

    func seek(to seconds: TimeInterval, autoplay: Bool = true) {
        request = SeekRequest(seconds: seconds, autoplay: autoplay)
    }

    func consume() {
        request = nil
    }
}

func timeString(_ seconds: TimeInterval) -> String {
    let m = Int(seconds) / 60
    let s = Int(seconds) % 60
    return String(format: "%02d:%02d", m, s)
}
