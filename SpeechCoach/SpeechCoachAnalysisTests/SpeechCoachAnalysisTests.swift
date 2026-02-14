//
//  SpeechCoachAnalysisTests.swift
//  SpeechCoachAnalysisTests
//
//  Created by Heejung Yang on 2/13/26.
//

import Testing
import Foundation
@testable import SpeechCoachAnalysis

struct SpeechCoachAnalysisTests {

    // MARK: - Helpers

    private func makeSegments(
        count: Int,
        startStep: TimeInterval = 1.0,
        segDuration: TimeInterval = 0.5,
        text: String = "a",
        confidence: Float? = 0.8
    ) -> [TranscriptSegment] {
        (0..<count).map { i in
            TranscriptSegment(
                text: text,
                startTime: TimeInterval(i) * startStep,
                duration: segDuration,
                confidence: confidence
            )
        }
    }

    // MARK: - 1) TranscriptQualityChecker: transcript 공백만이면 true

    @Test func qualityChecker_blankTranscript_shouldHideTrue() async throws {
        let result = TranscriptQualityChecker.shouldHide(transcript: "   \n\t  ", segments: nil)
        #expect(result == true)
    }

    // MARK: - 2) TranscriptQualityChecker: segments nil이면 false (transcript가 비어있지 않다면)

    @Test func qualityChecker_segmentsNil_shouldHideFalseWhenTranscriptNotEmpty() async throws {
        let result = TranscriptQualityChecker.shouldHide(transcript: "hello", segments: nil)
        #expect(result == false)
    }

    // MARK: - 3) TranscriptQualityChecker: segments.count <= 8 이면 true

    @Test func qualityChecker_fewSegments_shouldHideTrue() async throws {
        let segments = makeSegments(count: 8, startStep: 1.0, segDuration: 0.5, text: "a", confidence: 0.8)
        let result = TranscriptQualityChecker.shouldHide(transcript: "hello", segments: segments)
        #expect(result == true)
    }

    // MARK: - 4) TranscriptQualityChecker: segmentsPerSecond <= 0.4 이면 true

    @Test func qualityChecker_lowDensity_shouldHideTrue() async throws {
        let segments = makeSegments(count: 10, startStep: 3.0, segDuration: 0.5, text: "a", confidence: 0.8)
        let result = TranscriptQualityChecker.shouldHide(transcript: "hello", segments: segments)
        #expect(result == true)
    }

    // MARK: - 5) TranscriptQualityChecker: 정상 케이스면 false

    @Test func qualityChecker_goodSegments_shouldHideFalse() async throws {
        let segments = makeSegments(count: 10, startStep: 1.0, segDuration: 0.5, text: "a", confidence: 0.8)
        let result = TranscriptQualityChecker.shouldHide(transcript: "hello", segments: segments)
        #expect(result == false)
    }

    // MARK: - 6) SpeedSeriesBuilder: segments 기반 bin 카운트 정확성

    @Test func speedSeries_fromSegments_countsWordsPerBin() async throws {
        let segments: [TranscriptSegment] = [
            .init(text: "안녕하세요 여러분", startTime: 1.0, duration: 0.8),
            .init(text: "오늘 주제는 테스트 입니다", startTime: 6.0, duration: 1.0)
        ]

        let series = SpeedSeriesBuilder.make(
            duration: 12.0,
            transcript: "",
            segments: segments,
            binSeconds: 5
        )

        #expect(series.bins.count == 3)
        #expect(series.bins[0].wordCount == 2)
        #expect(series.bins[1].wordCount == 4)
        #expect(series.bins[2].wordCount == 0)
    }

    // MARK: - 7) SpeedSeriesBuilder: fallback transcript 분배

    @Test func speedSeries_fallback_transcriptDistributedAcrossBins() async throws {
        let transcript = "a b c d e f"

        let series = SpeedSeriesBuilder.make(
            duration: 10.0,
            transcript: transcript,
            segments: nil,
            binSeconds: 5
        )

        #expect(series.bins.count == 2)
        #expect(series.bins[0].wordCount == 3)
        #expect(series.bins[1].wordCount == 3)
    }

    // MARK: - 8) PauseAnalyzer: gap 계산 기본

    @Test func pauseAnalyzer_gaps_computedCorrectly() async throws {
        let segments: [TranscriptSegment] = [
            .init(text: "a", startTime: 0.0, duration: 1.0),
            .init(text: "b", startTime: 3.0, duration: 1.0),
            .init(text: "c", startTime: 4.5, duration: 1.0)
        ]

        let gaps = PauseAnalyzer.gaps(from: segments, duration: 6.0)

        #expect(gaps.count == 2)

        #expect(abs(gaps[0].start - 1.0) < 0.0001)
        #expect(abs(gaps[0].end - 3.0) < 0.0001)
        #expect(abs(gaps[0].duration - 2.0) < 0.0001)

        #expect(abs(gaps[1].start - 4.0) < 0.0001)
        #expect(abs(gaps[1].end - 4.5) < 0.0001)
        #expect(abs(gaps[1].duration - 0.5) < 0.0001)
    }

    // MARK: - 9) SpeechTypeSummarizer: PaceType 경계값

    @Test func speechType_paceType_thresholds() async throws {
        #expect(SpeechTypeSummarizer.inferPaceType(wpm: 0) == .slow)
        #expect(SpeechTypeSummarizer.inferPaceType(wpm: 109) == .slow)

        #expect(SpeechTypeSummarizer.inferPaceType(wpm: 110) == .comfortable)
        #expect(SpeechTypeSummarizer.inferPaceType(wpm: 160) == .comfortable)

        #expect(SpeechTypeSummarizer.inferPaceType(wpm: 161) == .fast)
    }

    // MARK: - 10) ResultAnalyzer: segments nil -> speechType nil

    @Test func resultAnalyzer_segmentsNil_returnsSpeechTypeNil() async throws {
        let sut = ResultAnalyzer()

        let input = ResultAnalysisInput(
            duration: 60.0,
            transcript: "hello world",
            segments: nil,
            wordsPerMinute: 140
        )

        let out = sut.analyze(input)

        #expect(out.speechType == nil)
    }
}
