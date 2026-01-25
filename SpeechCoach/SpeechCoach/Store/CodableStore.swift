//
//  CodableStore.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/27/25.
//

import Foundation

enum CodableStore {
    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }
    
    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
