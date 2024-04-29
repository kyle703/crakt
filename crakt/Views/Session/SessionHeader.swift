//
//  SessionHeader.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct SessionHeader: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    var session: Session
    @ObservedObject var stopwatch: Stopwatch
    
    @State private var isPaused = false
    @State private var showExitAlert = false
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text(stopwatch.elapsedDisplay)
                        .font(.system(size: 32, weight: .thin, design: .monospaced))
                        .frame(minWidth: 100, maxWidth: .infinity)
                    Text("Total Session Time")
                        .font(.caption)
                    
                    // Stop and Pause/Play buttons
                    HStack {
                        
                        Button(action: {
                            if isPaused {
                                stopwatch.start()
                            } else {
                                stopwatch.pause()
                            }
                            isPaused.toggle()
                        }) {
                            Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            self.showExitAlert = true
                            stopwatch.pause()
                            isPaused.toggle()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.red)
                        }.alert(isPresented: $showExitAlert) {
                            Alert(
                                title: Text("End Session"),
                                message: Text("Are you sure you want to end your sesh?"),
                                primaryButton: .default(Text("Yes"), action: {
                                    session.completeSession(context: modelContext, elapsedTime: stopwatch.elapsed())
                                    self.presentationMode.wrappedValue.dismiss()
                                }),
                                secondaryButton: .cancel(Text("Keep crushing"), action : {
                                    stopwatch.start()
                                    isPaused.toggle()
                                })
                            )
                        }
                    }
                }
                
                Divider()
                
                VStack {
                    VStack {
                        Text("\(session.tops)")
                            .font(.largeTitle)
                            .fontWeight(.thin)
                        Text("Tops")
                            .font(.caption)
                    }
                    
                    Divider()
                    
                    VStack {
                        Text("\(session.tries)")
                            .font(.largeTitle)
                            .fontWeight(.thin)
                        Text("Tries")
                            .font(.system(size: 12))
                    }
                }
            }
        }
    }
}
