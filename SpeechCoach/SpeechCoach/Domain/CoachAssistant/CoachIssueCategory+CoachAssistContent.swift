//
//  CoachIssueCategory+CoachAssistContent.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/22/25.
//

import Foundation

enum HighlightSeverity: Int, CaseIterable, Hashable, Codable {
    case low = 1
    case medium
    case high
}

enum CoachIssueCategory: String, CaseIterable, Hashable, Codable {
    case paceFast
    case paceSlow
    case longPause
    case fillerWords
    case monotone
    case unclearStructure
    case weakEmphasis
    case unclearPronunciation
}

struct CoachAssistContent: Hashable, Codable {
    var problemSummary: String
    var listenerImpact: [String]
    var checkpoints: [String]

    var likelyCauses: [String]
    var diagnosticQuestions: [String]

    var coachingOneLiner: String
    var coachingScript30s: String
    var alternativePhrases: [String]
    var doSay: [String]
    var avoidSay: [String]

    var drills: [CoachDrill]
}

extension CoachAssistContent {
    var isPlaceholder: Bool {
        problemSummary.contains("준비 중") || coachingOneLiner.isEmpty
    }
}

extension CoachAssistContent {

    static func content(for category: CoachIssueCategory) -> CoachAssistContent {
        mapping[category] ?? placeholder
    }

    // MARK: - Mapping Table

