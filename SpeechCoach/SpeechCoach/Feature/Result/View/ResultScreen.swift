//
//  ResultScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI
import AlertToast
import AVKit

extension ResultScreen {
    enum ResultTab: String, CaseIterable, Identifiable {
        case feedback = "노트"
        case analysis = "분석"
        var id: String { rawValue }
    }
}

struct ResultScreen: View {
    let recordID: UUID
    let playbackPolicy: HighlightPlaybackPolicy
    let highlightContext: HighlightListContext
    let onRequestPlay: (TimeInterval) -> Void
    let scriptMatches: [ScriptMatchSegment] = []
    @Binding var failedToSave: Bool
    
    @StateObject private var recordVM: ResultRecordViewModel
    @StateObject private var metricsVM: ResultMetricsViewModel
    
    @StateObject private var recommendVM = ResultRecommendationsViewModel()
    @StateObject private var summaryVM = SpeechTypeSummaryViewModel()
        
    @EnvironmentObject private var recordStore: SpeechRecordStore
    @EnvironmentObject private var pc: PlayerController
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.dismiss) private var dismiss
        
    @State private var editedTranscript: String = ""
    
    @State private var introText: String = ""
    @State private var strenthsText: String = ""
    @State private var improvementsText: String = ""
    @State private var nextStepsText: String = ""
    @State private var practiceChecklistText: String = ""
    
    @State private var showCopyAlert = false
    @State private var showToast = false
    @State private var toastTitle: String = ""
    @State private var isSaving = false
    @State private var previousRecord: SpeechRecord?

    @State private var qualitative: QualitativeMetrics = .neutral
    @State private var showSaveAlert = false
    
    @State private var suggestions: [TemplateSuggestion] = []
    
    @State private var selectedTab: ResultTab = .feedback
    @State private var showAdvanced = false
    @State private var showQualitative = false
    
    @State private var isCoachAssistantPresented = false

    @State private var selectedHighlight: SpeechHighlight?
    @State private var showPlayer = false
    @State private var pendingSeek: TimeInterval = 0
    
    @State private var speechType: SpeechTypeSummary? = nil
    
    
    private let oneLineSummaryExamples: [String] = [
        "요약하면, 오늘 영상의 핵심은 결론을 먼저 말하는 것입니다.",
        "결론부터 말하면, 핵심 문장을 더 또렷하게 전달하는 것이 목표입니다.",
        "한 문장으로 말하면, 말의 흐름을 더 간단하게 정리할 필요가 있습니다.",
        "핵심만 말하면, 중요한 문장에서 한 박자 쉬는 연습이 필요합니다."
    ]
    
    struct PlayerRoute: Identifiable, Equatable {
        let id = UUID()
        let recordID: UUID
        let startTime: TimeInterval?
        let autoplay: Bool
    }

    @State private var playerRoute: PlayerRoute?

    init(
        recordID: UUID,
        highlightContext: HighlightListContext,
        playbackPolicy: HighlightPlaybackPolicy,
        onRequestPlay: @escaping (TimeInterval) -> Void,
        failedToSave: Binding<Bool>
    ) {
        self.recordID = recordID
        self.onRequestPlay = onRequestPlay
        self.playbackPolicy = playbackPolicy
        self.highlightContext = highlightContext
        self._failedToSave = failedToSave
        
        _recordVM = StateObject(wrappedValue: ResultRecordViewModel(recordID: recordID))
        _metricsVM = StateObject(wrappedValue: ResultMetricsViewModel(recordID: recordID))
    }
    
    var body: some View {
        ZStack {
            Group {
                switch (recordVM.record, metricsVM.metrics) {
                case let (.some(record), .some(metrics)):
                    content(record: record, metrics: metrics)
                default:
                    ProgressView("불러오는 중...")
                }
            }
            .navigationTitle("분석 결과")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toast(isPresenting: $showToast){
            AlertToast(
                type: .regular,
                title: toastTitle,
                style: AlertToast.AlertStyle.style(
                    backgroundColor: .black,
                    titleColor: .white,
                    titleFont: .callout
                )
            )
        }
        .toast(isPresenting: $showCopyAlert){
            AlertToast(
                type: .regular,
                title: "복사했어요",
                style: AlertToast.AlertStyle.style(
                    backgroundColor: .black,
                    titleColor: .white,
                    titleFont: .callout
                )
            )
        }
        .task {
            await recordVM.load(using: recordStore)
            
            guard let record = recordVM.record else { return }
            
            await MainActor.run {
                hydrateNoteStateIfNeeded(from: record)
            }
            
            previousRecord = recordStore.previousRecord(before: record.id)
            await metricsVM.load(using: recordStore, previousRecordID: previousRecord?.id)

            if let metrics = metricsVM.metrics {
                if let segments = record.insight?.transcriptSegments, !segments.isEmpty {
                    summaryVM.load(
                        duration: record.duration,
                        wordsPerMinute: metrics.wordsPerMinute,
                        segments: segments
                    )
                } else {
//                    summaryVM.load(from: metrics)
                }
            } else {
                summaryVM.reset()
            }
            
            let series = SpeedSeriesBuilder.make(
                duration: recordVM.record?.duration ?? .zero,
                transcript: record.transcript,
                segments: record.insight?.transcriptSegments,
                binSeconds: 5
            )
            
            recommendVM.buildSuggestions(
                recordID: recordID,
                averageWPM: metricsVM.metrics?.wordsPerMinute ?? .zero,
                speedSeries: series
            )
        }
        .sheet(item: $selectedHighlight) { highlight in
            if let record = recordVM.record {
                CoachAssistantHighlightDetailView(
                    highlight: highlight,
                    record: record,
                    drillCatalog: DrillCatalog.all,
                    onRequestPlay: { _ in }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showPlayer, onDismiss: {
            playerRoute = nil
        }) {
            NavigationStack {
                if let record = recordVM.record {
                    if let url = record.resolvedVideoURL,
                       let route = playerRoute {
                        VideoPlayerScreen(
                            videoURL: url,
                            title: record.title,
                            startTime: route.startTime,
                            autoplay: route.autoplay,
                            mode: VideoPlayerScreenMode.highlightReview(showFeedbackCTA: false)
                        )
                    } else {
                        VideoReconnectView(record: record)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func content(record: SpeechRecord, metrics: SpeechMetrics) -> some View {
        VStack(spacing: 0) {
            headerSection(record: record) { newName in
                Task {
                    await recordVM.updateStudentName(newName, using: recordStore)
                }
            }
            
            Picker("", selection: $selectedTab) {
                ForEach(ResultTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            ZStack {
                ScrollView {
                    feedbackTab(record: record)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                .opacity(selectedTab == .feedback ? 1 : 0)
                .allowsHitTesting(selectedTab == .feedback)
                .accessibilityHidden(selectedTab != .feedback)

                ScrollView {
                    AnalysisTab(
                        record: record,
                        metrics: metrics,
                        previousRecord: previousRecord,
                        previousMetrics: metricsVM.previousMetrics,
                        speechType: summaryVM.speechType,
                        playbackPolicy: playbackPolicy,
                        highlightContext: highlightContext,
                        selectedHighlight: $selectedHighlight,
                        insertIntoImprovements: insertIntoImprovements,
                        presentCoachAssistant: presentCoachAssistant
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .opacity(selectedTab == .analysis ? 1 : 0)
                .allowsHitTesting(selectedTab == .analysis)
                .accessibilityHidden(selectedTab != .analysis)
            }

        }
    }
    
    private func highlightRow(_ item: SpeechHighlight) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(timeString(item.start))–\(timeString(item.end))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !item.detail.isEmpty {
                Text(item.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(item.reason)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func chip(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    private func applySuggestion(_ suggestion: TemplateSuggestion) {
        let sentence = "• \(suggestion.body)"
        switch suggestion.category {
        case .strengths:
            strenthsText = appendLine(strenthsText, sentence)
        case .improvements:
            improvementsText = appendLine(improvementsText, sentence)
        case .nextStep:
            if suggestion.isActionItem {
                practiceChecklistText = appendLine(practiceChecklistText, sentence)
            } else {
                nextStepsText = appendLine(nextStepsText, sentence)
            }
        }
    }
    
    func appendLine(_ original: String, _ newLine: String) -> String {
        if original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return newLine
        } else {
            return (original + "\n" + newLine)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func headerSection(
        record: SpeechRecord,
        onChangeStudentName: @escaping (
            String
        ) -> Void
    ) -> some View {
        HeaderSectionView(
            record: record
        )
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
    
    private func saveNotes(record: SpeechRecord) async throws {
        recordStore.updateNotes(
            for: record.id,
            intro: introText.trimmingCharacters(in: .whitespacesAndNewlines),
            strenghts: strenthsText.trimmingCharacters(in: .whitespacesAndNewlines),
            improvements: improvementsText.trimmingCharacters(in: .whitespacesAndNewlines),
            nextStep: nextStepsText.trimmingCharacters(in: .whitespacesAndNewlines),
            checklist: practiceChecklistText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        recordStore.updateQualitative(
            for: record.id,
            metrics: qualitative
        )
        
        if !editedTranscript.isEmpty,
            editedTranscript != record.transcript {
            AutoCorrectionStore.shared.learn(
                from: record.transcript,
                edited: editedTranscript
            )
        }
        
        try await recordStore.persist()
    }
  
    @discardableResult
    private func setTemplateIfEmpty(
        _ text: inout String,
        template: String
    ) -> Bool {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            withAnimation(.easeInOut(duration: 0.15)) {
                text = template
            }
            return true
        } else {
            return false
        }
    }
    
    private var wpmStrengthHighlight: String {
        let wpm = Int(metricsVM.metrics?.wordsPerMinute ?? 0)
        switch wpm {
        case 0..<110:
            return "차분한 속도예요 (\(wpm) wpm) — 핵심 문장만 조금 더 또렷하게 말해보면 좋아요."
        case 110...160:
            return "듣기 편한 속도예요 (\(wpm) wpm) — 지금 속도를 유지해보세요."
        default:
            return "에너지 있는 속도예요 (\(wpm) wpm) — 핵심 문장에서는 한 박자만 쉬어보세요."
        }
    }
    
    private var wpmImprovementTemplate : String {
        let wpm = metricsVM.metrics?.wordsPerMinute ?? .zero
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
        guard let fillerCount = metricsVM.metrics?.fillerCount else { return "--" }

        if fillerCount == 0 {
            return """
            말이 끊기지 않고 자연스럽게 이어져서 전달력이 또렷하게 느껴져요.
            지금처럼 문장 흐름을 안정적으로 유지해보시면 좋겠습니다.
            """
        } else {
            return """
            문장을 시작할 때 말이 급하게 이어지는 구간이 조금 보여요.
            바로 말을 이어가기보다 한 박자 정리한 뒤 다음 문장을 시작해보세요.
            말의 흐름이 훨씬 안정적으로 들릴 수 있어요.
            """
        }
    }

    private func makeFeedbackText() -> String {
        var lines: [String] = []

        lines.append("내 연습 노트")
        lines.append("")

        // 기록 메타: 날짜/영상명 등
        // guard let record = recordVM.record else { return "--" }
        // lines.append("영상: \(record.title ?? "발표 영상")")
        // lines.append("")

        let summary = introText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty {
            lines.append("한 줄 요약")
            lines.append(summary)
            lines.append("")
        }

        lines.append("좋았던 점")
        let strengths = strenthsText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !strengths.isEmpty {
            lines.append(strengths)
        } else {
            lines.append("• 오늘 영상에서 괜찮았던 점을 2~3개 적어보세요.")
        }
        lines.append("")

        lines.append("다음에 고칠 1가지")
        let improvements = improvementsText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !improvements.isEmpty {
            lines.append(improvements)
        } else {
            lines.append("• 다음 영상에서 하나만 바꾼다면 무엇인지 적어보세요.")
        }
        lines.append("")

        lines.append("다음 연습 목표")
        let nextSteps = nextStepsText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nextSteps.isEmpty {
            lines.append(nextSteps)
        } else {
            lines.append("• 첫 문장을 결론으로 시작하기")
            lines.append("• 핵심 문장마다 0.5초 멈춘 뒤 말하기")
        }
        lines.append("")

        lines.append("지금 바로 해볼 것")
        let checklist = practiceChecklistText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !checklist.isEmpty {
            lines.append(checklist)
        } else {
            lines.append("• 30초 버전으로 다시 말해보기")
            lines.append("• 첫 문장을 결론으로 바꿔서 다시 찍기")
        }

        return lines.joined(separator: "\n")
    }

    private func dismissCoachAssistant() {
        isCoachAssistantPresented = false
        selectedHighlight = nil
    }
    
    @MainActor
    private func hydrateNoteStateIfNeeded(from record: SpeechRecord) {
        let alreadyHasUserInput =
            !introText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !strenthsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !improvementsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !nextStepsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !practiceChecklistText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        guard alreadyHasUserInput == false else { return }

        guard let note = record.note else { return }

        introText = note.intro
        strenthsText = note.strengths
        improvementsText = note.improvements
        nextStepsText = note.nextStep
        practiceChecklistText = note.checklist ?? ""
    }

}

extension ResultScreen {
    
    func noteCard(
        title: String,
        placeholder: String,
        text: Binding<String>,
        templateAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("템플릿") { templateAction() }
                    .font(.caption.weight(.semibold))
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .frame(minHeight: 88)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.25))
                    )
                if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(12)
    }
    
    func memoEditorRow(
        title: String,
        buttonTitle: String,
        placeholder: String,
        text: Binding<String>,
        onTemplateTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button(buttonTitle) { onTemplateTap() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentColor)
            }
            
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                TextEditor(text: text)
                    .font(.body)
                    .padding(8)
                    .frame(minHeight: 110)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
            )
        }
    }
    
}

extension ResultScreen {
    
    func feedbackTab(record: SpeechRecord) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            quickTipsSection
            learnerNoteSections(record: record)
            primaryActionsRow(record: record)
        }
    }
    
    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("빠른 팁")
                .font(.subheadline.weight(.semibold))
            
            if recommendVM.suggestions.isEmpty {
                Text("아직 추천을 만들 데이터가 부족해요. 영상을 한 번 더 분석해보면 정확해져요.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(recommendVM.suggestions) { suggestion in
                            Button {
                                applySuggestion(suggestion)
                            } label: {
                                Text(suggestion.title)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Text("버튼을 누르면 아래 노트에 바로 적용돼요.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    func learnerNoteSections(record: SpeechRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("내 연습 노트")
                .font(.headline)
            
            MemoEditorRow(
                title: "한 줄 요약",
                buttonTitle: "예시 넣기",
                placeholder: "이 영상에서 내가 가장 전하고 싶은 말을 한 문장으로 적어보세요.",
                text: $introText
            ) { highlight in
                guard let example = oneLineSummaryExamples.randomElement() else { return }
                if setTemplateIfEmpty(&introText, template: example) {
                    highlight()
                } else {
                    presentToast("이미 내용이 있어요")
                }
            }
            
            MemoEditorRow(
                title: "좋았던 점",
                buttonTitle: "힌트",
                placeholder: "이번 영상에서 괜찮았던 점 2~3개를 적어보세요. \n(예: 말 속도, 또박또박함, 결론이 잘 보임)",
                text: $strenthsText
            ) { highlight in
                let template = """
                • (예: 말이 차분해서 듣기 편했다)
                • (예: 핵심이 또렷했다)
                • \(wpmStrengthHighlight)
                """
                if setTemplateIfEmpty(&strenthsText, template: template) {
                    highlight()
                } else {
                    presentToast("이미 작성 중이에요")
                }
            }
            
            MemoEditorRow(
                title: "다음에 고칠 1가지",
                buttonTitle: "힌트",
                placeholder: "다음 영상에서 하나만 바꾼다면 뭘 바꿀까요? \n(예: 속도 조금 올리기, 결론 먼저 말하기)",
                text: $improvementsText
            ) { highlight in
                let template = "• \(wpmImprovementTemplate)"
                if setTemplateIfEmpty(&improvementsText, template: template) {
                    highlight()
                } else {
                    presentToast("이미 작성 중이에요")
                }
            }
            
            MemoEditorRow(
                title: "다음 연습 목표",
                buttonTitle: "예시 넣기",
                placeholder: "다음 연습에서 해보고 싶은 목표를 1~2개 적어보세요.",
                text: $nextStepsText
            ) { highlight in
                let template = """
                • 첫 문장을 결론으로 시작하기
                • 핵심 문장마다 0.5초 멈춘 뒤 말하기
                """
                if setTemplateIfEmpty(&nextStepsText, template: template) {
                    highlight()
                } else {
                    presentToast("이미 작성 중이에요")
                }
            }
            
            MemoEditorRow(
                title: "지금 바로 해볼 것",
                buttonTitle: "예시 넣기",
                placeholder: "오늘 바로 할 수 있는 행동을 2~3개 적어보세요.",
                text: $practiceChecklistText
            ) { highlight in
                let template = """
                • 30초 버전으로 다시 말해보기
                • 첫 문장을 결론으로 바꿔서 다시 찍기
                • 멈춘 구간만 다시 보고 한 번 더 말해보기
                """
                if setTemplateIfEmpty(&practiceChecklistText, template: template) {
                    highlight()
                } else {
                    presentToast("이미 작성 중이에요")
                }
            }
        }
    }
    
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("추천 템플릿")
                .font(.subheadline.weight(.semibold))
            
            if recommendVM.suggestions.isEmpty {
                Text("추천을 생성할 데이터가 아직 부족해요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(recommendVM.suggestions) { suggestion in
                            Button {
                                applySuggestion(suggestion)
                            } label: {
                                Text(suggestion.title)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Text("버튼을 누르면 해당 섹션에 문장이 추가돼요")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    func primaryActionsRow(record: SpeechRecord) -> some View {
        HStack(spacing: 10) {
            Button {
                let text = makeFeedbackText()
//                UIPasteboard.general.string = text
                showCopyAlert = true
            } label: {
                Label("내 정리 복사", systemImage: "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button {
                guard !isSaving else { return }
                isSaving = true

                Task { @MainActor in
                    do {
                        try await saveNotes(record: record)
                        Haptics.success()
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        dismiss()
                        router.popToRoot()
                        isSaving = false
                    } catch {
                        Haptics.error()
                        failedToSave = true
                        isSaving = false
                    }
                }
            } label: {
                Label(isSaving ? "저장 중..." : "저장", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 92)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .opacity(isSaving ? 0.7 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
    }

    
}

extension ResultScreen {

    private func presentCoachAssistant(for highlight: SpeechHighlight) {
        guard case .playable = playbackPolicy else { return }
        selectedHighlight = highlight
        isCoachAssistantPresented = true
    }

    private func insertIntoImprovements(_ snippet: String) {
        let s = snippet.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.isEmpty == false else { return }

        if improvementsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            improvementsText = s
        } else {
            improvementsText += "\n\n" + s
        }
    }
    
    private func presentToast(_ title: String) {
        toastTitle = title
        showToast = true
    }
}

struct SpeechTypeSummarySection: View {
    let speechType: SpeechTypeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("말하기 타입 요약")
                .font(.headline)

            Text(speechType.oneLiner)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Text(speechType.paceType.label)
                Text("·")
                Text(speechType.paceStability.label)
            }
            .font(.footnote)
        }
    }
}
