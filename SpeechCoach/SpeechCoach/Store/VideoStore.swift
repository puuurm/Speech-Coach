//
//  VideoStore.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/24/25.
//

import Foundation

enum VideoStoreError: Error {
    case sourceNotFound
    case copyFailed
}

final class VideoStore {
    static let shared = VideoStore()
    private init() {}
    
    private var baseDir: URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? .documentsDirectory
        let dir = doc.appendingPathComponent("Videos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    func destinationURL(recordID: UUID, ext: String = "mov") -> URL {
        baseDir.appendingPathComponent(recordID.uuidString).appendingPathExtension(ext)
    }
    
    func importToSandbox(sourceURL: URL, recordID: UUID) throws -> String {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw VideoStoreError.sourceNotFound
        }
        let ext = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let destinationURL = self.destinationURL(recordID: recordID, ext: ext)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw VideoStoreError.copyFailed
        }
        let document = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? .documentsDirectory
        let relativePath = destinationURL.path.replacingOccurrences(of: document.path + "/", with: "")
        return relativePath
    }
    
    func resolve(relativePath: String) -> URL {
        let document = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? .documentsDirectory
        return document.appendingPathComponent(relativePath)
    }
    
    func exist(relativePath: String) -> Bool {
        FileManager.default.fileExists(atPath: resolve(relativePath: relativePath).path)
    }
}
