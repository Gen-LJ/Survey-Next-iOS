import SwiftUI

/// Full-width filled button with a loading state. Equivalent of `CustomButton`.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Keep the label in the layout so the height doesn't jump.
                Group {
                    if let systemImage {
                        Label(title, systemImage: systemImage)
                    } else {
                        Text(title)
                    }
                }
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView().tint(.brandOnPrimary)
                }
            }
        }
        .buttonStyle(FilledButtonStyle())
        .disabled(isLoading)
    }
}

/// Filled, full-width, 54pt tall. `tonal` is the softer secondary variant.
struct FilledButtonStyle: ButtonStyle {
    var tonal = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(tonal ? Color.brandOnPrimaryContainer : Color.brandOnPrimary)
            .background(tonal ? Color.brandPrimaryContainer : Color.brandPrimary, in: .rect(cornerRadius: Radius.medium))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
            .contentShape(.rect(cornerRadius: Radius.medium))
    }
}

/// Primary-colored outline, full width. For "Add question" and "Back".
struct OutlinedButtonStyle: ButtonStyle {
    var fullWidth = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 54)
            .foregroundStyle(Color.brandPrimary)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.medium).stroke(Color.brandPrimary, lineWidth: 1)
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
            .contentShape(.rect(cornerRadius: Radius.medium))
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton(title: "Login") {}
        PrimaryButton(title: "Publish survey", systemImage: "paperplane.fill") {}
        PrimaryButton(title: "Login", isLoading: true) {}
        PrimaryButton(title: "Disabled") {}.disabled(true)
        Button("Pause survey") {}.buttonStyle(FilledButtonStyle(tonal: true))
        Button("Add question") {}.buttonStyle(OutlinedButtonStyle())
    }
    .padding()
}
