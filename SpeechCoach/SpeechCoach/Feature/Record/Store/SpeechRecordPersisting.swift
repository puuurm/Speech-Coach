//
//  SpeechRecordPersisting.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 3/2/26.
//

import Foundation

protocol SpeechRecordPersisting: AnyObject {
    func upsertBundle(record: SpeechRecord, metrics: SpeechMetrics?)
}
