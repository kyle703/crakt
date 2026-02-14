//
//  CircuitGradePicker.swift
//  crakt
//
//  A specialized picker for circuit grades that displays color swatches
//

import SwiftUI
import SwiftData

/// Displays circuit colors as selectable swatches with grade range info
struct CircuitGradePicker: View {
    let circuit: CustomCircuitGrade
    @Binding var selectedGrade: String?
    
    @State private var selectedIndex: Int = -1
    
    init(circuit: CustomCircuitGrade, selectedGrade: Binding<String?>) {
        self.circuit = circuit
        self._selectedGrade = selectedGrade
        
        // Find initial selection
        if let grade = selectedGrade.wrappedValue,
           let idx = circuit.orderedMappings.firstIndex(where: { $0.id.uuidString == grade }) {
            _selectedIndex = State(initialValue: idx)
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(circuit.orderedMappings.enumerated()), id: \.element.id) { index, mapping in
                    CircuitColorSwatch(
                        mapping: mapping,
                        isSelected: selectedIndex == index,
                        showLabel: true
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedIndex = index
                            selectedGrade = mapping.id.uuidString
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .onChange(of: selectedGrade) { _, newGrade in
            if let grade = newGrade,
               let idx = circuit.orderedMappings.firstIndex(where: { $0.id.uuidString == grade }) {
                selectedIndex = idx
            }
        }
    }
}

/// A single color swatch for circuit grade selection
struct CircuitColorSwatch: View {
    let mapping: CircuitColorMapping
    let isSelected: Bool
    var showLabel: Bool = false
    var size: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 4) {
            // Color swatch
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(mapping.swiftUIColor)
                    .frame(width: size, height: size)
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: size, height: size)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(mapping.swiftUIColor, lineWidth: 2)
                        .frame(width: size + 4, height: size + 4)
                }
            }
            
            // Label (color name and grade range)
            if showLabel {
                VStack(spacing: 0) {
                    Text(mapping.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(mapping.gradeRangeDescription)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// Display a circuit grade inline with color indicator
struct CircuitGradeDisplay: View {
    let mapping: CircuitColorMapping
    var showGradeRange: Bool = true
    
    var body: some View {
        HStack(spacing: 8) {
            // Color indicator
            Circle()
                .fill(mapping.swiftUIColor)
                .frame(width: 20, height: 20)
            
            // Text info
            VStack(alignment: .leading, spacing: 0) {
                Text(mapping.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if showGradeRange {
                    Text(mapping.gradeRangeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/// Horizontal color bar showing all circuit colors (compact preview)
struct CircuitColorBar: View {
    let circuit: CustomCircuitGrade
    var height: CGFloat = 8
    var cornerRadius: CGFloat = 4
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(circuit.orderedMappings) { mapping in
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(mapping.swiftUIColor)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Previews

#Preview("Circuit Grade Picker") {
    struct PreviewWrapper: View {
        @State private var selectedGrade: String?
        
        var body: some View {
            let circuit = GradeSystemFactory.createVScaleDefaultCircuit()
            
            VStack(spacing: 20) {
                Text("Circuit Grade Picker")
                    .font(.headline)
                
                CircuitGradePicker(circuit: circuit, selectedGrade: $selectedGrade)
                
                if let grade = selectedGrade,
                   let mapping = circuit.mapping(forGrade: grade) {
                    HStack {
                        Text("Selected:")
                        CircuitGradeDisplay(mapping: mapping)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Circuit Color Bar") {
    VStack(spacing: 20) {
        CircuitColorBar(circuit: GradeSystemFactory.createVScaleDefaultCircuit())
            .padding(.horizontal)
        
        CircuitColorBar(circuit: GradeSystemFactory.createFontDefaultCircuit(), height: 12, cornerRadius: 6)
            .padding(.horizontal)
    }
}
