//
//  HighlightReason.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/15/26.
//

import Foundation

enum HighlightReason {
    static let longPause =
        "말을 이어가기 전 잠시 멈추며 생각을 정리한 흐름이 관찰된 구간"

    static let fastPace =
        "짧은 시간에 많은 정보를 전달하려다 말의 속도가 눈에 띄게 빨라진 흐름"

    static let unclearPronunciation =
        "발음이나 환경 영향으로 음성이 또렷하게 전달되지 않은 흐름"
}
