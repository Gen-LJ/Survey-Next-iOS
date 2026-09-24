import SwiftUI

struct LoginView: View {
    /// `@State` owns the view model for the life of the screen, like `hiltViewModel()`.
    @State private var viewModel: LoginViewModel
    let onRegister: () -> Void

    init(repository: any AuthRepository, onRegister: @escaping () -> Void) {
        _viewModel = State(initialValue: LoginViewModel(repository: repository))
        self.onRegister = onRegister
    }

    var body: some View {
        // `@Bindable` lets us write `$viewModel.email` for two-way bindings.
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Image(.appLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 90)
                    .padding(.top, Spacing.lg)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Welcome")
                        .font(.largeTitle.bold())
                    Text("Join our Survey Next community and start earning today.")
                        .font(.headline)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
                .padding(.bottom, Spacing.sm)

                FormTextField.email($viewModel.email, error: viewModel.emailError)

                PasswordField(
                    text: $viewModel.password,
                    error: viewModel.passwordError,
                    contentType: .password
                )

                PrimaryButton(title: "Login", isLoading: viewModel.isLoading) {
                    Task { await viewModel.login() }
                }
                .padding(.top, Spacing.sm)

                Button(action: onRegister) {
                    (Text("Don't have an account? ").foregroundStyle(Color.appOnSurfaceVariant)
                        + Text("Register").bold().foregroundStyle(Color.brandPrimary))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.xs)
            }
            .padding(Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .errorAlert($viewModel.errorMessage)
    }
}

#Preview {
    NavigationStack {
        LoginView(repository: PreviewAuthRepository(), onRegister: {})
    }
}
