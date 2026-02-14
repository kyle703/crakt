//
//  ScrollingSectionView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI

struct ScrollingSelectionView<Content: View>: View {
    let items: [Content]
    @Binding var selectedIdx: Int
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollView in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<items.count, id: \.self) { idx in
                            items[idx]
                                .scaleEffect(idx == selectedIdx ? 1 : 0.8)
                                .opacity(idx == selectedIdx ? 1 : 0.6)
                                .shadow(color: idx == selectedIdx ? Color.black.opacity(0.4) : Color.clear, radius: 5, x: 0, y: 5)
                                .id(idx)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedIdx = idx
                                        scrollView.scrollTo(selectedIdx, anchor: .center)
                                    }
                                }
                        }
                    }.padding()
                }.onAppear {
                    scrollView.scrollTo(selectedIdx, anchor: .center)
                }
            }
        }
    }
}
