import SwiftUI
import UIKit

extension View {
    /// Shows `message` briefly at the bottom of the screen, then sets it back
    /// to nil. The iOS stand-in for Android's Snackbar.
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appInverseOnSurface)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.appInverseSurface, in: .capsule)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onTapGesture { dismiss() }
                        .task(id: message) {
                            try? await Task.sleep(for: .seconds(2.5))
                            if !Task.isCancelled { dismiss() }
                        }
                        .accessibilityAddTraits(.isStaticText)
                        .onAppear {
                            UIAccessibility.post(notification: .announcement, argument: message)
                        }
                }
            }
            .animation(.spring(duration: 0.35), value: message)
    }

    private func dismiss() {
        message = nil
    }
}

#Preview {
    Color.appBackground
        .toast(.constant("Saved for later"))
}
