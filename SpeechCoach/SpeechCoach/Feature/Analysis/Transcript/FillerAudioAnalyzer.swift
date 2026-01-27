//
//  FillerAudioAnalyzer.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/27/26.
//

import AVFoundation
import Accelerate

// MARK: - Analyzer

final class FillerAudioAnalyzer {

    struct Config {
        /// 후보 이벤트 최소/최대 길이 (오탐 줄이려고 조금 좁힘)
        var minDuration: TimeInterval = 0.22
        var maxDuration: TimeInterval = 0.85

        /// 프레임 설정 (튜닝 가능)
        var frameSize: Int = 1024
        var hopSize: Int = 512

        /// noise floor 대비 몇 dB 이상이면 "활성(음성/잡음 포함)" 프레임으로 볼지
        var speechDbOffset: Float = 12.0

        /// filled pause는 보통 에너지가 낮은 편이라
        /// (speechThreshold + 이 값)보다 낮으면 가산점
        var lowEnergyMarginDb: Float = 8.0

        /// ZCR이 낮을수록 유성(모음/허밍) 가능성 ↑
        /// (너무 낮추면 분할/누락 생겨서, 하드컷에 쓰되 값은 보수적으로 튜닝)
        var maxZCRForVoiced: Float = 0.10

        /// 후보 구간(프레임 단위) 합치기
        var mergeGap: TimeInterval = 0.08

        /// 최종 이벤트끼리 가까우면 합치기 (과분할 방지)
        var mergeEventGap: TimeInterval = 0.25

        /// 최종 confidence 컷 (오탐이 많으면 0.60~0.70 추천)
        var minConfidence: Float = 0.60
    }

    let config: Config
    init(config: Config = .init()) { self.config = config }

    func detectFilledPauses(audioURL: URL) async throws -> [FillerEvent] {
        let file = try AVAudioFile(forReading: audioURL)
        let processingFormat = file.processingFormat
        let sampleRate = Float(processingFormat.sampleRate)

        // ✅ 1ch Float32로 읽기
        guard let floatFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: processingFormat.sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            return []
        }

        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: floatFormat, frameCapacity: frameCount) else {
            return []
        }

        // 대부분의 exportAudio가 PCM으로 뽑히면 바로 읽히지만,
        // 포맷 mismatch가 나는 케이스는 converter 버전으로 대체 필요.
        try file.read(into: buffer)

        // ✅ buffer 포맷 기준으로 channelCount 결정 (버그 방지)
        let mono = makeMonoFloatArray(buffer: buffer)
        if mono.isEmpty { return [] }

        // 프레임별 RMS(dB) + ZCR
        let frameSize = config.frameSize
        let hopSize = config.hopSize

        var rmsDb: [Float] = []
        rmsDb.reserveCapacity(max(1, mono.count / hopSize))

        var zcr: [Float] = []
        zcr.reserveCapacity(max(1, mono.count / hopSize))

        var idx = 0
        while idx + frameSize <= mono.count {
            let frame = Array(mono[idx..<(idx + frameSize)])
            rmsDb.append(frameRMSdB(frame))
            zcr.append(frameZCR(frame))
            idx += hopSize
        }

        if rmsDb.isEmpty { return [] }

        // noise floor (하위 20% 퍼센타일)
        let noiseFloor = percentile(rmsDb, p: 0.20)
        let speechThreshold = noiseFloor + config.speechDbOffset

        // ✅ isActive는 에너지로만(과분할 방지)
        let isActive: [Bool] = rmsDb.map { $0 >= speechThreshold }

        let hopSec = TimeInterval(Float(hopSize) / sampleRate)
        let frameSec = TimeInterval(Float(frameSize) / sampleRate)

        // active 프레임 → regions
        var regions: [(startFrame: Int, endFrame: Int)] = []
        var start: Int? = nil

        for i in 0..<isActive.count {
            if isActive[i] {
                if start == nil { start = i }
            } else {
                if let s = start {
                    regions.append((s, i - 1))
                    start = nil
                }
            }
        }
        if let s = start {
            regions.append((s, isActive.count - 1))
        }

        // 프레임 갭 병합
        regions = mergeRegions(regions, hopSec: hopSec, mergeGap: config.mergeGap)

        // region 평가
        var events: [FillerEvent] = []
        events.reserveCapacity(regions.count)

        for r in regions {
            let startTime = TimeInterval(r.startFrame) * hopSec
            let endTime = TimeInterval(r.endFrame) * hopSec + frameSec
            let dur = endTime - startTime

            guard dur >= config.minDuration, dur <= config.maxDuration else { continue }

            let sliceDb = Array(rmsDb[r.startFrame...r.endFrame])
            let sliceZ = Array(zcr[r.startFrame...r.endFrame])

            let meanDb = sliceDb.reduce(0, +) / Float(sliceDb.count)
            let meanZ = sliceZ.reduce(0, +) / Float(sliceZ.count)

            // ✅ 하드컷: ZCR이 높으면 유성 필러가 아닐 확률 ↑
            if meanZ > config.maxZCRForVoiced { continue }

            // low-energy 힌트
            let lowEnergyHint = meanDb <= (speechThreshold + config.lowEnergyMarginDb)

            // ✅ 주변에 강한 발화가 붙어있으면 "말의 일부"일 가능성 ↑ → 제외(오탐 감소)
            let adjacentSpeech = hasAdjacentStrongSpeech(
                startFrame: r.startFrame,
                endFrame: r.endFrame,
                rmsDb: rmsDb,
                speechThreshold: speechThreshold,
                hopSec: hopSec,
                contextSec: 0.20,
                strongOffsetDb: 10
            )
            if adjacentSpeech { continue }

            // confidence (룰 기반)
            var score: Float = 0

            // duration: 0.2~0.7쯤에 더 가산
            if dur < 0.70 { score += 0.35 } else { score += 0.15 }

            // meanZ가 낮을수록 유성 가능성 ↑
            score += 0.35

            if lowEnergyHint { score += 0.25 } else { score += 0.10 }

            // threshold 근처면 더 가산
            let dbAbove = meanDb - speechThreshold
            if dbAbove >= 0, dbAbove <= 6 { score += 0.10 }

            let confidence = min(1.0, max(0.0, score))
            guard confidence >= config.minConfidence else { continue }

            events.append(
                FillerEvent(
                    start: startTime,
                    end: endTime,
                    kind: .filledPauseAudio,
                    confidence: confidence
                )
            )
        }

        // ✅ 최종 이벤트 병합(과분할/근접 중복 방지)
        return mergeEvents(events, gap: config.mergeEventGap)
    }
}

