import SwiftUI

public struct RoundSplitDisplay: Equatable {
    public let roundNumber: Int
    public let splitTime: TimeInterval
    
    public init(roundNumber: Int, splitTime: TimeInterval) {
        self.roundNumber = roundNumber
        self.splitTime = splitTime
    }
}

struct WorkoutSummaryView: View {
    let data: WorkoutSummaryData
    let onDismiss: () -> Void
    var onRepeat: (() -> Void)?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("SecondaryBackground"), Color.black, Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header (replaces navigation bar for full-screen presentation)
                HStack {
                    Spacer()
                    Text("Workout Summary")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)

                // Shared content
                WorkoutSummaryContentView(data: data, showDate: false)

                // Action buttons
                HStack(spacing: 12) {
                    // Repeat button (secondary)
                    if let onRepeat = onRepeat {
                        Button(action: onRepeat) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Repeat")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("CardBackground"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(statusColor.opacity(0.5), lineWidth: 1.5)
                                    )
                            )
                            .foregroundColor(.white)
                        }
                        .accessibilityLabel("Repeat this workout")
                    }

                    // Done button (primary)
                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Done")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [statusColor, statusColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: statusColor.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                        .foregroundColor(.white)
                    }
                    .accessibilityLabel("Finish and return to home")
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var statusColor: Color {
        data.wasCompleted ? .green : .orange
    }
}
