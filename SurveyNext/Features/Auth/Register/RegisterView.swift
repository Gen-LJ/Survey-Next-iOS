import SwiftUI

struct RegisterView: View {
    @State private var viewModel: RegisterViewModel
    let onLogin: () -> Void

    init(repository: any AuthRepository, onLogin: @escaping () -> Void) {
        _viewModel = State(initialValue: RegisterViewModel(repository: repository))
        self.onLogin = onLogin
    }

    var body: some View {
        Group {
            switch viewModel.formState {
            case .loading:
                ProgressView("Retrieving form…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't load the form", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { Task { await viewModel.loadForm() } }
                        .buttonStyle(.borderedProminent)
                }
            case .loaded:
                form
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.inline)
        // `.task` runs when the screen appears and is cancelled when it leaves,
        // like `LaunchedEffect(Unit)`.
        .task {
            if case .loading = viewModel.formState { await viewModel.loadForm() }
        }
    }

    private var form: some View {
        @Bindable var viewModel = viewModel

        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("How will you use Survey Next?")
                    .font(.headline)

                HStack(spacing: 12) {
                    RoleOptionCard(
                        systemImage: "text.bubble",
                        title: "Respondent",
                        subtitle: "Answer surveys and earn points",
                        isSelected: viewModel.role == .respondent
                    ) { viewModel.role = .respondent }

                    RoleOptionCard(
                        systemImage: "megaphone",
                        title: "Interviewer",
                        subtitle: "Create surveys and collect insights",
                        isSelected: viewModel.role == .interviewer
                    ) { viewModel.role = .interviewer }
                }
                .fixedSize(horizontal: false, vertical: true)

                FormTextField(
                    title: "Name",
                    text: $viewModel.name,
                    prompt: "Your name",
                    error: viewModel.errors[.name],
                    contentType: .name,
                    autocapitalization: .words
                )

                FormTextField.email($viewModel.email, error: viewModel.errors[.email])

                PickerField(
                    title: "Country",
                    placeholder: "Select country",
                    items: viewModel.countries,
                    selection: $viewModel.selectedCountry,
                    label: \.name,
                    error: viewModel.errors[.country]
                )

                PickerField(
                    title: "Region",
                    placeholder: "Select region",
                    items: viewModel.regions,
                    selection: $viewModel.selectedRegion,
                    label: \.name,
                    error: viewModel.errors[.region],
                    helper: "You'll see surveys that target your region",
                    isDisabled: viewModel.selectedCountry == nil
                )

                PasswordField(text: $viewModel.password, error: viewModel.errors[.password])

                PasswordField(
                    title: "Confirm password",
                    text: $viewModel.confirmPassword,
                    error: viewModel.errors[.confirmPassword]
                )

                PrimaryButton(title: "Create account", isLoading: viewModel.isSubmitting) {
                    Task { await viewModel.register() }
                }
                .padding(.top, Spacing.sm)

                Button(action: onLogin) {
                    (Text("Already have an account? ").foregroundStyle(Color.appOnSurfaceVariant)
                        + Text("Login").bold().foregroundStyle(Color.brandPrimary))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, Spacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
        .errorAlert($viewModel.errorMessage)
    }
}

#Preview {
    NavigationStack {
        RegisterView(repository: PreviewAuthRepository(), onLogin: {})
    }
}
