import SwiftUI

/// Toast overlay that displays Quick Start countdown with cancel option
struct QuickStartCountdownToast: View {
    let seconds: Int
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Progress indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.9)

            // Countdown text
            VStack(alignment: .leading, spacing: 4) {
                Text("Starting workout...")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(seconds) second\(seconds == 1 ? "" : "s") remaining")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .accessibilityLabel("Cancel Quick Start")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Starting workout in \(seconds) second\(seconds == 1 ? "" : "s")")
        .accessibilityHint("Double tap to cancel")
    }
}

// MARK: - Preview
#if DEBUG
struct QuickStartCountdownToast_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                QuickStartCountdownToast(seconds: 10) {
                    print("Cancel tapped")
                }

                Spacer().frame(height: 20)

                QuickStartCountdownToast(seconds: 1) {
                    print("Cancel tapped")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
