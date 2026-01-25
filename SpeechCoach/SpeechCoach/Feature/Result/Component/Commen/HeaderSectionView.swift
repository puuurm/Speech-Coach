//
//  HeaderSectionView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/15/26.
//

import SwiftUI

struct HeaderSectionView: View {
    let record: SpeechRecord
    let onChangeStudentName: (String) -> Void
    
    @State private var isEditingName: Bool = false
    @State private var nameDraft: String = ""
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cleanTitle(from: record.title))
                .font(.title3.weight(.semibold))
            
            HStack(spacing: 8) {
                Text(record.createdAt.headerDisplayString)
                Text("·")
                Text(durationString(record.duration))
                
                studentNameView
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top,  10)
        .padding(.bottom, 6)
    }
    
    @ViewBuilder
    private var studentNameView: some View {
        if isEditingName {
            TextField("학생 이름", text: $nameDraft)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit { commit() }
                .onAppear {
                    nameDraft = record.studentName ?? "--"
                    isNameFocused = true
                }
                .onChange(of: isNameFocused) { _, focused in
                    if !focused { commit() }
                }
        } else {
            Button {
                isEditingName = true
            } label: {
                HStack(spacing: 4) {
                    Text("·")
                    
                    if let name = record.studentName, name.isEmpty == false {
                        Text(name)
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(" 학생 이름 추가")
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private func commit() {
        isEditingName = false
        onChangeStudentName(nameDraft)
    }
}
