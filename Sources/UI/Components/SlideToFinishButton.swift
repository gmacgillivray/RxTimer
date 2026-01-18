import SwiftUI
import UIKit

/// A slide-to-confirm button that prevents accidental activation of destructive actions.
/// Designed for ending workouts where accidental taps would be frustrating.
struct SlideToFinishButton: View {
    let label: String
    let icon: String
    let accentColor: Color
    let onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var hasCompleted: Bool = false
    @GestureState private var isPressed: Bool = false

    // Layout constants meeting accessibility requirements
    private let trackHeight: CGFloat = 60
    private let thumbSize: CGFloat = 52 // Meets 52pt minimum touch target
    private let thumbPadding: CGFloat = 4
    private let completionThreshold: CGFloat = 0.85 // 85% of track width to trigger

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
            let progress = min(dragOffset / maxOffset, 1.0)
            let isNearCompletion = progress >= completionThreshold

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(trackBackgroundColor(progress: progress))
                    .overlay(
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .stroke(trackStrokeColor(progress: progress), lineWidth: 1)
                    )

                // Progress fill
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(progressFillColor(progress: progress))
                    .frame(width: thumbSize + dragOffset + thumbPadding)

                // Label text (fades as thumb approaches)
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 14, weight: .semibold))
                        Text(label)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(1 - progress * 1.5) // Fades out as slider progresses
                    Spacer()
                }
                .padding(.leading, thumbSize + thumbPadding * 2)

                // Thumb
                Circle()
                    .fill(thumbColor(progress: progress, isNearCompletion: isNearCompletion))
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Image(systemName: isNearCompletion ? "checkmark" : icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: accentColor.opacity(0.4), radius: isDragging ? 8 : 4, x: 0, y: 2)
                    .scaleEffect(isDragging ? 1.05 : 1.0)
                    .offset(x: thumbPadding + dragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !hasCompleted else { return }
                                isDragging = true
                                // Clamp offset between 0 and maxOffset
                                dragOffset = min(max(0, value.translation.width), maxOffset)
                            }
                            .onEnded { value in
                                isDragging = false
                                let finalProgress = dragOffset / maxOffset

                                if finalProgress >= completionThreshold {
                                    // Complete the action
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = maxOffset
                                        hasCompleted = true
                                    }

                                    // Haptic feedback
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)

                                    // Delay callback slightly for visual feedback
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onComplete()
                                    }
                                } else {
                                    // Spring back to start
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        dragOffset = 0
                                    }

                                    // Light haptic for reset
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            }
                    )
            }
            .frame(height: trackHeight)
        }
        .frame(height: trackHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            // VoiceOver users can double-tap to activate
            onComplete()
        }
    }

    // MARK: - Color Helpers

    private func trackBackgroundColor(progress: CGFloat) -> Color {
        Color("CardBackground").opacity(0.8)
    }

    private func trackStrokeColor(progress: CGFloat) -> Color {
        if progress >= completionThreshold {
            return accentColor.opacity(0.8)
        }
        return accentColor.opacity(0.3 + progress * 0.3)
    }

    private func progressFillColor(progress: CGFloat) -> Color {
        if progress >= completionThreshold {
            return accentColor.opacity(0.4)
        }
        return accentColor.opacity(0.15 + progress * 0.2)
    }

    private func thumbColor(progress: CGFloat, isNearCompletion: Bool) -> LinearGradient {
        if isNearCompletion {
            return LinearGradient(
                colors: [accentColor, accentColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [accentColor.opacity(0.8), accentColor.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 24) {
            SlideToFinishButton(
                label: "Slide to Finish",
                icon: "flag.checkered",
                accentColor: .orange
            ) {
                print("Workout finished!")
            }
            .padding(.horizontal)

            SlideToFinishButton(
                label: "Slide to Complete Set",
                icon: "checkmark.circle.fill",
                accentColor: .green
            ) {
                print("Set completed!")
            }
            .padding(.horizontal)
        }
    }
    .preferredColorScheme(.dark)
}
