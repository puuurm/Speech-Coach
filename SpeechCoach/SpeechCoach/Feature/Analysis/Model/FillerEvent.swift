//
//  FillerEvent.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/27/26.
//

import Foundation

struct FillerEvent: Hashable {
    enum Kind { case textToken, filledPauseAudio }
    let start: TimeInterval
    let end: TimeInterval
    let kind: Kind
    let confidence: Float
}
