//
//  Date+Format.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/15/26.
//

import Foundation

extension Date {
    private static let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f
    }()

    var headerDisplayString: String {
        Self.headerFormatter.string(from: self)
    }
}
