import SwiftUI
import CoreData

struct WorkoutHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.timestamp, ascending: false)],
        animation: .default)
    private var workouts: FetchedResults<Workout>

    let onSelectWorkout: (Workout) -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("SecondaryBackground"), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if workouts.isEmpty {
                emptyStateView
            } else {
                workoutList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Close")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                }
                .accessibilityLabel("Close history")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Workout List
    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutHistoryRow(workout: workout)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteWorkout(workout)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Workouts Yet")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text("Completed workouts will appear here")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions
    private func deleteWorkout(_ workout: Workout) {
        withAnimation {
            viewContext.delete(workout)
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete workout: \(error)")
            }
        }
    }
}

// MARK: - Workout History Row
struct WorkoutHistoryRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(timerTypeColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: timerTypeIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(timerTypeColor)
            }

            // Workout info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(timerTypeName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    if !workout.wasCompleted {
                        Text("Incomplete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.2))
                            )
                    }
                }

                HStack(spacing: 16) {
                    Label(formattedDuration, systemImage: "timer")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Label(formattedDate, systemImage: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Computed Properties
    private var timerTypeName: String {
        switch workout.timerType {
        case "FT": return "For Time"
        case "AMRAP": return "AMRAP"
        case "EMOM": return "EMOM"
        default: return workout.timerType ?? "Unknown"
        }
    }

    private var timerTypeIcon: String {
        switch workout.timerType {
        case "FT": return "stopwatch"
        case "AMRAP": return "flame.fill"
        case "EMOM": return "clock.arrow.circlepath"
        default: return "timer"
        }
    }

    private var timerTypeColor: Color {
        switch workout.timerType {
        case "FT": return .accentColor
        case "AMRAP": return .orange
        case "EMOM": return .blue
        default: return .gray
        }
    }

    private var formattedDuration: String {
        let totalSeconds = Int(workout.totalDurationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.timestamp ?? Date())
    }
}
