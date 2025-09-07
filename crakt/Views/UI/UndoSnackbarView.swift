//
//  UndoSnackbarView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI

struct UndoSnackbarView: View {
    let message: String
    let actionTitle: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    @State private var isVisible = true
    @State private var timer: Timer?

    var body: some View {
        VStack {
            Spacer()

            if isVisible {
                HStack(spacing: 16) {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Spacer()

                    Button(action: {
                        onUndo()
                        dismiss()
                    }) {
                        Text(actionTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: isVisible)
            }
        }
        .onAppear {
            // Auto-dismiss after 5 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                dismiss()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func dismiss() {
        withAnimation {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    UndoSnackbarPreview()
}

struct UndoSnackbarPreview: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .edgesIgnoringSafeArea(.all)

            UndoSnackbarView(
                message: "Send logged — v2 (Attempt 3)",
                actionTitle: "Undo"
            ) {
                print("Undo tapped")
            } onDismiss: {
                print("Snackbar dismissed")
            }
        }
    }
}
