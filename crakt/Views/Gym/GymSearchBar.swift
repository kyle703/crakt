//
//  GymSearchBar.swift
//  crakt
//
//  Search bar for gym finder
//

import SwiftUI

struct GymSearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search gyms, city, or state", text: $text)
                    .focused($isFocused)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            
            if isSearching {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                    isSearching = false
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.default, value: isSearching)
        .onChange(of: isFocused) { _, newValue in
            withAnimation {
                isSearching = newValue
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        GymSearchBar(
            text: .constant(""),
            isSearching: .constant(false)
        )
        .padding()
        
        GymSearchBar(
            text: .constant("Boulder"),
            isSearching: .constant(true)
        )
        .padding()
    }
}

