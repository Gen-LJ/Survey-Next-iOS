import SwiftUI

/// A number with an icon and a label, optionally tappable. Equivalent of `StatCard`.
struct StatCard: View {
    let systemImage: String
    let value: String
    let label: String
    var accent: Color = .brandPrimary
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(CardButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.14), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(Color.appOnSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))
        .accessibilityElement(children: .combine)
    }
}

/// Dims a card while it's pressed, instead of the blue text tint of a plain button.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCard(systemImage: "square.and.pencil", value: "3", label: "Drafts", accent: SurveyState.draft.badgeForeground) {}
        StatCard(systemImage: "play.circle", value: "1", label: "Live", accent: SurveyState.published.badgeForeground)
    }
    .padding()
}
