//
//  ResultAnalyzing.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public protocol ResultAnalyzing {
    func analyze(_ input: ResultAnalysisInput) -> ResultAnalysisOutput
}
