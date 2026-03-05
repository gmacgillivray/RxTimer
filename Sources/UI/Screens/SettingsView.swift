import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color("SecondaryBackground"), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                List {
                    Section {
                        Toggle(isOn: $settings.audioEnabled) {
                            Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                        }

                        Toggle(isOn: $settings.countdownSoundsEnabled) {
                            Label("Countdown Beeps", systemImage: "bell.fill")
                        }
                        .disabled(!settings.audioEnabled)
                        .opacity(settings.audioEnabled ? 1.0 : 0.5)
                    } header: {
                        Text("Audio")
                    }

                    Section {
                        Toggle(isOn: $settings.hapticsEnabled) {
                            Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                        }
                    } header: {
                        Text("Haptics")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