// MARK: - Helpers

private extension FillerAudioAnalyzer {

    func makeMonoFloatArray(buffer: AVAudioPCMBuffer) -> [Float] {
        guard let floatData = buffer.floatChannelData else { return [] }
        let frames = Int(buffer.frameLength)
        if frames == 0 { return [] }

        let channelCount = Int(buffer.format.channelCount)

        if channelCount == 1 {
            return Array(UnsafeBufferPointer(start: floatData[0], count: frames))
        } else {
            // (현재 floatFormat이 1ch라면 사실상 여기 안 들어옴)
            var mono = [Float](repeating: 0, count: frames)
            for ch in 0..<channelCount {
                let src = UnsafeBufferPointer(start: floatData[ch], count: frames)
                for i in 0..<frames {
                    mono[i] += src[i]
                }
            }
            let inv = 1.0 / Float(channelCount)
            vDSP_vsmul(mono, 1, [inv], &mono, 1, vDSP_Length(frames))
            return mono
        }
    }

    func frameRMSdB(_ frame: [Float]) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(frame, 1, &rms, vDSP_Length(frame.count))
        let eps: Float = 1e-7
        let value = max(rms, eps)
        return 20.0 * log10f(value)
    }

    func frameZCR(_ frame: [Float]) -> Float {
        if frame.count < 2 { return 0 }
        var changes = 0
        for i in 1..<frame.count {
            let a = frame[i - 1]
            let b = frame[i]
            if (a >= 0 && b < 0) || (a < 0 && b >= 0) {
                changes += 1
            }
        }
        return Float(changes) / Float(frame.count - 1)
    }

    func percentile(_ values: [Float], p: Float) -> Float {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let clamped = min(1, max(0, p))
        let idx = Int(round(clamped * Float(sorted.count - 1)))
        return sorted[idx]
    }

    func mergeRegions(
        _ regions: [(startFrame: Int, endFrame: Int)],
        hopSec: TimeInterval,
        mergeGap: TimeInterval
    ) -> [(startFrame: Int, endFrame: Int)] {
        guard regions.count >= 2 else { return regions }

        var merged: [(Int, Int)] = []
        var cur = regions[0]

        for r in regions.dropFirst() {
            let gapFrames = r.startFrame - cur.endFrame - 1
            let gapTime = TimeInterval(max(0, gapFrames)) * hopSec

            if gapTime <= mergeGap {
                cur = (cur.0, r.endFrame)
            } else {
                merged.append(cur)
                cur = r
            }
        }
        merged.append(cur)
        return merged
    }

    func mergeEvents(_ events: [FillerEvent], gap: TimeInterval) -> [FillerEvent] {
        guard events.count >= 2 else { return events }
        let sorted = events.sorted { $0.start < $1.start }

        var out: [FillerEvent] = []
        var cur = sorted[0]

        for e in sorted.dropFirst() {
            if e.start - cur.end <= gap {
                cur = FillerEvent(
                    start: cur.start,
                    end: max(cur.end, e.end),
                    kind: .filledPauseAudio,
                    confidence: max(cur.confidence, e.confidence)
                )
            } else {
                out.append(cur)
                cur = e
            }
        }
        out.append(cur)
        return out
    }

    func hasAdjacentStrongSpeech(
        startFrame: Int,
        endFrame: Int,
        rmsDb: [Float],
        speechThreshold: Float,
        hopSec: TimeInterval,
        contextSec: TimeInterval,
        strongOffsetDb: Float
    ) -> Bool {
        let ctxFrames = Int(contextSec / hopSec)

        func mean(_ slice: ArraySlice<Float>) -> Float {
            guard !slice.isEmpty else { return -999 }
            return slice.reduce(0, +) / Float(slice.count)
        }

        let preStart = max(0, startFrame - ctxFrames)
        let preEnd = max(0, startFrame - 1)

        let postStart = min(rmsDb.count - 1, endFrame + 1)
        let postEnd = min(rmsDb.count - 1, endFrame + ctxFrames)

        let preMean = preStart <= preEnd ? mean(rmsDb[preStart...preEnd]) : -999
        let postMean = postStart <= postEnd ? mean(rmsDb[postStart...postEnd]) : -999

        let strong = speechThreshold + strongOffsetDb
        return (preMean >= strong) || (postMean >= strong)
    }
}
