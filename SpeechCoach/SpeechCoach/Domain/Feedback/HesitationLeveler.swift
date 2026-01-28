//
//  HesitationLevel.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/27/26.
//

import Foundation

struct HesitationLeveler {

    struct Threshold {
        /// 분당 말 막힘 횟수 기준
        var stableMaxPerMin: Double = 2.0     // 0~2 / min
        var normalMaxPerMin: Double = 5.0     // 2~5 / min
        // 그 이상 = unstable
    }

    let threshold: Threshold
    init(threshold: Threshold = .init()) {
        self.threshold = threshold
    }

    func level(count: Int, duration: TimeInterval) -> HesitationLevel {
        guard duration > 0 else { return .normal }

        let perMin = Double(count) / (duration / 60.0)

        if perMin <= threshold.stableMaxPerMin { return .stable }
        if perMin <= threshold.normalMaxPerMin { return .normal }
        return .unstable
    }
}

enum HesitationLevel: String, CaseIterable, Hashable {
    case stable = "안정"
    case normal = "보통"
    case unstable = "불안정"

    var systemImage: String {
        switch self {
        case .stable: return "checkmark.seal"
        case .normal: return "minus.circle"
        case .unstable: return "exclamationmark.triangle"
        }
    }

    var shortComment: String {
        switch self {
        case .stable:
            return "말 흐름이 자연스럽게 이어져요."
        case .normal:
            return "가끔 멈칫하는 구간이 있어요."
        case .unstable:
            return "말 흐름이 자주 끊겨 들릴 수 있어요."
        }
    }

    var detailComment: String {
        switch self {
        case .stable:
            return "말 막힘이 거의 없어서 전달이 또렷해요."
        case .normal:
            return "문장 시작 전에 한 박자 정리하면 더 매끄러워져요."
        case .unstable:
            return "생각 정리 → 한 문장씩 끊어 말하는 연습이 효과적이에요."
        }
    }
}
