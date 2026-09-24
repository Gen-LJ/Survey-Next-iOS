import SwiftUI

/// A horizontal bar filled to `fraction` (0...1), for the analytics charts.
struct BarTrack: View {
    let fraction: Double
    var color: Color = .brandPrimary
    var height: CGFloat = 10

    @State private var shown: Double = 0

    var body: some View {
        Capsule()
            .fill(Color.appSurfaceHighest)
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * shown)
                }
            }
            .clipShape(.capsule)
            .onAppear { animate(to: fraction) }
            .onChange(of: fraction) { _, newValue in animate(to: newValue) }
            .accessibilityHidden(true)
    }

    private func animate(to value: Double) {
        withAnimation(.easeOut(duration: 0.6)) {
            shown = min(max(value, 0), 1)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        BarTrack(fraction: 0.7)
        BarTrack(fraction: 0.25, color: .brandGold)
    }
    .padding()
}
