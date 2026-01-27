//
//  HesitationAnalyzer.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/27/26.
//
import Foundation

struct HesitationAnalyzer {

    struct Config {
        // gap 기반(멈칫)
        var minGap: TimeInterval = 0.38
        var longGap: TimeInterval = 0.90
        var maxGap: TimeInterval = 1.20

        // STT 분절로 생기는 인공 gap 억제
        var minNeighborSegmentDuration: TimeInterval = 0.22

        // stumble 기반(삐끗) - 과탐 줄인 빡센 조건
        var stumbleMinDuration: TimeInterval = 0.18
        var stumbleMaxDuration: TimeInterval = 0.40
        var stumbleMaxConfidence: Float = 0.50

        /// segment 텍스트가 매우 짧을 때만 stumble 후보로 인정 (가능하면 강추)
        var maxTokenLengthForStumble: Int = 2

        /// stumble 연속 발생 시 하나로 묶기(버스트 제한)
        var stumbleBurstWindow: TimeInterval = 0.60

        // 최종 이벤트 병합(가까우면 1개)
        var mergeEventGap: TimeInterval = 0.25
    }

    let config: Config
    init(config: Config = .init()) { self.config = config }

    enum Kind: String, Hashable { case gap, stumble }

    struct HesitationEvent: Hashable {
        let start: TimeInterval
        let end: TimeInterval
        let kind: Kind
        var duration: TimeInterval { end - start }
    }

    func events(from segments: [TranscriptSegment], duration: TimeInterval) -> [HesitationEvent] {
        let sorted = segments.sorted { $0.startTime < $1.startTime }
        guard !sorted.isEmpty else { return [] }

        var out: [HesitationEvent] = []

        // A) gap 기반
        if sorted.count >= 2 {
            for i in 0..<(sorted.count - 1) {
                let left = sorted[i]
                let right = sorted[i + 1]

                let leftEnd = min(duration, left.startTime + left.duration)
                let gapStart = leftEnd
                let gapEnd = min(duration, right.startTime)
                let gap = gapEnd - gapStart

                guard gap.isFinite, gap > 0 else { continue }
                guard gap >= config.minGap, gap <= config.maxGap else { continue }
                if gap >= config.longGap { continue }

                // 둘 다 짧은 조각이면 STT 분절일 가능성이 커서 제외
                let short = config.minNeighborSegmentDuration
                if left.duration < short && right.duration < short { continue }

                out.append(.init(start: gapStart, end: gapEnd, kind: .gap))
            }
        }

        // B) stumble 기반 (빡센 필터 + 버스트 제한)
        var lastStumbleEnd: TimeInterval? = nil

        for seg in sorted {
            guard let c = seg.confidence else { continue }

            guard seg.duration >= config.stumbleMinDuration,
                  seg.duration <= config.stumbleMaxDuration else { continue }

            guard c <= config.stumbleMaxConfidence else { continue }

            // ✅ 텍스트 길이 필터(가능할 때만)
            // TranscriptSegment에 텍스트/substring이 없다면 이 조건은 빼도 됨.
            let trimmed = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > config.maxTokenLengthForStumble {
                continue
            }

            let s = max(0, seg.startTime)
            let e = min(duration, seg.startTime + seg.duration)
            guard e > s else { continue }

            // ✅ 버스트 제한: stumble이 연속으로 나오면 1개로만 세기
            if let lastEnd = lastStumbleEnd, s - lastEnd <= config.stumbleBurstWindow {
                continue
            }

            out.append(.init(start: s, end: e, kind: .stumble))
            lastStumbleEnd = e
        }

        // C) 최종 병합
        return mergeEvents(out, gap: config.mergeEventGap)
    }

    func count(from segments: [TranscriptSegment], duration: TimeInterval) -> Int {
        events(from: segments, duration: duration).count
    }

    private func mergeEvents(_ events: [HesitationEvent], gap: TimeInterval) -> [HesitationEvent] {
        guard events.count >= 2 else { return events }
        let sorted = events.sorted { $0.start < $1.start }

        var out: [HesitationEvent] = []
        var cur = sorted[0]

        for e in sorted.dropFirst() {
            if e.start - cur.end <= gap {
                let mergedKind: Kind = (cur.kind == .stumble || e.kind == .stumble) ? .stumble : .gap
                cur = HesitationEvent(start: cur.start, end: max(cur.end, e.end), kind: mergedKind)
            } else {
                out.append(cur)
                cur = e
            }
        }
        out.append(cur)
        return out
    }
}
