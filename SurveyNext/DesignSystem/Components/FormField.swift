import SwiftUI

/// Label on top, bordered content, error or helper text underneath.
/// The shared frame for `FormTextField`, `PasswordField` and `PickerField`.
struct FormField<Content: View>: View {
    let title: String
    var error: String?
    var helper: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs + 2) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    // The control itself carries the title for VoiceOver.
                    .accessibilityHidden(true)
            }

            content
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
                .frame(minHeight: 52)
                .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.small))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.small)
                        .stroke(error == nil ? Color.appOutlineVariant : Color.appError, lineWidth: 1)
                }

            if let message = error ?? helper {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(error == nil ? Color.appOnSurfaceVariant : Color.appError)
            }
        }
    }
}

/// Text input. Equivalent of an `OutlinedTextField`.
struct FormTextField: View {
    let title: String
    @Binding var text: String
    var prompt: String = ""
    var error: String?
    var helper: String?
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    /// More than 1 makes a multi-line field that grows as you type.
    var minLines = 1

    var body: some View {
        FormField(title: title, error: error, helper: helper) {
            Group {
                if minLines > 1 {
                    TextField(title, text: $text, prompt: Text(prompt), axis: .vertical)
                        .lineLimit(minLines...max(minLines, 10))
                } else {
                    TextField(title, text: $text, prompt: Text(prompt))
                }
            }
            .keyboardType(keyboard)
            .textContentType(contentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(minLines == 1)
            // With a prompt, SwiftUI exposes only the placeholder to VoiceOver.
            .accessibilityLabel(title)
        }
    }
}

extension FormTextField {
    /// Preconfigured for email: no capitals, email keyboard, autofill.
    static func email(_ text: Binding<String>, error: String?) -> FormTextField {
        FormTextField(
            title: "Email",
            text: text,
            prompt: "you@example.com",
            error: error,
            keyboard: .emailAddress,
            contentType: .emailAddress,
            autocapitalization: .never
        )
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        FormTextField(title: "Name", text: .constant(""), prompt: "Your name")
        FormTextField.email(.constant("bad"), error: "Invalid email")
        FormTextField(title: "Description", text: .constant(""), prompt: "What is this survey about?", minLines: 3)
    }
    .padding()
}
