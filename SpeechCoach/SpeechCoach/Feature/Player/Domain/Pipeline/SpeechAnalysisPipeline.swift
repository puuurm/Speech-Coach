//
//  SpeechAnalysisPipeline.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/27/26.
//

import Foundation

protocol SpeechAnalysisPipeline {
    func run(videoURL: URL, durationHint: TimeInterval) async throws -> (SpeechRecord, SpeechMetrics)
}
