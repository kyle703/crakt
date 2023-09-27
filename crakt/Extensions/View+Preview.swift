//
//  View+Preview.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct StatefulPreviewContainer<Value, Content: View>: View {
  @State var value: Value
  var content: (Binding<Value>) -> Content
  
  var body: some View {
    content($value)
  }
  
  init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
    self._value = State(wrappedValue: value)
    self.content = content
  }
}
