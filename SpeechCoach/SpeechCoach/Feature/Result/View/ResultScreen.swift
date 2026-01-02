//
//  ResultScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI
import AVKit

extension ResultScreen {
    enum ResultTab: String, CaseIterable, Identifiable {
        case feedback = "피드백"
        case analysis = "분석"
        var id: String { rawValue }
    }
}

struct ResultScreen: View {
    let record: SpeechRecord
    let playbackPolicy: HighlightPlaybackPolicy
    let onRequestPlay: (TimeInterval) -> Void
    let scriptMatches: [ScriptMatchSegment] = []
    
    @State private var selectedAnchor: ResultSectionAnchor = .summary
    
    @EnvironmentObject private var recordStore: SpeechRecordStore
    @EnvironmentObject private var pc: PlayerController
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.dismiss) private var dismiss
        
    @State private var editedTranscript: String = ""
    
    @State private var introText: String
    @State private var strenthsText: String
    @State private var improvementsText: String
    @State private var nextStepsText: String
    
    @State private var showCopyAlert = false
    @State private var previousRecord: SpeechRecord?

    @State private var qualitative: QualitativeMetrics
    @State private var showSaveAlert = false
    
    @State private var suggestions: [TemplateSuggestion] = []
    
    @State private var selectedTab: ResultTab = .feedback
    @State private var showAllTranscript: Bool = false
    @State private var showAdvanced: Bool = false
    @State private var showQualitative: Bool = false
    
    @State private var isCoachAssistantPresented: Bool = false

    @State private var selectedHighlight: SpeechHighlight?
    @State private var showPlayer: Bool = false
    @State private var pendingSeek: TimeInterval = 0
    
    @State private var speechType: SpeechTypeSummary? = nil
    
    struct PlayerRoute: Identifiable, Equatable {
        let id = UUID()
        let recordID: UUID
        let startTime: TimeInterval?
        let autoplay: Bool
    }

    @State private var playerRoute: PlayerRoute?

    init(
        record: SpeechRecord,
        playbackPolicy: HighlightPlaybackPolicy,
        onRequestPlay: @escaping (TimeInterval) -> Void
    ) {
        self.record = record
        _introText = State(initialValue: record.note?.intro ?? "")
        _strenthsText = State(initialValue: record.note?.strengths ?? "")
        _improvementsText = State(initialValue: record.note?.improvements ?? "")
        _nextStepsText = State(initialValue: record.note?.nextStep ?? "")
        let baseQualitative = record.insight?.qualitative ?? QualitativeRecommender.recommend(for: record)
        _qualitative = State(initialValue: baseQualitative)
//        self.player = player
        self.onRequestPlay = onRequestPlay
        self.playbackPolicy = playbackPolicy
    }
    
    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                VStack(alignment: .leading, spacing: 16) {
//
//                    SummarySection(record: record)
//                        .id(ResultAnchor.summary)
//                    
//                    ScriptMatchSection(segments: scriptMatches)
//                        .id(ResultAnchor.scriptMatch)
//                    
//                    HighlightsSection(record: record)
//                        .id(ResultAnchor.highlights)
//                    
//                    noteSections
//
//                }
//                .padding(.horizontal, 16)
//                .padding(.bottom, 24)
//            }
//        }
        VStack(spacing: 0) {
            headerSection
            
            Picker("", selection: $selectedTab) {
                ForEach(ResultTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch selectedTab {
                    case .feedback:
                        feedbackTab
                    case .analysis:
                        analysisTab
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .sheet(item: $selectedHighlight) { h in
            CoachAssistantHighlightDetailView(
                highlight: h,
                record: record,
                onRequestPlay: { sec in
                    onRequestPlay(sec)
                    selectedHighlight = nil
                    pendingSeek = sec
                    playerRoute = .init(recordID: record.id, startTime: sec, autoplay: true)
                    DispatchQueue.main.async {
                        showPlayer = true
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlayer, onDismiss: {
            playerRoute = nil
        }) {
            NavigationStack {
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
                    // fallback UI
                    VideoReconnectView(record: record)
                }
            }
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
            suggestions = QualitativeRecommender.makeSuggestions(
                transcript: record.transcript,
                duration: record.duration,
                fillerCount: record.fillerCount,
                segments: record.insight?.transcriptSegments
            )
            speechType = SpeechTypeSummarizer
                .summarize(
                    duration: record.duration,
                    wordsPerMinute: record.wordsPerMinute,
                    segments: record.insight?.transcriptSegments ?? []
                )
        }
    }
    
//    var speakingTypeSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack(spacing: 8) {
//                Text("말하기 타입 요약")
//                    .font(.headline)
//                
//                Text("1:1 핵심")
//                    .font(.caption2.weight(.semibold))
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(Capsule().fill(Color(.systemGray6)))
//            }
//
//            if let speechType {
//                Text(speechType.oneLiner)
//                    .font(.subheadline.weight(.semibold))
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(12)
//                    .background(
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color(.secondarySystemBackground))
//                    )
//                
//                FlowChips {
//                    chip(title: "속도", value: speechType.paceType.displayName)
//                    chip(title: "속도 안정", value: speechType.paceStability.displayName)
//                    chip(title: "쉬는 습관", value: speechType.pauseType.displayName)
//                    chip(title: "구조", value: speechType.structureType.displayName)
//                    chip(title: "확신 톤", value: speechType.confidenceType.displayName)
//                }
//                
//                if speechType.highlights.isEmpty == false {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("하이라이트")
//                            .font(.subheadline.weight(.semibold))
//                            .foregroundColor(.secondary)
//                        
//                        ForEach(speechType.highlights) { item in
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(item.title)
//                                    .font(.subheadline.weight(.semibold))
//                                if item.detail.isEmpty == false {
//                                    Text(item.detail)
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                }
//                            }
//                            .padding(12)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .background(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .fill(Color(.secondarySystemBackground))
//                            )
//                        }
//                    }
//                } else {
//                    Text("타입 요약을 만드는 중이에요.")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
//    }
    
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
    
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("추천 템플릿")
                .font(.subheadline.weight(.semibold))
            
            if suggestions.isEmpty {
                Text("추천을 생성할 데이터가 아직 부족해요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(suggestions) { suggestion in
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
    
    private func applySuggestion(_ suggestion: TemplateSuggestion) {
        let sentence = "• \(suggestion.body)\n"
        switch suggestion.category {
        case .strengths:
            strenthsText = (strenthsText + (strenthsText.isEmpty ? "" : "\n") + sentence).trimmingCharacters(in: .whitespacesAndNewlines)
        case .improvements:
            improvementsText = (improvementsText + (improvementsText.isEmpty ? "" : "\n") + sentence).trimmingCharacters(in: .whitespacesAndNewlines)
        case .nextStep:
            nextStepsText = (nextStepsText + (nextStepsText.isEmpty ? "" : "\n") + sentence).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cleanTitle(from: record.title))
                .font(.title3.weight(.semibold))
            
            HStack(spacing: 8) {
                Text(formattedDate(record.createdAt))
                Text("·")
                Text(durationString(record.duration))
                if record.studentName.isEmpty == false {
                    Text("·")
                    Text(record.studentName)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
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
    
    private var qualitativeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("정성 지표 (1:1용)")
                .font(.headline)
            qualitativeRow(
                title: "전달력 / 발화 안정감",
                value: $qualitative.delivery
            )
            
            qualitativeRow(
                title: "명료함 / 이해도",
                value: $qualitative.clarity
            )
            
            qualitativeRow(
                title: "자신감 / 에너지",
                value: $qualitative.confidence
            )
            
            qualitativeRow(
                title: "답변 구조 / 논리",
                value: $qualitative.structure
            )
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
    
//    private var summarySection: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            Text(record.title)
//                .font(.headline)
//            HStack(spacing: 12) {
//                Label(durationString(record.duration), systemImage: "clock")
//                Text(formattedDate(record.createdAt))
//            }
//            .font(.caption)
//            .foregroundColor(.secondary)
//        }
//    }
    
    private var feedbackActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                saveNotes()
                dismiss()
                router.popToRoot()
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
        
        recordStore
            .updateQualitative(
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
    
    private func qualitativeRow(title: String, value: Binding<EmojiRating>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.medium))
            
            HStack(spacing: 10) {
                ForEach(EmojiRating.allCases, id: \.self) { rating in
                    let isSelected = value.wrappedValue == rating
                    
                    Text(emoji(for: rating))
                        .font(.title2)
                        .padding(6)
                        .background(
                            isSelected
                            ? Color.accentColor.opacity(0.2)
                            : Color.clear
                        )
                        .cornerRadius(8)
                        .onTapGesture {
                            value.wrappedValue = rating
                        }
                }
            }
        }
    }

    private func emoji(for rating: EmojiRating) -> String {
        switch rating {
        case .veryLow:   return "😣"
        case .low:       return "😕"
        case .neutral:   return "😐"
        case .high:      return "🙂"
        case .veryHigh:  return "😄"
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
    
    private func dismissCoachAssistant() {
        isCoachAssistantPresented = false
        selectedHighlight = nil
    }
}

extension ResultScreen {
    
    var noteSectionsRedesigned: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("피드백 메모")
                .font(.headline)
            
            memoEditorRow(
                title: "인사 / 전체 인상",
                buttonTitle: "인사 템플릿",
                placeholder: "전체적인 인상과 수고 메시지를 적어주세요.",
                text: $introText
            ) {
                appendTemplate(&introText, template: """
                \(record.studentName.isEmpty ? "학생님" : record.studentName) 안녕하세요. 
                보내주신 과제 영상에 대한 피드백 남겨드립니다.
                첫 촬영이라 익숙하지 않으셨을 텐데 차분히 연습해주셔서 감사합니다.
                """)
            }
            
            memoEditorRow(
                title: "잘된 점 / 강점",
                buttonTitle: "강점 템플릿",
                placeholder: "좋았던 점을 bullet로 정리해보세요.",
                text: $strenthsText
            ) {
                appendTemplate(&strenthsText, template: """
                전반적으로 차분하게 전달해주셔서 듣기 편했습니다.
                특히 \(wpmStrengthHighlight) 부분이 강점으로 느껴집니다.
                """)
            }
            
            memoEditorRow(
                title: "개선할 점",
                buttonTitle: "개선 템플릿",
                placeholder: "개선 포인트를 구체적으로 적어주세요.",
                text: $improvementsText
            ) {
                appendTemplate(&improvementsText, template: wpmImprovementTemplate)
            }
            
            memoEditorRow(
                title: "다음 연습 / 수업 방향",
                buttonTitle: "다음 연습 템플릿",
                placeholder: "다음 과제/수업에서의 목표를 적어주세요.",
                text: $nextStepsText
            ) {
                appendTemplate(&nextStepsText, template: """
                다음 과제에서는 핵심 문장마다 한 박자 멈추는 연습을 해보세요.
                다음 수업에서 이 부분을 원포인트로 같이 점검해보겠습니다.
                """)
            }
        }
    }
    
    var qualitativeSectionCompact: some View {
        VStack(alignment: .leading, spacing: 12) {
            qualitativeRow(
                title: "전달력 / 발화 안정감",
                value: $qualitative.delivery
            )
            
            qualitativeRow(
                title: "명료함 / 이해도",
                value: $qualitative.clarity
            )
            
            qualitativeRow(
                title: "자신감 / 에너지",
                value: $qualitative.confidence
            )
            
            qualitativeRow(
                title: "답변 구조 / 논리",
                value: $qualitative.structure
            )
            
            Text("※ 정성 지표는 '메모를 더 빨리/일관되게 쓰기 위한 체크' 용도로만 사용해요.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 6)
    }
    
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
    var feedbackTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            suggestionSection
            noteSectionsRedesigned
            
            primaryActionsRow
//            saveOnlyButton
        }
    }
    
    var primaryActionsRow: some View {
        HStack(spacing: 10) {
            Button {
                let text = makeFeedbackText()
                UIPasteboard.general.string = text
                showCopyAlert = true
            } label: {
                Label("피드백 복사", systemImage: "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button {
                saveNotes()
                dismiss()
                router.popToRoot()
            } label: {
                Label("저장", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 92)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    var saveOnlyButton: some View {
        Button {
            saveNotes()
            dismiss()
            router.popToRoot()
        } label: {
            Text("메모 저장하고 홈으로")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }
}

extension ResultScreen {
    var analysisTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            metricsSection
            speakingTypeSection
            
            if previousRecord != nil {
                progressSection
            }
            
            if !record.fillerWords.isEmpty {
                fillerDetailSection
            }
            
            transcriptSectionRedesigned
            
            DisclosureGroup(
                isExpanded: $showAdvanced,
                content: {
                    Text("※ 자동 인식 초안이라 부정확할 수 있어요. 중요한 문장은 영상과 함께 확인해주세요.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                },
                label: {
                    HStack {
                        Text("안내")
                            .font(.headline)
                        Spacer()
                        Text(showAdvanced ? "접기" : "펼치기")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            )
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
    }
}

extension ResultScreen {
    var transcriptSectionRedesigned: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("전체 스크립트")
                    .font(.headline)
                Spacer()
                Button(showAllTranscript ? "접기" : "펼치기") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showAllTranscript.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
            }
            
            Text("자동 인식 초안이에요. 중요한 문장은 영상과 함께 확인해 주세요.")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            let text = record.transcript.isEmpty ? "인식된 텍스트가 없어요." : record.transcript
            
            if showAllTranscript {
                ScrollView {
                    Text(text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(minHeight: 180)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            } else {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(5)
                    .truncationMode(.tail)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }
        }
    }
}

extension ResultScreen {

    var speakingTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("말하기 타입 요약")
                    .font(.headline)

                Spacer()

                Button("요약 복사") {
                    guard let speechType else { return }
                    UIPasteboard.general.string = speechType.clipboardText(for: record)
                    showCopyAlert = true
                }
                .font(.caption.weight(.semibold))
            }

            if let speechType {
                // one-liner
                Text(speechType.oneLiner)
                    .font(.subheadline.weight(.semibold))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )

                // “메모 삽입” (최소: 개선할 점에 붙이기 / or intro에 붙이기)
                Button {
                    let snippet = speechType.memoSnippet(for: record)
                    insertIntoImprovements(snippet)
                } label: {
                    Label("개선 메모에 요약 삽입", systemImage: "plus.circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                
                // inside ResultScreen

                // highlights
                if speechType.highlights.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("체크할 구간")
                            .font(.subheadline.weight(.semibold))
                        ForEach(speechType.highlights.prefix(3)) { h in
                            SpeechHighlightRow(
                                item: h,
                                duration: record.duration,
                                playbackPolicy: playbackPolicy,
                                onPlay: {
                                    presentCoachAssistant(for: h)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedHighlight = h
                            }
                        }
                    }
                }
            } else {
                Text("요약을 만들 데이터가 아직 부족해요.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    private func presentCoachAssistant(for highlight: SpeechHighlight) {
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
}

extension ResultScreen {
    var anchorItems: [ResultSectionAnchor] {
        var items: [ResultSectionAnchor] = [.summary]
        if hasPaceHighlights { items.append(.highlightPace) }
        if hasToneHighlights { items.append(.highlightTone) }
        if hasFaceHighlights { items.append(.highlightFace) }
        if hasScriptHighlights { items.append(.highlightScript) }
        if !scriptMatches.isEmpty { items.append(.scriptCompare) }
        return items
    }
    
    private var hasPaceHighlights: Bool {
        guard let highlights = speechType?.highlights else { return false }
        return highlights.contains { [.paceFast, .paceSlow, .longPause].contains($0.category) }
    }
    
    private var hasToneHighlights: Bool {
        guard let highlights = speechType?.highlights else { return false }
        return highlights.contains { [.monotone, .weakEmphasis].contains($0.category) }
    }
    
    private var hasFaceHighlights: Bool {
        guard let highlights = speechType?.highlights else { return false }
        return highlights.contains { [.facialTension, .lowSmile].contains($0.category) }
    }
    
    private var hasScriptHighlights: Bool {
        guard let highlights = speechType?.highlights else { return false }
        return highlights.contains { [.scriptOverRead, .scriptDeviation, .keyMessageLoss].contains($0.category) }
    }
    
    private var scriptCompareSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("대본/발화 비교")
                    .font(.headline)
                Spacer()
            }
            VStack(spacing: 10) {
                ForEach(scriptMatches) { segment in
                    ScriptMatchRow(segment: segment)
                }
            }
        }
        .padding(.top, 6)
    }
    
}
