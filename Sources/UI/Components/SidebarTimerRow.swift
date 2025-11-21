import SwiftUI

/// Sidebar row displaying timer type with Quick Start button
struct SidebarTimerRow: View {
    let timerType: TimerType
    let isSelected: Bool
    let onTap: () -> Void
    let onQuickStart: () -> Void
    let quickStartLabel: String

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(timerType.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Quick Start button
                Button(action: {
                    onQuickStart()
                }) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(quickStartLabel)
                .accessibilityHint("Starts workout immediately with default settings")
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch timerType {
        case .forTime: return "stopwatch"
        case .amrap: return "flame.fill"
        case .emom: return "clock.arrow.circlepath"
        }
    }

    private var iconColor: Color {
        switch timerType {
        case .forTime: return .accentColor
        case .amrap: return .orange
        case .emom: return .blue
        }
    }

    private var subtitle: String {
        switch timerType {
        case .forTime: return "Count up"
        case .amrap: return "Count down"
        case .emom: return "Intervals"
        }
    }
}

// MARK: - Preview
#if DEBUG
struct SidebarTimerRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                SidebarTimerRow(
                    timerType: .forTime,
                    isSelected: false,
                    onTap: { print("Row tapped") },
                    onQuickStart: { print("Quick Start tapped") },
                    quickStartLabel: "Quick Start For Time, no time cap"
                )

                SidebarTimerRow(
                    timerType: .amrap,
                    isSelected: true,
                    onTap: { print("Row tapped") },
                    onQuickStart: { print("Quick Start tapped") },
                    quickStartLabel: "Quick Start AMRAP, 10 minutes"
                )

                SidebarTimerRow(
                    timerType: .emom,
                    isSelected: false,
                    onTap: { print("Row tapped") },
                    onQuickStart: { print("Quick Start tapped") },
                    quickStartLabel: "Quick Start EMOM, 10 intervals of 60 seconds"
                )
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
