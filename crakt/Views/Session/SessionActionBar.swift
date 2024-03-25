//
//  SessionActionBar.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI
import SwiftData

struct SessionActionBar: View {
    @Bindable var session: Session

    var body: some View {
        HStack(spacing: 20) {
            
            // Fail
            ActionButton(icon: ClimbStatus.fall.iconName, label: ClimbStatus.fall.description, color: .red, action: {
                performAction(.fall)
            })
            
            // Send
            ActionButton(icon: ClimbStatus.send.iconName, label: ClimbStatus.send.description, color: .green, action: {
                performAction(.send)
            })
            
            // Topped
            ActionButton(icon: ClimbStatus.topped.iconName, label: ClimbStatus.topped.description, color: .orange, action: {
                performAction(.topped)
            })
            
            // Flash
            ActionButton(icon: ClimbStatus.flash.iconName, label: ClimbStatus.flash.description, color: .yellow, action: {
                performAction(.flash)
            }, disabled: session.activeRoute?.attempts.count ?? 0 > 0)
        }
    }
    
    private func performAction(_ action: ClimbStatus) {
        if let activeRoute = session.activeRoute {
            activeRoute.addAttempt(status: action)
        }
    }
}

