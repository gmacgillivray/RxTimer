import SwiftUI

/// Card component for displaying timer type with configuration preview
/// Adaptive sizing for iPhone and iPad layouts
struct TimerTypeCard: View {
    let timerType: TimerType
    let configuration: TimerConfiguration
    let onTap: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Header section
                cardHeader

                // Divider
                Divider()
                    .background(Color.white.opacity(0.1))

                // Configuration details
                configurationDetails
            }
            .background(cardBackground)
            .cornerRadius(16)
            .shadow(color: iconColor.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(timerType.displayName) timer")
        .accessibilityHint("Double tap to configure timer with last used settings")
    }

    // MARK: - Header Section

    private var cardHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .accessibilityHidden(true)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(timerType.displayName.uppercased())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)

                Text(useCase)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Configuration Details

    private var configurationDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAST USED")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.5)

            Text(configurationSummary)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.03))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Last used configuration: \(configurationSummary)")
    }

    // MARK: - Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        Color("CardBackground"),
                        Color("CardBackground").opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                iconColor.opacity(0.3),
                                iconColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch timerType {
        case .forTime: return "stopwatch"
        case .amrap: return "flame.fill"
        case .emom: return "clock.arrow.circlepath"
        }
    }

    private var iconColor: Color {
        switch timerType {
        case .forTime: return Color("AccentColor")
        case .amrap: return .orange
        case .emom: return .blue
        }
    }

    /// User-focused description of when to use this timer
    private var useCase: String {
        switch timerType {
        case .forTime:
            return "Complete work as fast as possible"
        case .amrap:
            return "Maximum rounds in fixed time"
        case .emom:
            return "Work at the top of every minute"
        }
    }

    /// Human-readable summary of last used configuration
    private var configurationSummary: String {
        switch timerType {
        case .forTime:
            if let cap = configuration.timeCapSeconds {
                let minutes = cap / 60
                let seconds = cap % 60
                if seconds == 0 {
                    return "\(minutes) minute time cap"
                } else {
                    return "\(minutes):\(String(format: "%02d", seconds)) time cap"
                }
            } else {
                return "No time cap"
            }

        case .amrap:
            if let duration = configuration.durationSeconds {
                let minutes = duration / 60
                let seconds = duration % 60
                if seconds == 0 {
                    return "\(minutes) minutes"
                } else {
                    return "\(minutes):\(String(format: "%02d", seconds))"
                }
            }
            return "Not configured"

        case .emom:
            if let intervals = configuration.numIntervals,
               let intervalDuration = configuration.intervalDurationSeconds {
                let totalMinutes = (intervals * intervalDuration) / 60
                return "\(intervals) rounds × \(intervalDuration)s (\(totalMinutes) min total)"
            }
            return "Not configured"
        }
    }
}

// MARK: - Button Styles

/// Button style for card tap (subtle scale effect)
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct TimerTypeCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color("SecondaryBackground"), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // AMRAP with configuration
                TimerTypeCard(
                    timerType: .amrap,
                    configuration: TimerConfiguration(
                        timerType: .amrap,
                        durationSeconds: 600
                    ),
                    onTap: { print("Card tapped") }
                )

                // For Time with cap
                TimerTypeCard(
                    timerType: .forTime,
                    configuration: TimerConfiguration(
                        timerType: .forTime,
                        timeCapSeconds: 1200
                    ),
                    onTap: { print("Card tapped") }
                )

                // EMOM
                TimerTypeCard(
                    timerType: .emom,
                    configuration: TimerConfiguration(
                        timerType: .emom,
                        numIntervals: 10,
                        intervalDurationSeconds: 60
                    ),
                    onTap: { print("Card tapped") }
                )
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
