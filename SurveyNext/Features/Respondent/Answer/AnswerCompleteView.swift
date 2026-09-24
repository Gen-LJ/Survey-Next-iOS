import SwiftUI

/// "Thanks for sharing!" with the points you earned.
/// Equivalent of `AnswerCompleteScreen`.
struct AnswerCompleteView: View {
    let points: Int
    let onDone: () -> Void

    @State private var badgeScale: CGFloat = 0
    @State private var shownPoints = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [.heroStart, .heroEnd], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Image(systemName: "checkmark")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color.heroStart)
                    .frame(width: 112, height: 112)
                    .background(.white, in: .circle)
                    .scaleEffect(badgeScale)
                    .accessibilityHidden(true)

                Text("Thanks for sharing!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Your answers were submitted.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))

                if points > 0 {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(Color.heroStar)
                        Text("+\(shownPoints.pointsText) points")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: Double(shownPoints)))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.16), in: .capsule)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("You earned \(points) points")
                }
            }
            .padding(Spacing.lg)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onDone) {
                Text("Back to home")
                    .font(.headline)
                    .foregroundStyle(Color.heroStart)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(.white, in: .rect(cornerRadius: Radius.medium))
            }
            .buttonStyle(.plain)
            .padding(Spacing.lg)
        }
        .task {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                badgeScale = 1
            }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.8)) {
                shownPoints = points
            }
        }
    }
}

#Preview {
    AnswerCompleteView(points: 50) {}
}
