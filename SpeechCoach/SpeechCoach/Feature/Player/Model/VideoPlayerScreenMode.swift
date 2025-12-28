//
//  VideoPlayerScreenMode.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/28/25.
//

import Foundation

enum VideoPlayerScreenMode: Equatable {
    case normal
    case highlightReview(showFeedbackCTA: Bool = false)
}
