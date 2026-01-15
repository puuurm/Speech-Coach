//
//  SpeechService.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/25/25.
//

import Foundation
import AVFoundation
import Speech

protocol SpeechService {
    func transcribe(videoURL: URL) async throws -> String
    func cancelRecognitionIfSupported()
}

final class MockSpeechService: SpeechService {
    func cancelRecognitionIfSupported() {}
    
    func transcribe(videoURL: URL) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return """
        안녕하세요, 저는 iOS 개발자 양희정입니다.
        오늘은 제가 준비한 스피치 과제를 발표하겠습니다.
        음, 사실 조금 긴장되지만 어, 최대한 또박또박 말해보겠습니다.
        """
    }
}

enum RealSpeechServiceError: LocalizedError {
    case speechNotAuthorized
    case recognizerUnavailable
    case exportFailed
    case noTranscription
    
    var errorDescription: String? {
        switch self {
        case .speechNotAuthorized:
            return "Speech recognition not authorized."
        case .recognizerUnavailable:
            return "Speech recognition is currently unavailable."
        case .exportFailed:
            return "Failed to export audio file."
        case .noTranscription:
            return "No transcription available."
        }
    }
}

final class RealSpeechService: SpeechService {

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko_KR"))
    
    private var recognitionTask: SFSpeechRecognitionTask?
    private let lock = NSLock()
    
    func transcribe(videoURL: URL) async throws -> String {
        try await ensureSpeechAuthorization()
        guard let recognizer, recognizer.isAvailable else {
            throw RealSpeechServiceError.recognizerUnavailable
        }
        let audioURL = try await exportAudio(from: videoURL)
        
        let result = try await recognizeDetailed(url: audioURL, with: recognizer)
        let autoCorrected = AutoCorrectionStore.shared.apply(to: result.rawText)
        let cleaned = TranscriptCleaner.cleaned(autoCorrected)
        return cleaned
    }
    
    func cancelRecognitionIfSupported() {
        lock.lock()
        defer { lock.unlock() }
        
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}

// MARK: - 권한 처리

extension RealSpeechService {
    private func ensureSpeechAuthorization() async throws {
        let status = await requestSpeechAuthorization()
        switch status {
        case .authorized:
            return
        default:
            throw RealSpeechServiceError.speechNotAuthorized
        }
    }
    
    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

// MARK: - 영상 -> 오디오 추출

extension RealSpeechService {
    func exportAudio(from videoURL: URL) async throws -> URL {
        let asset = AVAsset(url: videoURL)
        
        guard asset.tracks(withMediaType: .audio).isEmpty == false else {
            throw RealSpeechServiceError.exportFailed
        }
        
        let outputURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw RealSpeechServiceError.exportFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.shouldOptimizeForNetworkUse = true
        
        return try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: outputURL)
                case .failed, .cancelled:
                    continuation.resume(throwing: RealSpeechServiceError.exportFailed)
                default:
                    continuation.resume(throwing: RealSpeechServiceError.exportFailed)
                }
            }
        }
    }
}

extension RealSpeechService {
    func recognizeDetailed(
        url audioURL: URL,
        with recognizer: SFSpeechRecognizer
    ) async throws -> TranscriptResult {
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        
        return try await withCheckedThrowingContinuation { continuation in
            var didFinish = false
            
            func finish(_ result: Result<TranscriptResult, Error>) {
                guard !didFinish else { return }
                didFinish = true
                self.cancelRecognitionIfSupported()
                
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.cancelRecognitionIfSupported()
            
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    print("🔴 Speech recognition error:", error)
                    finish(.failure(error))
                    return
                }
                
                guard let result, result.isFinal else { return }
                
                let transcription = result.bestTranscription
                let raw = transcription.formattedString
                
                guard !raw.isEmpty else {
                    finish(.failure(RealSpeechServiceError.noTranscription))
                    return
                }
                
                let segs: [TranscriptSegment] = transcription.segments.map {
                    TranscriptSegment(
                        text: $0.substring,
                        startTime: $0.timestamp,
                        duration: $0.duration,
                        confidence: $0.confidence
                    )
                }
                
                let cleaned = TranscriptCleaner.cleaned(raw)
                let payload = TranscriptResult(
                    rawText: raw,
                    cleanedText: cleaned,
                    segments: segs
                )
                
                print("✅ Final transcription:", cleaned)
                finish(.success(payload))
            }
            
            self.lock.lock()
            self.recognitionTask = task
            self.lock.unlock()
        }
    }
}
