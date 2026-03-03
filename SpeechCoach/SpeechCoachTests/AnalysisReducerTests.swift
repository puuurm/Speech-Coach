//
//  SpeechCoachTests.swift
//  SpeechCoachTests
//
//  Created by Heejung Yang on 3/2/26.
//

import XCTest
@testable import SpeechCoach

@MainActor
final class AnalysisReducerTests: XCTestCase {
    
    func test_analysisSucceeded_whenPlaybackNotEnded_transitionsToWaitingForPlaybackEnd() {
        let (record, metrics) = makeDummyRecordAndMetrics()

        var state = AnalysisState(
            phase: .idle,
            playbackEnded: false,
            analyzedRecord: nil,
            analyzedMetrics: nil
        )

        AnalysisReducer.reduce(&state, .startTapped)
        AnalysisReducer.reduce(&state, .analysisSucceeded(
            playbackEnded: false,
            record: record,
            metrics: metrics
        ))

        guard case .waitingForPlaybackEnd = state.phase else {
            return XCTFail("Expected .waitingForPlaybackEnd, got \(state.phase)")
        }
        XCTAssertNotNil(state.analyzedRecord)
        XCTAssertNotNil(state.analyzedMetrics)
    }
    
    func test_openResultNow_whenWaitingForPlaybackEnd_transitionsToReady() {
        let (record, metrics) = makeDummyRecordAndMetrics()

        var state = AnalysisState(
            phase: .idle,
            playbackEnded: false,
            analyzedRecord: nil,
            analyzedMetrics: nil
        )

        AnalysisReducer.reduce(&state, .startTapped)
        AnalysisReducer.reduce(&state, .analysisSucceeded(
            playbackEnded: false,
            record: record,
            metrics: metrics
        ))

        guard case .waitingForPlaybackEnd = state.phase else {
            return XCTFail("Precondition failed: expected .waitingForPlaybackEnd, got \(state.phase)")
        }

        AnalysisReducer.reduce(&state, .openResultNow)

        guard case .ready = state.phase else {
            return XCTFail("Expected .ready, got \(state.phase)")
        }
    }
    
    func test_playbackEnded_whenWaitingForPlaybackEnd_transitionsToReady() {
        let (record, metrics) = makeDummyRecordAndMetrics()
        
        var state = AnalysisState(
            phase: .idle,
            playbackEnded: false,
            analyzedRecord: nil,
            analyzedMetrics: nil
        )

        AnalysisReducer.reduce(&state, .startTapped)
        AnalysisReducer.reduce(&state, .analysisSucceeded(
            playbackEnded: false,
            record: record,
            metrics: metrics
        ))

        guard case .waitingForPlaybackEnd = state.phase else {
            return XCTFail("Precondition failed: expected .waitingForPlaybackEnd, got \(state.phase)")
        }

        AnalysisReducer.reduce(&state, .playbackEnded)

        guard case .ready = state.phase else {
            return XCTFail("Expected .ready, got \(state.phase)")
        }
    }
    
    func test_openResultNow_whenIdle_doesNotTransition() {
        var state = AnalysisState(
            phase: .idle,
            playbackEnded: false,
            analyzedRecord: nil,
            analyzedMetrics: nil
        )

        AnalysisReducer.reduce(&state, .openResultNow)

        guard case .idle = state.phase else {
            return XCTFail("Expected .idle (no transition), got \(state.phase)")
        }
        XCTAssertNil(state.analyzedRecord)
        XCTAssertNil(state.analyzedMetrics)
    }

    func test_playbackEnded_whenIdle_doesNotTransition() {
        var state = AnalysisState(
            phase: .idle,
            playbackEnded: false,
            analyzedRecord: nil,
            analyzedMetrics: nil
        )

        AnalysisReducer.reduce(&state, .playbackEnded)

        guard case .idle = state.phase else {
            return XCTFail("Expected .idle (no transition), got \(state.phase)")
        }
        XCTAssertNil(state.analyzedRecord)
        XCTAssertNil(state.analyzedMetrics)
    }
}

private extension AnalysisReducerTests {

    func makeDummyRecordAndMetrics() -> (SpeechRecord, SpeechMetrics) {
        let id = UUID()
        let now = Date()

        let record = SpeechRecord(
            id: id,
            createdAt: now,
            title: "test",
            duration: 10,
            summaryWPM: 100,
            summaryFillerCount: 1,
            metricsGeneratedAt: now,
            transcript: "테스트",
            studentName: nil,
            videoRelativePath: "test.mov",
            note: nil,
            insight: SpeechRecord.Insight(
                oneLiner: "",
                problemSummary: "",
                qualitative: nil,
                transcriptSegments: nil,
                updatedAt: now
            ),
            highlights: []
        )

        let metrics = SpeechMetrics(
            recordID: id,
            generatedAt: now,
            wordsPerMinute: 100,
            fillerCount: 1,
            fillerWords: [:],
            paceVariability: nil,
            spikeCount: nil
        )

        return (record, metrics)
    }
}