    private static let mapping: [CoachIssueCategory: CoachAssistContent] = [

        // MARK: - Pace Fast

        .paceFast: CoachAssistContent(
            problemSummary: "말의 속도가 빨라 핵심 메시지가 청자에게 충분히 전달되지 않을 수 있어요.",
            listenerImpact: [
                "중요한 포인트를 놓칠 수 있음",
                "전달력이 급해 보이거나 불안하게 느껴질 수 있음"
            ],
            checkpoints: [
                "핵심 단어에서 속도를 낮췄는가?",
                "문장 끝을 급하게 닫지 않았는가?"
            ],
            likelyCauses: [
                "호흡이 짧아 문장을 빨리 마무리하려는 경향",
                "중요/비중요 구간을 같은 속도로 말함"
            ],
            diagnosticQuestions: [
                "이 문장에서 가장 중요한 단어는 무엇인가요?",
                "그 단어를 말할 때도 속도가 같았나요?"
            ],
            coachingOneLiner: "핵심 단어에서만 속도를 10% 낮추고, 문장 끝에 한 박자 쉬어볼게요.",
            coachingScript30s: """
            지금 구간은 속도가 조금 빨라서 내용이 좋아도 핵심이 충분히 남지 않을 수 있어요.
            중요한 단어를 말할 때만 속도를 살짝 낮추고,
            문장 끝에서 한 박자 쉬어주면 전달력이 훨씬 좋아집니다.
            같은 문장을 한 번 더, ‘핵심-멈춤-마무리’로 말해볼까요?
            """,
            alternativePhrases: [
                "핵심어에서만 속도를 낮춰볼게요.",
                "이 문장은 끝을 조금 더 열어둘게요."
            ],
            doSay: [
                "핵심 단어에서만 속도를 낮춰볼게요.",
                "문장 끝에 한 박자 쉬어볼게요."
            ],
            avoidSay: [
                "너무 빨라요.",
                "천천히 말하세요."
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

        // MARK: - Pace Slow

        .paceSlow: CoachAssistContent(
            problemSummary: "말의 속도가 느려 전체적인 에너지와 집중도가 떨어질 수 있어요.",
            listenerImpact: [
                "집중력이 쉽게 흐트러질 수 있음",
                "전달이 늘어져 보일 수 있음"
            ],
            checkpoints: [
                "불필요한 멈춤이 길지 않았는가?",
                "어미가 흐려지지 않았는가?"
            ],
            likelyCauses: [
                "문장 구조를 즉석에서 고민함",
                "강조와 멈춤을 구분하지 못함"
            ],
            diagnosticQuestions: [
                "여기서 꼭 강조해야 할 단어는 무엇이었나요?",
                "모든 문장에서 같은 속도로 말하고 있지는 않았나요?"
            ],
            coachingOneLiner: "멈춤은 유지하되, 어미를 또렷하게 가져가볼게요.",
            coachingScript30s: """
            속도가 느린 건 나쁜 게 아니에요.
            다만 모든 구간이 같은 속도면 에너지가 떨어져 보일 수 있어요.
            멈춤이 필요한 곳만 살리고,
            문장 어미는 또렷하게 닫아볼게요.
            """,
            alternativePhrases: [
                "이 문장은 리듬을 조금 더 타이트하게 가볼게요.",
                "강조 구간만 천천히 해볼게요."
            ],
            doSay: [
                "어미를 또렷하게 닫아볼게요.",
                "강조 구간만 속도를 조절해볼게요."
            ],
            avoidSay: [
                "너무 느려요.",
                "빨리 말해보세요."
            ],
            drills: [
                CoachDrill(
                    title: "리듬 고정 드릴",
                    durationSec: 90,
                    steps: [
                        "한 문장을 일정한 박자로 말한다.",
                        "문장 끝을 흐리지 않고 또렷하게 마무리한다."
                    ]
                )
            ]
        ),

        // MARK: - Filler Words

        .fillerWords: CoachAssistContent(
            problemSummary: "군더더기 단어가 많아 말의 신뢰도가 낮아 보일 수 있어요.",
            listenerImpact: [
                "자신감이 부족해 보일 수 있음",
                "핵심 메시지가 분산됨"
            ],
            checkpoints: [
                "문장 시작이 필러로 열리지 않았는가?",
                "핵심 문장에 군더더기가 끼지 않았는가?"
            ],
            likelyCauses: [
                "생각을 정리하기 전에 말이 먼저 나옴",
                "침묵을 불편하게 느끼는 습관"
            ],
            diagnosticQuestions: [
                "생각할 시간이 필요할 때 어떻게 했나요?",
                "침묵을 의도적으로 써본 적이 있나요?"
            ],
            coachingOneLiner: "필러 대신 0.3초 침묵으로 바꿔볼게요.",
            coachingScript30s: """
            ‘어, 음’ 같은 군더더기는 생각할 시간이 필요할 때 나오는 경우가 많아요.
            이걸 없애려고 애쓰기보다,
            말 대신 짧은 침묵으로 바꿔보는 게 좋아요.
            침묵은 실수가 아니라 여유로 들릴 수 있어요.
            """,
            alternativePhrases: [
                "결론부터 말하면 ___입니다.",
                "제가 제안드리고 싶은 건 ___예요."
            ],
            doSay: [
                "결론부터 말씀드리면 ___입니다.",
                "제가 중요하게 보고 싶은 건 ___예요."
            ],
            avoidSay: [
                "어…",
                "음…"
            ],
            drills: [
                CoachDrill(
                    title: "필러 → 침묵 치환 드릴",
                    durationSec: 180,
                    steps: [
                        "금지어(어/음/그)를 정한다.",
                        "필러가 나오면 바로 멈추고 이전 문장을 다시 시작한다.",
                        "침묵이 들어간 문장을 다시 들어본다."
                    ]
                )
            ]
        ),

        // MARK: - Monotone

        .monotone: CoachAssistContent(
            problemSummary: "톤 변화가 적어 중요한 포인트가 잘 드러나지 않아요.",
            listenerImpact: [
                "청자가 중요도를 구분하기 어려움",
                "집중도가 떨어질 수 있음"
            ],
            checkpoints: [
                "핵심 단어에 톤 변화가 있었는가?",
                "문장 끝이 떠 있지 않았는가?"
            ],
            likelyCauses: [
                "모든 문장을 같은 중요도로 인식함",
                "강조 포인트를 의식하지 않음"
            ],
            diagnosticQuestions: [
                "이 문장에서 꼭 남겨야 할 단어는 무엇이었나요?",
                "그 단어를 어떻게 강조했나요?"
            ],
            coachingOneLiner: "핵심 단어에서만 톤을 한 단계 올려볼게요.",
            coachingScript30s: """
            모든 문장을 같은 톤으로 말하면
            청자는 어디가 중요한지 알기 어려워요.
            꼭 남겨야 할 단어 하나만 정해서
            그 단어에서만 톤을 올려보는 연습을 해볼게요.
            """,
            alternativePhrases: [
                "이 단어가 핵심이에요.",
                "여기가 가장 중요해요."
            ],
            doSay: [
                "가장 중요한 단어는 ___예요.",
                "이 부분은 꼭 기억해주세요."
            ],
            avoidSay: [
                "전체적으로 밋밋해요."
            ],
            drills: [
                CoachDrill(
                    title: "핵심 단어 톤 강조 드릴",
                    durationSec: 120,
                    steps: [
                        "문장에서 가장 중요한 단어 하나를 고른다.",
                        "그 단어에서만 톤을 올려 말한다."
                    ]
                )
            ]
        ),

        // MARK: - Unclear Structure

        .unclearStructure: CoachAssistContent(
            problemSummary: "말의 구조가 한 번에 들어오지 않아 이해하기 어려울 수 있어요.",
            listenerImpact: [
                "결론이 무엇인지 헷갈릴 수 있음",
                "피드백이 실행으로 이어지기 어려움"
            ],
            checkpoints: [
                "결론이 초반에 나왔는가?",
                "이유와 예시가 과하지 않았는가?"
            ],
            likelyCauses: [
                "말하면서 구조를 동시에 고민함",
                "전달 순서를 명확히 정하지 않음"
            ],
            diagnosticQuestions: [
                "이 말의 결론은 한 문장으로 뭐였나요?",
                "그 결론을 언제 말했나요?"
            ],
            coachingOneLiner: "결론을 먼저 말하고, 이유를 하나만 붙여볼게요.",
            coachingScript30s: """
            구조가 복잡하면 좋은 내용도 잘 안 들어와요.
            그래서 먼저 결론을 한 문장으로 말하고,
            이유는 하나만 붙여보는 게 좋아요.
            이 순서로 다시 한 번 말해볼까요?
            """,
            alternativePhrases: [
                "결론부터 말씀드리면 ___입니다.",
                "이유는 한 가지예요."
            ],
            doSay: [
                "결론은 ___입니다.",
                "이유는 ___입니다."
            ],
            avoidSay: [
                "이것도 있고 저것도 있는데요…"
            ],
            drills: [
                CoachDrill(
                    title: "결론 먼저 말하기 드릴",
                    durationSec: 150,
                    steps: [
                        "결론을 한 문장으로 정리한다.",
                        "이유를 하나만 덧붙여 말한다."
                    ]
                )
            ]
        ),

        // MARK: - Weak Emphasis

        .weakEmphasis: CoachAssistContent(
            problemSummary: "강조가 약해 중요한 메시지가 잘 남지 않아요.",
            listenerImpact: [
                "무엇을 고쳐야 할지 모호해짐",
                "피드백의 실행력이 떨어짐"
            ],
            checkpoints: [
                "강조 단어가 하나로 좁혀졌는가?",
                "강조 전에 표식이 있었는가?"
            ],
            likelyCauses: [
                "모든 내용을 비슷한 중요도로 다룸",
                "강조를 과하게 하거나 아예 하지 않음"
            ],
            diagnosticQuestions: [
                "이 문장에서 꼭 남겨야 할 단어는 무엇이었나요?",
                "그 단어를 어떻게 표시했나요?"
            ],
            coachingOneLiner: "이 문장에서 꼭 남겨야 할 단어 하나만 강조해볼게요.",
            coachingScript30s: """
            모든 걸 강조하려 하면
            오히려 아무 것도 남지 않을 수 있어요.
            이 문장에서 가장 중요한 단어 하나만 정해서
            그 단어를 분명하게 살려볼게요.
            """,
            alternativePhrases: [
                "핵심은 딱 하나예요.",
                "가장 중요한 건 ___입니다."
            ],
            doSay: [
                "가장 중요한 단어는 ___예요.",
                "핵심은 ___입니다."
            ],
            avoidSay: [
                "전부 중요해요."
            ],
            drills: [
                CoachDrill(
                    title: "핵심 단어 1개 강조 드릴",
                    durationSec: 90,
                    steps: [
                        "문장에서 가장 중요한 단어 하나를 고른다.",
                        "그 단어만 또렷하게 강조해 말한다."
                    ]
                )
            ]
        )
    ]

    // MARK: - Fallback

    private static let placeholder = CoachAssistContent(
        problemSummary: "이 항목에 대한 코칭 콘텐츠는 준비 중입니다.",
        listenerImpact: [],
        checkpoints: [],
        likelyCauses: [],
        diagnosticQuestions: [],
        coachingOneLiner: "",
        coachingScript30s: "",
        alternativePhrases: [],
        doSay: [],
        avoidSay: [],
        drills: []
    )
}

extension CoachAssistContent {
    static func makeFallback(from record: SpeechRecord, highlight: SpeechHighlight) -> CoachAssistContent {
        CoachAssistContent(
            problemSummary: highlight.title,
            listenerImpact: ["요점이 분산되어 전달력이 떨어질 수 있어요."],
            checkpoints: ["결론을 먼저 말했는가?", "한 문장 길이가 너무 길지 않은가?"],
            likelyCauses: ["생각 정리 전에 말이 먼저 나옴", "핵심 메시지 우선순위가 불명확"],
            diagnosticQuestions: ["이 답변의 결론은 한 문장으로 뭐예요?", "지금 예시는 결론을 강화하나요?"],
            coachingOneLiner: "결론 한 문장 → 근거 2개 → 예시 1개로 정리해보세요.",
            coachingScript30s: "먼저 결론을 한 문장으로 말하고, 이유를 두 가지로 정리한 다음, 마지막에 짧은 예시로 마무리해보세요. 문장 길이는 짧게 끊고, 한 번 숨 고르는 타이밍을 넣으면 전달력이 좋아져요.",
            alternativePhrases: ["정리하면, 핵심은 ~입니다.", "결론부터 말씀드리면 ~입니다."],
            doSay: ["결론부터 말씀드리면 ~입니다.", "이유는 두 가지입니다."],
            avoidSay: ["음… 그러니까…", "아무튼…"],
            drills: []   // CoachDrill을 지금 당장 만들기 어려우면 빈 배열로
        )
    }
}
