//
//  HighlightPlaybackPolicy.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/21/25.
//

import Foundation

enum HighlightPlaybackPolicy {
    case hidden
    case playable((TimeInterval) -> Void)
}
