//
//  FeedbackSheet.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/10/25.
//

import SwiftUI

struct FeedbackSheet: View {
    let record: SpeechRecord

    // 초기 값은 기존에 저장된 메모 있으면 그걸로, 없으면 빈 문자열
    @State private var introText: String
    @State private var strengthsText: String
    @State private var improvementsText: String
    @State private var nextStepsText: String

    let onSave: (String, String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showCopyAlert = false

    init(record: SpeechRecord,
         onSave: @escaping (String, String, String, String) -> Void) {
        self.record = record
        self.onSave = onSave
        _introText = State(initialValue: record.noteIntro ?? "")
        _strengthsText = State(initialValue: record.noteStrengths ?? "")
        _improvementsText = State(initialValue: record.noteImprovements ?? "")
        _nextStepsText = State(initialValue: record.noteNextStep ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section(
                        title: "전체 느낌 / 인사",
                        text: $introText,
                        templates: [
                            "영상 잘 봤습니다 :)",
                            "지난 과제보다 훨씬 안정적으로 들립니다.",
                            "성실하게 연습해주셔서 감사합니다."
                        ]
                    )

                    section(
                        title: "잘한 점",
                        text: $strengthsText,
                        templates: [
                            "속도가 일정해서 듣기 편합니다.",
                            "호흡이 훨씬 자연스러워졌습니다.",
                            "전달력이 좋아져서 실전 답변처럼 들립니다."
                        ]
                    )

                    section(
                        title: "개선 포인트",
                        text: $improvementsText,
                        templates: [
                            "종결 어미를 조금 더 또렷하게 마무리해보면 좋겠습니다.",
                            "중간에 시선이 아래로 떨어지는 부분을 한 번 더 점검해보세요.",
                            "문장과 문장 사이에 약간의 여유를 두면 안정감이 생깁니다."
                        ]
                    )

                    section(
                        title: "다음 연습 방향",
                        text: $nextStepsText,
                        templates: [
                            "오늘 피드백 기준으로 2~3번 더 촬영해보시면 좋겠습니다.",
                            "실제 면접 시간(10분)을 가정하고 체력을 유지하는 연습을 해봅시다.",
                            "다음 수업에서는 답변 구조를 한 번 더 정리해보겠습니다."
                        ]
                    )

                    Button {
                        copyToPasteboard()
                    } label: {
                        Label("카톡으로 복사하기", systemImage: "doc.on.doc")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .navigationTitle("피드백 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(
                            introText.trimmed,
                            strengthsText.trimmed,
                            improvementsText.trimmed,
                            nextStepsText.trimmed
                        )
                    }
                }
            }
            .alert("피드백이 복사되었어요", isPresented: $showCopyAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("카톡에 붙여넣기 하면 바로 보낼 수 있어요.")
            }
        }
        .presentationDetents([.medium, .large])  // 예전 시트 느낌
        .presentationDragIndicator(.visible)
    }

    private func section(
        title: String,
        text: Binding<String>,
        templates: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            // 템플릿 칩
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(templates, id: \.self) { template in
                        Button {
                            if text.wrappedValue.isEmpty {
                                text.wrappedValue = template
                            } else {
                                text.wrappedValue += "\n" + template
                            }
                        } label: {
                            Text(template)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .cornerRadius(999)
                        }
                    }
                }
            }

            TextEditor(text: text)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
        }
    }

    private func copyToPasteboard() {
        let combined = """
        \(introText.trimmed)

        [잘한 점]
        \(strengthsText.trimmed)

        [개선 포인트]
        \(improvementsText.trimmed)

        [다음 연습 방향]
        \(nextStepsText.trimmed)
        """
        UIPasteboard.general.string = combined
        showCopyAlert = true
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
