import SwiftUI

struct PacingStatsView: View {
    let currentRoundTimeText: String
    let lastRoundSplitTime: TimeInterval?
    let currentRoundVsLastDelta: TimeInterval?
    let accentColor: Color
    let currentRoundFontSize: CGFloat
    let lastRoundFontSize: CGFloat
    let deltaFontSize: CGFloat

    @Binding var areDetailsExpanded: Bool

    var body: some View {
        VStack(spacing: 8) {
            if areDetailsExpanded {
                HStack(spacing: 50) {
                    // Current Round Column
                    VStack(spacing: 6) {
                        Text("Current Round")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(currentRoundTimeText)
                            .font(.system(size: currentRoundFontSize, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(accentColor)
                    }

                    // Last Round Column
                    VStack(spacing: 6) {
                        Text("Last Round")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(lastRoundSplitTime.map(TimeFormatter.format) ?? "––:––")
                            .font(.system(size: lastRoundFontSize, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(lastRoundSplitTime != nil ? .white.opacity(0.8) : .white.opacity(0.4))

                        // Delta indicator
                        if let delta = currentRoundVsLastDelta {
                            Text(TimeFormatter.formatDelta(delta))
                                .font(.system(size: deltaFontSize, weight: .medium))
                                .foregroundColor(delta > 0 ? .orange : .green)
                        } else {
                            Text(" ")
                                .font(.system(size: deltaFontSize, weight: .medium))
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.top, -6)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Pacing: Current Round \(currentRoundTimeText). Last Round \(lastRoundSplitTime.map(TimeFormatter.format) ?? "None"). \(currentRoundVsLastDelta.map { diff in diff > 0 ? "\(TimeFormatter.formatDeltaForVoiceOver(diff)) slower" : "\(TimeFormatter.formatDeltaForVoiceOver(diff)) faster" } ?? "")")
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Toggle Button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    areDetailsExpanded.toggle()
                }
            }) {
                Image(systemName: areDetailsExpanded ? "chevron.compact.up" : "chevron.compact.down")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 80, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(areDetailsExpanded ? "Collapse Pacing Details" : "Show Pacing Details")
        }
    }
}
