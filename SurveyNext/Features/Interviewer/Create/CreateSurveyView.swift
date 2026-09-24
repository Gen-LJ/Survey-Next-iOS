import SwiftUI

/// "New survey" sheet: title, description, category and audience.
/// Questions and rewards come next, in the survey's editor.
/// Equivalent of `CreateSurveyScreen`.
struct CreateSurveyView: View {
    let onCreated: (Int) -> Void

    @State private var viewModel: CreateSurveyViewModel
    @Environment(\.dismiss) private var dismiss

    init(repository: any InterviewerRepository, session: SessionStore, onCreated: @escaping (Int) -> Void) {
        _viewModel = State(initialValue: CreateSurveyViewModel(repository: repository, session: session))
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            LoadStateView(state: viewModel.options, loadingMessage: "Preparing form…", retry: viewModel.load) { form in
                formContent(form)
            }
            .background(Color.appBackground)
            .navigationTitle("New survey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if case .loading = viewModel.options { await viewModel.load() }
            }
            .errorAlert($viewModel.errorMessage)
        }
        .interactiveDismissDisabled(viewModel.isSubmitting)
    }

    private func formContent(_ form: CreateSurveyForm) -> some View {
        @Bindable var viewModel = viewModel

        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Start with the basics. You'll add questions and set rewards next.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appOnSurfaceVariant)

                FormTextField(
                    title: "Title",
                    text: $viewModel.title,
                    prompt: "e.g. Commute habits",
                    error: viewModel.titleError
                )

                FormTextField(
                    title: "Description",
                    text: $viewModel.description,
                    prompt: "What is this survey about?",
                    error: viewModel.descriptionError,
                    minLines: 3
                )

                PickerField(
                    title: "Category",
                    placeholder: "Select category",
                    items: form.categoryList,
                    selection: $viewModel.category,
                    label: \.name,
                    error: viewModel.categoryError
                )

                Text("Audience")
                    .font(.headline)
                    .padding(.top, Spacing.sm)

                PickerField(
                    title: "Country",
                    placeholder: "Select country",
                    items: form.countryList,
                    selection: Binding(
                        get: { viewModel.country },
                        set: { country in
                            guard let country else { return }
                            Task { await viewModel.selectCountry(country) }
                        }
                    ),
                    label: \.name,
                    error: viewModel.countryError
                )

                PickerField(
                    title: "Region",
                    placeholder: viewModel.regionsLoading ? "Loading regions…" : "Select region",
                    items: viewModel.regions,
                    selection: $viewModel.region,
                    label: \.name,
                    error: viewModel.regionError,
                    helper: "Only respondents living here will see this survey",
                    isDisabled: viewModel.country == nil || viewModel.regionsLoading
                )

                StepperRow(
                    title: "Estimated time",
                    subtitle: "How long it takes to answer",
                    value: $viewModel.minutes,
                    range: 1...60,
                    suffix: " min"
                )

                PrimaryButton(title: "Create & add questions", isLoading: viewModel.isSubmitting) {
                    Task {
                        if let id = await viewModel.submit() {
                            onCreated(id)
                        }
                    }
                }
                .padding(.top, Spacing.sm)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    CreateSurveyView(repository: container.interviewerRepository, session: container.session) { _ in }
}
