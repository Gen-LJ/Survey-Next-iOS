import SwiftUI

/// A labelled number with − / + buttons. Equivalent of `Stepper` on Android.
struct StepperRow: View {
    let title: String
    var subtitle: String?
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...60
    var suffix = ""

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appOnSurface)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
            }
            Spacer()
            Text("\(value)\(suffix)")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(Color.appOnSurface)
            Stepper(title, value: $value, in: range)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.medium))
    }
}

#Preview {
    StepperRow(title: "Estimated time", subtitle: "How long it takes to answer", value: .constant(5), suffix: " min")
        .padding()
}
