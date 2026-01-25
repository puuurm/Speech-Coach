//
//  VideoReconnectView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/24/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct VideoReconnectView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporterPresented: Bool = false
    @State private var errorText: String?
    
    let record: SpeechRecord
    
    @EnvironmentObject var recordStore: SpeechRecordStore
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                    .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("원본 영상 파일을 찾을 수 없어요")
                    .font(.headline)
                
                Text("영상이 기기 정리/권한/임시 경로 문제로 사라졌을 수 있어요.\n같은 영상을 다시 선택해 연결해 주세요.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                
                if let errorText {
                    Text(errorText).foregroundStyle(.red).font(.footnote)
                }
                
                Button("영상 다시 선택") {
                    isImporterPresented = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("닫기") { dismiss() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.movie, .mpeg4Movie],
            allowsMultipleSelection: false
        ) { result in
            do {
                let url = try result.get().first!
                try reconnect(with: url)
                dismiss()
            } catch {
                self.errorText = "가져오기 실패: \(error.localizedDescription)"
            }
        }
    }
    
    func reconnect(with sourceURL: URL) throws {
        let relative = try VideoStore.shared.importToSandbox(sourceURL: sourceURL, recordID: record.id)
        recordStore.updateVideoRelativePath(recordID: record.id, relativePath: relative)
    }
}

