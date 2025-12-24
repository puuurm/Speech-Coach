//
//  CoachAssistantHighlightDetailView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/21/25.
//

import SwiftUI

struct CoachAssistantHighlightDetailView: View {
    enum Tab: String, CaseIterable {
        case problem = "문제"
        case cause = "원인"
        case script = "개선 스크립트"
        case drill = "연습 드릴"
    }
    let highlight: SpeechHighlight
    let record: SpeechRecord
    let content: CoachAssistContent
    let onRequestPlay: (TimeInterval) -> Void
    
    @State private var selectedTab: Tab = .script
    @State private var memo: String = ""
    @State private var toastText: String? = nil
    
    init(
        highlight: SpeechHighlight,
        record: SpeechRecord,
        onRequestPlay: @escaping (TimeInterval) -> Void,
    ) {
        self.highlight = highlight
        self.record = record
        let base = CoachAssistContent.content(for: highlight.category)
        self.content = base.isPlaceholder
            ? CoachAssistContent.makeFallback(from: record, highlight: highlight)
            :base
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
        VStack(alignment: .leading, spacing: 12) {
            Text(highlight.title)
                .font(.title3).bold()
            Text("\(format(highlight.start)) ~ \(format(highlight.end))")
            Text(highlight.coachDetail(record: record))
            
            Spacer()
            
            Button {
                onRequestPlay(highlight.start)
            } label: {
                Label("이 구간 재생", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
//            HStack(alignment: .top) {
//                VStack(alignment: .leading, spacing: 6) {
//                    Text(highlight.title)
//                        .font(.title3).bold()
//                    Text("\(format(highlight.start)) ~ \(format(highlight.end))")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                    
//                    Text("심각도 \(highlight.severity)/5 · \(highlight.category.rawValue)")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//
//            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    var problemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("문제 요약")
            card {
                Text(content.problemSummary)
                    .font(.body)
            }
            sectionTitle("청자 영향")
            chipList(content.listenerImpact)
            
            sectionTitle("신규 강사용 체크포인트")
            bulletList(content.checkpoints)
        }
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
        VStack(alignment: .leading) {
            sectionTitle("추천 연습 드릴")
            let drills: [CoachDrill] = content.drills
            ForEach(drills, id: \.id) { (drill: CoachDrill) in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(drill.title).font(.headline)
                        Spacer()
                        Text(drill.durationHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
//                    Text("방법").font(.subheadline).bold()
//                    bulletList(drill.howTo)
//                    
//                    Text("성공 조건").font(.subheadline).bold()
//                    bulletList(drill.successCriteria)
//                    
//                    Text("흔한 실수").font(.subheadline).bold()
//                    bulletList(drill.commonMistakes)
                    
                    HStack {
                        Button {
                            
                        } label: {
                            Label("오늘 숙제로 저장", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button {
//                            copyToPasteboard("""
//                            [연습] \(drill.title) (\(drill.durationHint))
//                            - 방법: \(drill.howTo.joined(separator: " / "))
//                            - 성공 조건: \(drill.successCriteria.joined(separator: " / "))
//                            """)
                        } label: {
                            Label("공유 텍스트 복사", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    var memoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("강사 메모")
            TextEditor(text: $memo)
                .frame(minHeight: 110)
                .padding(10)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            HStack {
                Button {
                    
                } label: {
                    Label("메모 저장", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button {
                    
                } label: {
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
    
    private func card(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) { content() }
            .padding(14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").bold()
                    Text(items[index])
                        .font(.body)
                }
            }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func chipList(_ items: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)],
                  alignment: .leading,
                  spacing: 8
        ) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.secondary.opacity(0.10))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func copyCard(text: String) -> some View {
        card {
            Text(text).font(.body)
            HStack {
                Spacer()
                Button {
                    copyToPasteboard(text)
                } label: {
                    Label("복사", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
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
}

//#Preview {
//    CoachAssistantHighlightDetailView()
//}
