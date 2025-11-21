import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    let workout: Workout
    let onDismiss: () -> Void

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
                // Shared content (with date)
                WorkoutSummaryContentView(data: workout, showDate: true)

                // Done button
                Button(action: {
                    onDismiss()
                }) {
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
                .accessibilityLabel("Return to history")
                .padding()
            }
        }
        .navigationTitle("Workout Summary")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var statusColor: Color {
        workout.wasCompleted ? .green : .orange
    }
}
