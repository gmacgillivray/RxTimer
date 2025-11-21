import SwiftUI

// MARK: - Display Data Protocol
/// Protocol for data that can be displayed in workout summary
protocol WorkoutSummaryDisplayData {
    var timerType: String? { get }
    var totalDurationSeconds: Double { get }
    var wasCompleted: Bool { get }
    var date: Date? { get }
    var roundSplitSets: [[WorkoutRoundSplit]] { get }
    var setDurationDetails: [SetDuration] { get }
}

// MARK: - Round Split Data
struct WorkoutRoundSplit: Identifiable {
    let id: UUID
    let roundNumber: Int
    let splitTime: TimeInterval
}

// MARK: - Workout Summary Content View
/// Shared component for displaying workout summary/results
/// Used by both WorkoutSummaryView (after completion) and WorkoutDetailView (history)
struct WorkoutSummaryContentView: View {
    let data: WorkoutSummaryDisplayData
    let showDate: Bool

    init(data: WorkoutSummaryDisplayData, showDate: Bool = false) {
        self.data = data
        self.showDate = showDate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)

                // Success Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: data.wasCompleted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(statusColor)
                }

                // Title
                VStack(spacing: 8) {
                    Text(data.wasCompleted ? "Workout Complete!" : "Workout Saved")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(timerTypeName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)

                    // Date (optional, for history view)
                    if showDate, let date = data.date {
                        Text(formattedDate(date))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }

                // Duration Card
                VStack(spacing: 12) {
                    Text("Total Time")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(formattedDuration)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: statusColor.opacity(0.3), radius: 20, x: 0, y: 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("CardBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(statusColor.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: statusColor.opacity(0.2), radius: 15, x: 0, y: 5)
                )

                // Round Splits Section
                if hasRoundSplits {
                    roundSplitsSection
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Round Splits Section
    private var roundSplitsSection: some View {
        VStack(spacing: 16) {
            Text("Round Splits")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(Array(data.roundSplitSets.enumerated()), id: \.offset) { setIndex, setRounds in
                if !setRounds.isEmpty {
                    VStack(spacing: 12) {
                        // Set header (only show if multiple sets)
                        if data.roundSplitSets.count > 1 {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Set \(setIndex + 1)")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("\(setRounds.count) Rounds")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }

                                // Show set duration if available
                                if let setDuration = getSetDuration(for: setIndex) {
                                    HStack(spacing: 12) {
                                        Text("Work: \(formatSplitTime(setDuration.workingTime))")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)

                                        if setDuration.restTime > 0 {
                                            Text("•")
                                                .foregroundColor(.secondary.opacity(0.5))
                                            Text("Rest: \(formatSplitTime(setDuration.restTime))")
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }

                                        Text("•")
                                            .foregroundColor(.secondary.opacity(0.5))
                                        Text("Total: \(formatSplitTime(setDuration.totalTime))")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(statusColor.opacity(0.8))

                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Round split rows
                        VStack(spacing: 6) {
                            ForEach(setRounds) { split in
                                HStack {
                                    Text("Round \(split.roundNumber)")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text(formatSplitTime(split.splitTime))
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(statusColor)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("CardBackground").opacity(0.5))
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("CardBackground"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var hasRoundSplits: Bool {
        data.roundSplitSets.contains { !$0.isEmpty }
    }

    private var statusColor: Color {
        data.wasCompleted ? .green : .orange
    }

    private var timerTypeName: String {
        guard let timerType = data.timerType else { return "Unknown" }
        switch timerType {
        case "FT": return "For Time"
        case "AMRAP": return "AMRAP"
        case "EMOM": return "EMOM"
        default: return timerType
        }
    }

    private var formattedDuration: String {
        let totalSeconds = Int(data.totalDurationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatSplitTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    private func getSetDuration(for setIndex: Int) -> SetDuration? {
        let setDurations = data.setDurationDetails
        guard setIndex < setDurations.count else { return nil }
        return setDurations[setIndex]
    }
}
