//
//  RouteLogRowItem.swift
//  crakt
//
//  Created by Kyle Thompson on 5/12/24.
//

import SwiftUI

struct AttemptsList: View {
    var attempts: [RouteAttempt]
    
    var body: some View {
        VStack {
            ForEach(attempts, id: \.id) { attempt in
                HStack {
                    Image(systemName: attempt.status.iconName)
                        .foregroundColor(attempt.status.color)
                    
                    Text(attempt.status.description)
                        .font(.caption)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Text(attempt.date.toString())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
            }
        }
    }
}
