//
//  CoachIssueCategory+CoachAssistContent.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/22/25.
//

import Foundation

enum CoachIssueCategory: String, CaseIterable, Hashable, Codable {
    case paceFast
    case paceSlow
    case fillerWords
    case monotone
    case unclearStructure
    case weakEmphasis
}

struct CoachAssistContent: Hashable {
    /// 신규 강사가 문제를 "말로 풀어 설명"할 때 쓰는 문장
    let diagnosis: String
    let coachingScripts: [String]

    /// 바로 연결되는 연습 방법
    let drills: [CoachDrill]
}

extension CoachAssistContent {

    static func content(for category: CoachIssueCategory) -> CoachAssistContent {
        mapping[category] ?? placeholder
    }

    // MARK: - Mapping Table

    private static let mapping: [CoachIssueCategory: CoachAssistContent] = [

        // MARK: - Pace

        .paceFast: CoachAssistContent(
            diagnosis: "정보량에 비해 말의 속도가 빨라 핵심이 묻힐 수 있어요.",
            coachingScripts: [
                "좋아요. 핵심 단어에서만 속도를 10% 낮추고, 문장 끝에 한 박자 쉬어볼게요.",
                "이 문장은 ‘핵심 → 멈춤 → 마무리’ 순서로 다시 한 번 말해볼까요?"
            ],
            drills: [
                CoachDrill(
                    title: "20초 → 25초 늘리기 드릴",
                    durationSec: 120,
                    steps: [
                        "같은 내용을 20초로 말한다.",
                        "같은 내용을 25초로 말하되 핵심 단어에서만 잠깐 멈춘다.",
                        "두 버전의 차이를 직접 느껴본다."
                    ]
                )
            ]
        ),

        .paceSlow: CoachAssistContent(
            diagnosis: "속도가 느려 에너지가 낮게 느껴질 수 있어요.",
            coachingScripts: [
                "멈춤은 유지하되, 문장 어미를 또렷하게 살려볼게요.",
                "이 문장은 박자를 조금 더 타이트하게 가져가볼까요?"
            ],
            drills: [
                CoachDrill(
                    title: "리듬 고정 드릴",
                    durationSec: 90,
                    steps: [
                        "한 문장을 일정한 박자로 말한다.",
                        "문장 사이 멈춤은 유지하되 어미를 흐리지 않는다."
                    ]
                )
            ]
        ),

        // MARK: - Filler

        .fillerWords: CoachAssistContent(
            diagnosis: "군더더기(음, 어)가 많아 확신이 약해 보일 수 있어요.",
            coachingScripts: [
                "필러 대신 0.3초 침묵으로 바꿔볼게요.",
                "생각할 시간이 필요하면 말하지 말고 잠깐 멈춰도 괜찮아요."
            ],
            drills: [
                CoachDrill(
                    title: "금지어 → 침묵 치환 드릴",
                    durationSec: 180,
                    steps: [
                        "금지어(음/어/그)를 정한다.",
                        "30초 말하기 중 금지어가 나오면 멈추고 다시 시작한다.",
                        "침묵이 들어간 구간을 다시 들어본다."
                    ]
                )
            ]
        ),

        // MARK: - Tone

        .monotone: CoachAssistContent(
            diagnosis: "톤 변화가 적어 중요한 포인트가 살아나지 않아요.",
            coachingScripts: [
                "핵심 단어에서만 톤을 한 단계 올려볼게요.",
                "중요하지 않은 부분은 자연스럽게 흘려도 괜찮아요."
            ],
            drills: [
                CoachDrill(
                    title: "강조 단어 표시 드릴",
                    durationSec: 120,
                    steps: [
                        "문장에서 강조할 단어 3개를 고른다.",
                        "그 단어에서만 톤을 올려 말한다."
                    ]
                )
            ]
        ),

        // MARK: - Structure

        .unclearStructure: CoachAssistContent(
            diagnosis: "구조가 한 번에 들어오지 않아 이해가 어려울 수 있어요.",
            coachingScripts: [
                "결론을 먼저 말하고 이유를 붙여볼게요.",
                "이 문장은 ‘한 줄 요약 → 설명’ 구조로 다시 가볼까요?"
            ],
            drills: [
                CoachDrill(
                    title: "결론 먼저 말하기 드릴",
                    durationSec: 150,
                    steps: [
                        "말하고 싶은 내용을 한 문장 결론으로 정리한다.",
                        "그 다음 이유를 한 개만 덧붙인다."
                    ]
                )
            ]
        ),

        // MARK: - Emphasis

        .weakEmphasis: CoachAssistContent(
            diagnosis: "강조가 약해 중요한 메시지가 잘 남지 않아요.",
            coachingScripts: [
                "이 문장에서 꼭 남겨야 할 단어 하나만 강조해볼게요.",
                "모든 걸 강조하려 하지 말고 하나만 살려볼까요?"
            ],
            drills: [
                CoachDrill(
                    title: "핵심 단어 1개 강조 드릴",
                    durationSec: 90,
                    steps: [
                        "문장에서 가장 중요한 단어를 하나 고른다.",
                        "그 단어만 또렷하게 강조해 말한다."
                    ]
                )
            ]
        )
    ]

    // MARK: - Fallback

    private static let placeholder = CoachAssistContent(
        diagnosis: "이 항목에 대한 코칭 예시는 준비 중입니다.",
        coachingScripts: [],
        drills: []
    )
}

