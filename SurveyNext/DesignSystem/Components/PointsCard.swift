import SwiftUI

/// Gradient hero showing a points balance. Equivalent of `PointsCard`.
struct PointsCard: View {
    let label: String
    let points: Int
    /// Line under the balance, e.g. how points are used.
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.heroStar)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 4 }
                Text(points.pointsText)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(points)))
                Text("pts")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: [.heroStart, .heroEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                // Decorative ring, as on Android.
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .offset(x: 40, y: -50)
            }
        }
        .clipShape(.rect(cornerRadius: Radius.large))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PointsCard(label: "Available balance", points: 1_250, caption: "Publishing a survey reserves its reward pool from this balance")
        .padding()
}
