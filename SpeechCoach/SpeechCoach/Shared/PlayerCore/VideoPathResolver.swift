//
//  VideoPathResolver.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/26/25.
//

import Foundation

enum VideoPathResolver {
    static func resolve(relativePath: String?) -> URL {
        guard let relativePath else {
            return URL(fileURLWithPath: "")
        }

        let baseURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        return baseURL.appendingPathComponent(relativePath)
    }
}
