//
//  ResultAnalyzing.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/7/26.
//

import Foundation

protocol ResultAnalyzing {
    func analyze(_ input: ResultAnalysisInput) -> ResultAnalysisOutput
}
