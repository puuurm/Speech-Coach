//
//  PickedVideo.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/10/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PickedVideo: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exporting in
            return .init(exporting.url)
        } importing: { received in
            let fileURL = received.file
            let tempURL = FileManager.default
                .temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).mov")
            
            try FileManager.default.moveItem(at: fileURL, to: tempURL)
            
            return PickedVideo(url: tempURL)
        }
    }
}
