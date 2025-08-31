//
//  BaseTileView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/12/25.
//
import SwiftUI

struct BaseTileView<Content: View>: View {
    let content: Content
    let tileSize: CGFloat = 120

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack {
            content
        }
        .frame(width: tileSize, height: tileSize)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.shadow(.drop(radius: 2))))
    }
}
