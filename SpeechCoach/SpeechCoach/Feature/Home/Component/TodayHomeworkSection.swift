//
//  TodayHomeworkSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/21/26.
//

import SwiftUI

struct TodayHomeworkSection: View {
    
    let homeworks: [DailyHomework]
    let drillCatalog: [DrillType: CoachDrill]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 숙제")
                .font(.headline)
            
            ForEach(homeworks) { homework in
                if let drill = drillCatalog[homework.drillType] {
                    TodayHomeworkRow(drill: drill)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
