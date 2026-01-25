//
//  ScriptMatchRow.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/31/25.
//

import SwiftUI

//struct ScriptMatchRow: View {
//    let segment: ScriptMatchSegment
//    @State private var expanded: Bool = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            header
//            if expanded {
//                compareBlock
//            } else {
//                previewBlock
//            }
//            keywordBlock
//            if (segment.scriptText?.count ?? 0) + (segment.spokenText?.count ?? 0) > 140 {
//                Button {
//                    withAnimation(.snappy) { expanded.toggle() }
//                } label: {
//                    Text(expanded ? "접기" : "자세히")
//                        .font(.caption.weight(.semibold))
//                }
//                .buttonStyle(.plain)
//                .foregroundStyle(.secondary)
//            }
//        }
//        .padding(12)
//        .background(.ultraThinMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
//    }
//    
//    private var header: some View {
//        HStack {
//            Text("\(segment.start.toClock())-\(segment.end.toClock())")
//                .font(.caption)
//                .foregroundStyle(.secondary)
//            
//            Spacer()
//            
//            MatchBadge(type: segment.matchType, similarity: segment.similarity)
//        }
//    }
//    
//    private var previewBlock: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            if let script = segment.scriptText, !script.isEmpty {
//                Text("대본: \(script)")
//                    .font(.footnote)
//                    .lineLimit(2)
//            }
//            if let spoken = segment.spokenText, !spoken.isEmpty {
//                Text("발화: \(spoken)")
//                    .font(.footnote)
//                    .foregroundStyle(.secondary)
//                    .lineLimit(2)
//            }
//        }
//    }
//    
//    private var compareBlock: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            if let script = segment.scriptText {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("대본")
//                        .font(.caption.weight(.semibold))
//                        .foregroundStyle(.secondary)
//                    Text(script)
//                        .font(.footnote)
//                }
//            }
//            if let spoken = segment.spokenText {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("발화")
//                        .font(.caption.weight(.semibold))
//                        .foregroundStyle(.secondary)
//                    Text(spoken)
//                        .font(.footnote)
//                        .foregroundStyle(.secondary)
//                }
//            }
//        }
//    }
//    
//    private var keywordBlock: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            if !segment.keyTerms.isEmpty {
//                FlowTags(title: "핵심단어", tags: segment.keyTerms)
//            }
//            if segment.missingKeyTerms.isEmpty {
//                FlowTags(title: "누락", tags: segment.missingKeyTerms)
//            }
//        }
//    }
//    
//    
//    
//    
//}
