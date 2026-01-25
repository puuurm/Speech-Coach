//
//  CoachDrill.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/20/26.
//

import Foundation

struct CoachDrill: Hashable, Identifiable, Codable {
    let type: DrillType
    var id: DrillType { type }
    let title: String
    let durationSec: Int
    let guide: String
    let steps: [String]
}

extension CoachDrill {
    var durationHint: String {
        let min = max(1, durationSec / 60)
        return "\(min)분"
    }
}

struct CoachDrillGuide {
    let howTo: [String]
    let successCriteria: [String]
    let commonMistakes: [String]
}

enum DrillType: String, Codable, CaseIterable, Identifiable {
    case stretchTime20to25 = "stretch_time_20_to_25"
    case fixedRhythm = "fixed_rhythm"
    case replaceFillerWithSilence = "replace_filler_with_silence"
    case emphasizeKeywordTone = "emphasize_keyword_tone"
    case conclusionFirst = "conclusion_first"
    case emphasizeSingleKeyword = "emphasize_single_keyword"
    
    var id: String { rawValue }
}

enum DrillCatalog {
    static let all: [DrillType: CoachDrill] = [
        .stretchTime20to25: CoachDrill(
            type: .stretchTime20to25,
            title: "20초 → 25초 늘리기",
            durationSec: 120,
            guide: "같은 내용을 길이만 다르게 말하며, 말의 밀도와 여유 차이를 직접 느껴보는 연습입니다.",
            steps: [
                "같은 내용을 20초로 말한다.",
                "같은 내용을 25초로 말하되 핵심 단어에서만 잠깐 멈춘다.",
                "두 버전의 차이를 직접 느껴본다."
            ]
        ),
        .fixedRhythm: CoachDrill(
            type: .fixedRhythm,
            title: "리듬 고정",
            durationSec: 90,
            guide: "문장을 일정한 박자로 유지하며, 말의 흐름이 흔들리지 않도록 만드는 연습입니다.",
            steps: [
                "한 문장을 일정한 박자로 말한다.",
                "문장 끝을 흐리지 않고 또렷하게 마무리한다."
            ]
        ),
        .replaceFillerWithSilence: CoachDrill(
            type: .replaceFillerWithSilence,
            title: "군더더기 말 → 침묵 치환",
            durationSec: 180,
            guide: "군더더기 말 대신 짧은 침묵을 사용하는 연습으로, 말의 안정감을 높입니다.",
            steps: [
                "금지어(어/음/그)를 정한다.",
                "군더더기 말이 나오면 바로 멈추고 이전 문장을 다시 시작한다.",
                "침묵이 들어간 문장을 다시 들어본다."
            ]
        ),
        .emphasizeKeywordTone: CoachDrill(
            type: .emphasizeKeywordTone,
            title: "핵심 단어 톤 강조",
            durationSec: 120,
            guide: "문장에서 가장 중요한 단어 하나에만 톤을 실어 의미를 분명히 전달하는 연습입니다.",
            steps: [
                "문장에서 가장 중요한 단어 하나를 고른다.",
                "그 단어에서만 톤을 올려 말한다."
            ]
        ),
        .conclusionFirst: CoachDrill(
            type: .conclusionFirst,
            title: "결론 먼저 말하기",
            durationSec: 150,
            guide: "말의 시작을 결론으로 열어, 듣는 사람이 핵심을 바로 이해하게 만드는 연습입니다.",
            steps: [
                "결론을 한 문장으로 정리한다.",
                "이유를 하나만 덧붙여 말한다."
            ]
        ),
        .emphasizeSingleKeyword: CoachDrill(
            type: .emphasizeSingleKeyword,
            title: "핵심 단어 1개 강조",
            durationSec: 90,
            guide: "여러 단어를 강조하지 않고, 핵심 단어 하나에만 집중하는 연습입니다.",
            steps: [
                "문장에서 가장 중요한 단어 하나를 고른다.",
                "그 단어만 또렷하게 강조해 말한다."
            ]
        )
    ]
}
