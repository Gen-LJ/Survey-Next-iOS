import SwiftUI

/// Password input with a show/hide eye. Equivalent of `PasswordTextField`.
struct PasswordField: View {
    var title = "Password"
    @Binding var text: String
    var error: String?
    /// `.password` enables Keychain autofill on the login screen.
    var contentType: UITextContentType?

    @State private var isVisible = false

    var body: some View {
        FormField(title: title, error: error) {
            HStack {
                Group {
                    if isVisible {
                        TextField(title, text: $text, prompt: Text("••••••"))
                    } else {
                        SecureField(title, text: $text, prompt: Text("••••••"))
                    }
                }
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel(title)

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isVisible ? "Hide password" : "Show password")
            }
        }
    }
}

#Preview {
    PasswordField(text: .constant("secret"), error: nil)
        .padding()
}
