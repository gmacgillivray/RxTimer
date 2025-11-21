import SwiftUI

struct BigTimeDisplay: View {
    let seconds: Int
    var accentColor: Color = .accentColor
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        Text(String(format: "%02d:%02d", seconds/60, seconds%60))
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .white.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: accentColor.opacity(0.3), radius: 20, x: 0, y: 0)
            .accessibilityAddTraits(.isHeader)
    }

    private var fontSize: CGFloat {
        // iPad: 192 (double), iPhone: 96
        horizontalSizeClass == .regular ? 192 : 96
    }
}
