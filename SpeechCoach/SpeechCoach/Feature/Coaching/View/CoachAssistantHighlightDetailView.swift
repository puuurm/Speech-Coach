//
//  CoachAssistantHighlightDetailView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/21/25.
//

import SwiftUI

struct CoachAssistantHighlightDetailView: View {
    private enum CardStyle {
        case content
        case highlight
        case input
        case copy
    }
    
    private enum Tab: String, CaseIterable {
        case problem = "문제"
        case cause = "원인"
        case script = "개선 스크립트"
        case drill = "연습 과제"
    }
    
    private struct ChipHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
    
    let highlight: SpeechHighlight
    let record: SpeechRecord
    let drillCatalog: [DrillType: CoachDrill]
    let onRequestPlay: (TimeInterval) -> Void
    
    @State private var selectedTab: Tab = .script
    @State private var memo: String = ""
    @State private var toastText: String? = nil
    @State private var expandedDrillIDs: Set<DrillType> = []
    @State private var chipMinHeight: CGFloat = 0
    
    @FocusState private var isMemoFocused: Bool
    

    @EnvironmentObject var homeworkStore: HomeworkStore
    
    private var content: CoachAssistContent {
        let base = CoachAssistContent.content(for: highlight.category)
        return base.isPlaceholder
        ? CoachAssistContent.makeFallback(from: record, highlight: highlight)
        : base
    }
    
