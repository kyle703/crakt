import SwiftUI

struct SlideToConfirmView: View {
    /// Text shown before completion.
    let text: String
    /// Text shown after completion (e.g. "Confirmed!").
    let confirmedText: String
    /// Called once the user slides beyond threshold (after final animations).
    let onComplete: () -> Void
    
    @State private var dragOffset: CGFloat = 0      // How far the knob is dragged
    @State private var isConfirmed = false          // True once user slides beyond threshold
    
    // UI states for final animations
    @State private var backgroundHidden = false     // Hide the track after confirmation
    @State private var showCheckmark = false        // Switch icon from chevron to checkmark
    @State private var knobScale: CGFloat = 1.0     // For pop animation on the knob
    
    @GestureState private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let knobHeight = geometry.size.height
            let cornerRadius = knobHeight / 2
            
            // How far along the track the knob has moved, 0...1
            let progress = max(0, min(dragOffset / (totalWidth - knobHeight), 1))
            
            ZStack(alignment: .leading) {
                // Background track (hide it once user confirms)
                if !backgroundHidden {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.black.opacity(0.2))
                        .transition(.opacity)
                }
                
                // Centered text that becomes more visible as we slide
                Text(isConfirmed ? confirmedText : text)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Increase opacity with progress (0 = invisible, 1 = fully visible)
                    .opacity(isConfirmed ? 0 : 1 - progress)
                
                // Draggable knob
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white)
                    
                    // Switch from chevron to checkmark once fully confirmed
                    if showCheckmark {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(.system(size: 20, weight: .bold))
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                .frame(width: knobHeight, height: knobHeight)
                .offset(x: dragOffset)
                .scaleEffect(knobScale) // For pop animation
                .shadow(color: .white.opacity(isDragging ? 0.4 : 0),
                        radius: isDragging ? 8 : 0)
                .gesture(
                    DragGesture()
                        .updating($isDragging) { _, state, _ in
                            // Track live "dragging" for visual effects
                            state = true
                        }
                        .onChanged { value in
                            // Ignore drags if already confirmed
                            guard !isConfirmed else { return }
                            // Clamp between 0 and totalWidth - knobHeight
                            let translation = value.translation.width
                            dragOffset = max(0, min(translation, totalWidth - knobHeight))
                        }
                        .onEnded { _ in
                            // If already confirmed, ignore
                            guard !isConfirmed else { return }
                            let threshold = (totalWidth - knobHeight) * 0.5
                            
                            if dragOffset > threshold {
                                // User slid far enough -> confirm
                                isConfirmed = true
                                
                                // Final animations
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    // Remove background track
                                    backgroundHidden = true
                                    // Move knob to center
                                    dragOffset = (totalWidth - knobHeight) / 2
                                }
                                // Delay showing checkmark & pop so knob has time to move
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.3)) {
                                    showCheckmark = true
                                    knobScale = 1.2
                                }
                                // Return knob scale to 1
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.6)) {
                                    knobScale = 1.0
                                }
                                
                                // Call onComplete after knob transitions
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    onComplete()
                                }
                            } else {
                                // Not past threshold -> snap back
                                withAnimation {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                // Stop user interaction once confirmed
                .allowsHitTesting(!isConfirmed)
            }
        }
        .frame(height: 50)
    }
}

// MARK: - Preview

struct SlideToConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        SlideToConfirmView(
            text: "Slide to Confirm",
            confirmedText: "Confirmed!"
        ) {
            print("Action completed!")
        }
        .padding()
        .frame(height: 60)
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
