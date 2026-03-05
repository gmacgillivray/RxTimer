import SwiftUI

struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color("CardBackground"))
                .overlay(
                    Capsule()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
