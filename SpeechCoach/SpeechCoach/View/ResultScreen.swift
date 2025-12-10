//
//  ResultScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI

struct ResultScreen: View {
    let record: SpeechRecord
    
    @EnvironmentObject private var recordStore: SpeechRecordStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedTranscript: String = ""
    @State private var introText: String
    @State private var strenthsText: String
    @State private var improvementsText: String
    @State private var nextStepsText: String
    
    @State private var showCopyAlert = false
    @State private var previousRecord: SpeechRecord?
    
    init(record: SpeechRecord) {
        self.record = record
        _introText = State(initialValue: record.noteIntro)
        _strenthsText = State(initialValue: record.noteStrengths)
        _improvementsText = State(initialValue: record.noteImprovements)
        _nextStepsText = State(initialValue: record.noteNextStep)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                metricsSection
                progressSection
                
                if !record.fillerWords.isEmpty {
                    fillerDetailSection
                }
                
                transcriptionSection
                noteSections
                feedbackActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("분석 결과")
        .navigationBarTitleDisplayMode(.inline)
        .alert("피드백이 복사되었어요", isPresented: $showCopyAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("카톡에 붙여넣기 하면 바로 보낼 수 있어요.")
        }
        .onAppear {
            previousRecord = recordStore.previousRecord(before: record.id)
            editedTranscript = record.transcript
        }
        .navigationBarItems(trailing: Button("저장") {
            saveNotes()
        })
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cleanTitle(from: record.title))
                .font(.title3.weight(.semibold))
            HStack(spacing: 8) {
                Text(formattedDate(record.createdAt))
                Text("·")
                Text(durationString(record.duration))
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("말하기 지표")
                .font(.headline)
            
            VStack(spacing: 12) {
                metricCard(
                    title: "말하기 속도",
                    value: "\(record.wordsPerMinute) WPM",
                    detail: wpmComment
                )
                
                metricCard(
                    title: "필러 단어",
                    value: "\(record.fillerCount)회",
                    detail: fillerComment
                )
            }
        }
    }
    
    private func metricCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var progressSection: some View {
        Group {
            if let prev = previousRecord {
                VStack(alignment: .leading, spacing: 6) {
                    Text("이번 영상 vs 이전 영상")
                        .font(.headline)
                    
                    let wpmDiff = record.wordsPerMinute - prev.wordsPerMinute
                    let fillerDiff = record.fillerCount - prev.fillerCount
                    
                    Text("· 속도: \(prev.wordsPerMinute) → \(record.wordsPerMinute) WPM (\(diffString(wpmDiff)))")
                        .font(.subheadline)
                    Text("· 필러: \(prev.fillerCount) → \(record.fillerCount)회 (\(diffString(-fillerDiff)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                }
            }
        }
    }
    
    private var fillerDetailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("필러 단어 상세")
                .font(.headline)
            let items = record.fillerWords.sorted { $0.key < $1.key }
            if items.isEmpty {
                Text("추출된 필러 단어가 없어요.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(
                    items
                        .map { "\($0.key)(\($0.value))" }
                        .joined(separator: " · ")
                )
                .font(.subheadline)
            }
        }
    }
    
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("전체 스크립트")
                    .font(.headline)
                
                Text("자동 인식 초안")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text("※ 아래 텍스트는 영상에서 자동으로 인식한 초안이라, 일부 단어가 부정확할 수 있어요. 중요한 문장은 영상과 함께 한 번 더 확인해 주세요.")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(record.transcript.isEmpty ? "인식된 텍스트가 없어요." : record.transcript)
                .font(.body)
                .foregroundColor(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }
    
    private var noteSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("인사 / 전체 인상")
                        .font(.headline)
                    Spacer()
                    Button("인사 템플릿") {
                        appendTemplate(
                            &introText,
                            template:
                            """
                            \(record.studentName). 안녕하세요 :)
                            보내주신 과제 영상에 대한 피드백 남겨드립니다.
                            첫 촬영이라 익숙하지 않으셨을 텐데 차분히 연습해주셔서 감사합니다.
                            """
                        )
                    }
                    .font(.caption)
                }
                TextEditor(text: $introText)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("잘된 점 / 강점")
                        .font(.headline)
                    Spacer()
                    Button("강점 템플릿") {
                        let template =
                        """
                        전반적으로 차분하게 잘 해주셨습니다.
                        특히 \(wpmStrengthHighlight) 부분에서 전달력이 좋게 느껴집니다.
                        """
                        appendTemplate(&strenthsText, template: template)
                    }
                    .font(.caption)
                }
                TextEditor(text: $strenthsText)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("개선할 점")
                        .font(.headline)
                    Spacer()
                    Menu("개선 템플릿") {
                        Button("속도 관련 코멘트") {
                            appendTemplate(
                                &improvementsText,
                                template: wpmImprovementTemplate
                            )
                        }
                        Button("필러 관련 코멘트") {
                            appendTemplate(
                                &improvementsText,
                                template: fillerImprovementTemplate
                            )
                        }
                        Button("표정/시선 코멘트") {
                            appendTemplate(
                                &improvementsText,
                                template:
                                    """
                                    촬영 후 표정과 시선을 꼭 한 번 더 확인해보세요.
                                    답변 내용에 비해 표정이 조금 경직되어 보여 아쉬운 부분이 있습니다.
                                    """
                            )
                        }
                    }
                    .font(.caption)
                }
                
                TextEditor(text: $improvementsText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("다음 연습 / 수업 방향")
                        .font(.headline)
                    Spacer()
                    Button("다음 연습 템플릿") {
                        appendTemplate(
                            &nextStepsText,
                            template:
                                """
                                면접 시간만큼(약 10분) 지금의 전달력을 유지하는 연습을 해보면 좋겠습니다.
                                다음 수업에서 이 부분을 원포인트로 함께 다뤄보겠습니다.
                                """
                        )
                    }
                    .font(.caption)
                }
                
                TextEditor(text: $nextStepsText)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(record.title)
                .font(.headline)
            HStack(spacing: 12) {
                Label(durationString(record.duration), systemImage: "clock")
                Text(formattedDate(record.createdAt))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var feedbackActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                saveNotes()
                dismiss()
            } label: {
                Text("메모 저장")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            Button {
                let text = makeFeedbackText()
                UIPasteboard.general.string = text
                showCopyAlert = true
            } label: {
                Text("피드백 텍스트 복사하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.top, 4)
    }
    
    private func saveNotes() {
        recordStore
            .updateNotes(
                for: record.id,
                intro: introText.trimmingCharacters(in: .whitespacesAndNewlines),
                strenghts: strenthsText.trimmingCharacters(in: .whitespacesAndNewlines),
                improvements: improvementsText.trimmingCharacters(in: .whitespacesAndNewlines),
                nextStep: nextStepsText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        
        if editedTranscript != record.transcript {
            AutoCorrectionStore.shared.learn(
                from: record.transcript,
                edited: editedTranscript
            )
        }
    }
    
    private func appendTemplate(_ text: inout String, template: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text = template
        } else {
            text += "\n\n" + template
        }
    }
    
    private var wpmComment: String {
        let wpm = record.wordsPerMinute
        switch wpm {
        case 0:
            return "속도 정보가 없어요."
        case ..<110:
            return "조금 느린 편이에요. 말 사이 간격을 조금만 줄이면 전달력이 좋아질 것 같아요."
        case 110...160:
            return "듣기 편한 속도에요. 이 속도를 기준으로 유지해보면 좋아요."
        default:
            return "조금 빠른 편이에요. 중요한 문장에서 한 박자 쉬어가는 연습을 해보면 좋아요."
        }
    }
    
    private var fillerComment: String {
        let count = record.fillerCount
        switch count {
        case 0:
            return "필러가 거의 없어서 아주 또렷하게 들려요."
        case 1...3:
            return "자연스러운 범위의 필어예요. 전달에 큰 방해는 되지 않아요."
        case 4...8:
            return "필러가 조금 느껴져요. 문장 사이에 짧은 호흡을 넣어보면 좋아요."
        default:
            return "필러가 자주 등장해요. '음' 대신 잠깐 멈추는 연습을 해보면 효과가 클 것 같아요."
        }
    }
    
    private var wpmStrengthHighlight: String {
        let wpm = record.wordsPerMinute
        switch wpm {
        case 0..<110:
            return "차분하게 내용을 전달하시는"
        case 110...160:
            return "듣기 편한 속도로 말해주시는"
        default:
            return "에너지가 느껴지는 말하기 속도의"
        }
    }
    
    private var wpmImprovementTemplate : String {
        let wpm = record.wordsPerMinute
        switch wpm {
        case ..<110:
            return """
            목소리 전달력을 조금 더 높여보면 좋겠습니다.
            지금은 답변이라기보다는 혼자 연습하는 느낌이 강하게 들 수 있습니다.
            복압을 활용해서 조금 더 뱉어내듯 발화해보세요.
            """
        case 110...160:
            return """
            전체적인 속도는 좋지만, 중요한 문장에서는 한 박자 여유를 두면 더 설득력 있게 들릴 수 있습니다.
            문장과 문장 사이 간격을 조금만 더 의식해보세요.
            """
        default:
            return """
            속도가 다소 빠른 편이라 정보량이 많은 부분에서 전달력이 떨어질 수 있습니다.
            핵심 문장에서 속도를 한 번 낮추고 호흡을 정리하는 연습을 해보면 좋겠습니다.
            """
        }
    }
    
    private var fillerImprovementTemplate: String {
        if record.fillerCount == 0 {
            return """
            필러 단어는 거의 사용하지 않으셔서 전달력이 매우 또렷하게 들립니다.
            지금 패턴을 유지해보시면 좋겠습니다.
            """
        } else {
            return """
            '음'과 같은 필러가 중간중간 등장합니다.
            생각이 날 때마나 바로 말을 시작하기보다는, 짧게 멈춘 후 문장을 이어가 보는 연습을 해보세요.
            """
        }
    }
    
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func makeFeedbackText() -> String {
        var lines: [String] = []
        
        let name = record.studentName.isEmpty ? "학생님" : record.studentName
        lines.append("\(name). 안녕하세요 :)")
        lines.append("")
        
        if !introText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append(introText.trimmingCharacters(in: .whitespacesAndNewlines))
            lines.append("")
        }
        
        lines.append("1. 잘된 점")
        if !strenthsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append(strenthsText.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            lines.append("전반적으로 차분하게 잘 해주셨습니다.")
        }
        lines.append("")
        
        lines.append("2. 개선할 점")
        if !improvementsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append(improvementsText.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            lines.append("말하기 속도와 필러 사용을 조금 더 의식해보시면 좋겠습니다.")
        }
        lines.append("")
        
        lines.append("3. 다음 연습 / 수업 방향")
        if !nextStepsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append(nextStepsText.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            lines.append("다음 수업에서 오늘 내용을 바탕으로 한 번 더 연습해보겠습니다.")
        }
        lines.append("")
        
        lines.append("수업에서 뵙겠습니다.")
        lines.append("수고 많으셨습니다.")
        
        return lines.joined(separator: "\n")
    }
    
    private func diffString(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        if value < 0 { return "\(value)" }
        return "변화 없음"
    }
}

#Preview {
//    ResultScreen(
//        record: .init(
//            id: UUID(),
//            createdAt: Date(),
//            title: "예시 발표 영상",
//            duration: 120,
//            wordsPerMinute: 150,
//            fillerCount: 5,
//            transcript: """
//                안녕하세요, 저는 iOS 개발자 양희정입니다.
//                오늘은 제가 준비한 스피치 과제를 발표하겠습니다...
//                
//                (실제 구현에서는 음성 인식 결과 텍스트가 들어갈 영역)
//                """,
//            note: "",
//            videoURL: URL(fileURLWithPath: "/dev/null"),
//            fillerWords: [
//                "음": 3,
//                "어": 2,
//                "그니까": 1
//            ]
//        )
//    )
}
