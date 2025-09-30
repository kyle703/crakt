//
//  RouteStylePicker.swift
//  crakt
//
//  Created by Kyle Thompson on 1/27/25.
//

import SwiftUI
import SwiftData

struct RouteStylePicker: View {
    @Binding var selectedStyles: [RouteStyle]
    let isMultiSelect: Bool
    let onSelectionChanged: (() -> Void)?

    @State private var showStyleSelector = false

    private var selectedStylesText: String {
        if selectedStyles.isEmpty {
            return "Select styles..."
        } else if selectedStyles.count == 1 {
            return selectedStyles.first!.description
        } else {
            return "\(selectedStyles.count) styles selected"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Route Styles")
                .font(.headline)
                .foregroundColor(.primary)

            Button(action: {
                showStyleSelector = true
            }) {
                HStack {
                    Text(selectedStylesText)
                        .font(.body)
                        .foregroundColor(selectedStyles.isEmpty ? .secondary : .primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showStyleSelector) {
            StyleSelectorView(
                selectedStyles: $selectedStyles,
                isMultiSelect: isMultiSelect,
                onSelectionChanged: onSelectionChanged
            )
        }
    }
}

struct StyleSelectorView: View {
    @Binding var selectedStyles: [RouteStyle]
    let isMultiSelect: Bool
    let onSelectionChanged: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Select Route Styles")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)

                    Text("Choose the climbing styles that best describe this route")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(RouteStyle.allCases, id: \.self) { style in
                            StyleButton(
                                style: style,
                                isSelected: selectedStyles.contains(style),
                                action: {
                                    toggleStyle(style)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSelectionChanged?()
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleStyle(_ style: RouteStyle) {
        if isMultiSelect {
            if selectedStyles.contains(style) {
                selectedStyles.removeAll { $0 == style }
            } else {
                selectedStyles.append(style)
            }
        } else {
            // Single select mode
            selectedStyles = [style]
        }
    }
}

struct StyleButton: View {
    let style: RouteStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: style.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? style.color : .gray)

                Text(style.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? style.color : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? style.color.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? style.color : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RouteStylePickerPreview()
}

struct RouteStylePickerPreview: View {
    @State private var styles: [RouteStyle] = []

    var body: some View {
        RouteStylePicker(
            selectedStyles: $styles,
            isMultiSelect: true,
            onSelectionChanged: nil
        )
    }
}