    init(
        highlight: SpeechHighlight,
        record: SpeechRecord,
        drillCatalog: [DrillType: CoachDrill],
        onRequestPlay: @escaping (TimeInterval) -> Void
    ) {
        self.highlight = highlight
        self.record = record
        self.drillCatalog = drillCatalog
        self.onRequestPlay = onRequestPlay
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                
                Group {
                    switch selectedTab {
                    case .problem: problemSection
                    case .cause: causeSection
                    case .script: scriptSection
                    case .drill: drillSection
                    }
                }
                
                memoSection
            }
            .padding(16)
        }
        .navigationTitle("강사 보조")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if let toastText {
                toastView(text: toastText)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    var header: some View {
        sectionCard(.highlight) {
            Text(highlight.title)
                .font(.title3).bold()
            Text(highlight.coachDetail(record: record))
            Spacer()
            
            Button {
                onRequestPlay(highlight.start)
            } label: {
                Label("이 구간 재생", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            
        }
    }
    
    var problemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("문제 요약")
            sectionCard(.content) {
                Text(content.problemSummary)
                    .font(.body)
            }
            sectionTitle("청자 영향")

            sectionCard(.content) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(content.listenerImpact, id: \.self) { impact in
                        listenerImpactChip(impact, minHeight: chipMinHeight)
                    }
                }
                .onPreferenceChange(ChipHeightKey.self) { chipMinHeight = $0 }
            }
            sectionTitle("스스로 점검해보기")
            bulletList(content.checkpoints)
        }
    }
    private func listenerImpactChip(_ text: String, minHeight: CGFloat) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color(.systemBackground).opacity(0.5)
                        .preference(key: ChipHeightKey.self, value: proxy.size.height)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
    }
    var causeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("가능한 원인")
            bulletList(content.likelyCauses)
            
            sectionTitle("진단 질문")
            bulletList(content.diagnosticQuestions)
        }
    }
    
    var scriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("코칭 한 문장")
            copyCard(text: content.coachingOneLiner)
            
            sectionTitle("30초 설명 스크립트")
            copyCard(text: content.coachingScript30s)
            
            sectionTitle("대안 표현 예시")
            bulletList(content.alternativePhrases)
            
            sectionTitle("권장 표현")
            bulletList(content.doSay)
            
            sectionTitle("피해야 할 표현")
            bulletList(content.avoidSay)
        }
    }
    
    var drillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("추천 연습")
            let drills = content.drills(using: drillCatalog)
            if drills.isEmpty {
                emptyRecommendedDrillsCard
            } else {
                ForEach(drills, id: \.id) { drill in
                    drillCard(drill)
                }
            }
        }
    }
    
    private var emptyRecommendedDrillsCard: some View {
        sectionCard(.content) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("추천 연습 과제가 아직 없어요")
                        .font(.headline)
                    
                    Text("""
                    분석 결과가 충분하지 않거나, 
                    이번 구간에서는 연습이 필요하지 않을 수 있어요.
                    다른 하이라이트를 선택해보세요.
                    """)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    var memoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("내 연습 메모")
            
            ZStack(alignment: .topLeading) {
                if memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("이 구간을 다시 보며 느낀 점이나, \n다음에 하나만 고치고 싶은 포인트를 적어보세요.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                
                TextEditor(text: $memo)
                    .focused($isMemoFocused)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isMemoFocused ? Color.accentColor.opacity(0.55)
                                     : Color(.separator).opacity(0.35),
                        lineWidth: 1
                    )
            )
            
            HStack {
                Button { } label: {
                    Label("메모 저장", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button { } label: {
                    Label("메모 복사", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .disabled(memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded()))
        let minute = total / 60
        let second = total % 60
        return String(format: "%d:%02d", minute, second)
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .padding(.top, 4)
    }
    
    private func sectionCard(
        _ style: CardStyle = .content,
        @ViewBuilder _ content: () -> some View
    ) -> some View {
        let corner: CGFloat = 16
        let padding: CGFloat = 24
        
        return VStack(alignment: .leading, spacing: 8) { content() }
            .padding(padding)
            .background(background(for: style))
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
    
    private func drillCard(_ drill: CoachDrill) -> some View {
        let isExpanded = expandedDrillIDs.contains(drill.id)

        return sectionCard(.content) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 10) {

                    Text(drill.title)
                        .font(.headline)

                    Text(drill.guide)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            if isExpanded { expandedDrillIDs.remove(drill.id) }
                            else { expandedDrillIDs.insert(drill.id) }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(isExpanded ? "접기" : "연습 방법 보기")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(drill.steps.enumerated()), id: \.offset) { idx, step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(idx + 1).")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 18, alignment: .trailing)
                                    Text(step)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.top, 4)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 1.0, anchor: .top)),
                                removal: .opacity
                            )
                        )
                    }
                }

                if isExpanded {
                    Button {
                        let text = practiceCopyText(title: drill.title, steps: drill.steps)
                        hapticSuccess()
                        copyToPasteboard(text)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(8) // 터치 영역 확보
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("연습 문구 복사")
                    .padding(.top, -14)
                    .padding(.trailing, -14)
                    .transition(.opacity)
                }
            }
        }
    }

    private func practiceCopyText(title: String, steps: [String]) -> String {
        let lines = steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        return """
        [\(title)]

        \(lines)
        """
    }
    
    private func background(for style: CardStyle) -> AnyShapeStyle {
        switch style {
        case .content, .input, .copy:
            return AnyShapeStyle(Color(.secondarySystemBackground))
        case .highlight:
            return AnyShapeStyle(.thinMaterial)
        }
    }
    
    private func bulletList(_ items: [String]) -> some View {
        sectionCard(.content) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").bold()
                        Text(items[index]).font(.body)
                    }
                }
            }
        }
    }
    
    private func chipList(_ items: [String]) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(minHeight: 56, alignment: .topLeading)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func copyCard(text: String) -> some View {
        sectionCard(.copy) {
            ZStack(alignment: .topTrailing) {
                Text(text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    hapticSuccess()
                    copyToPasteboard(text)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(.systemGray))
                            .padding(.trailing, 5)
                    }
                }
                .padding(.top, -15)
                .padding(.trailing, -14)
                .accessibilityLabel("복사")
            }
        }
    }
    
    private func copyToPasteboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
        withAnimation(.spring()){
            toastText = "복사했어요"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut) { toastText = nil }
        }
    }
    
    private func toastView(text: String) -> some View {
        Text(text)
            .font(.caption).bold()
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 6)
    }
    
    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}

//#Preview {
//    CoachAssistantHighlightDetailView()
//}
