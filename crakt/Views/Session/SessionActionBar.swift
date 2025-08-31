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
    var actionButton: AnyView?

    @State private var showToppedButton: Bool = false
    @State private var flashButtonDisabled: Bool = false

    var body: some View {
        HStack(spacing: 20) {
            
            // Fail
            ActionButton(icon: ClimbStatus.fall.iconName, 
                         label: ClimbStatus.fall.description,
                         color: ClimbStatus.fall.color, action: {
                performAction(.fall)
            })
            
            // Send
            ActionButton(icon: ClimbStatus.send.iconName, 
                         label: ClimbStatus.send.description,
                         color: ClimbStatus.send.color, action: {
                performAction(.send)
            })
            
                        // Topped -- only for ropes
            if showToppedButton {
            //                ActionButton(icon: ClimbStatus.topped.iconName,
            //                             label: ClimbStatus.topped.description,
            //                             color: ClimbStatus.topped.color, action: {
            //                    performAction(.highpoint)
            //                })
            }

            // Flash
            ActionButton(icon: ClimbStatus.flash.iconName,
                         label: ClimbStatus.flash.description,
                         color: ClimbStatus.flash.color, action: {
                performAction(.flash)
            }, disabled: flashButtonDisabled)
            
            Divider()
            
            if let actionButton {
                actionButton
            }
        }.frame(height: 50)
        .onAppear {
            updateButtonStates()
        }
        .onChange(of: session.activeRoute?.gradeSystem) { _, _ in
            updateButtonStates()
        }
        .onChange(of: session.activeRoute?.attempts.count) { _, _ in
            updateButtonStates()
        }
        .onChange(of: session.activeRoute?.id) { _, _ in
            updateButtonStates()
        }
    }

    private func updateButtonStates() {
        showToppedButton = session.activeRoute?.gradeSystem.climbType != .boulder
        flashButtonDisabled = (session.activeRoute?.attempts.count ?? 0) > 0
    }
    
    private func performAction(_ action: ClimbStatus) {
        if let activeRoute = session.activeRoute {
            activeRoute.addAttempt(status: action)
        }
    }
}

