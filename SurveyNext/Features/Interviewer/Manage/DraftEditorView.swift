import SwiftUI

/// A draft survey: Questions, Details and Publish sections.
/// Equivalent of `DraftEditor` (a segmented control instead of a tab row + pager).
struct DraftEditorView: View {
    let survey: Survey
    let viewModel: ManageSurveyViewModel

    @State private var section: Section = .questions

    enum Section: Hashable {
        case questions, details, publish
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $section) {
                Text("Questions (\(survey.questionCount))").tag(Section.questions)
                Text("Details").tag(Section.details)
                Text("Publish").tag(Section.publish)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Group {
                switch section {
                case .questions: QuestionsSection(survey: survey, viewModel: viewModel)
                case .details: DetailsSection(viewModel: viewModel)
                case .publish: PublishSection(survey: survey, viewModel: viewModel)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Questions

private struct QuestionsSection: View {
    let survey: Survey
    let viewModel: ManageSurveyViewModel

    /// Non-nil while the editor sheet is open; a nil question means "new".
    @State private var editorTarget: EditorTarget?
    @State private var pendingDelete: Question?

    var body: some View {
        let questions = survey.sortedQuestions

        ScrollView {
            LazyVStack(spacing: 12) {
                if questions.isEmpty {
                    EmptyStateView(
                        systemImage: "text.bubble",
                        title: "No questions yet",
                        message: "Mix multiple choice, star ratings and open text. Every question is required for respondents."
                    )
                }

                ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                    QuestionCard(
                        number: index + 1,
                        question: question,
                        onEdit: { editorTarget = EditorTarget(question: question) },
                        onDelete: { pendingDelete = question }
                    )
                }

                Button {
                    editorTarget = EditorTarget(question: nil)
                } label: {
                    Label("Add question", systemImage: "plus")
                }
                .buttonStyle(OutlinedButtonStyle())
            }
            .padding(Spacing.md)
        }
        .sheet(item: $editorTarget) { target in
            QuestionEditorSheet(existing: target.question, isSaving: viewModel.isBusy) { draft in
                await viewModel.saveQuestion(existing: target.question, draft: draft)
            }
        }
        .alert(
            "Delete question?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            presenting: pendingDelete
        ) { question in
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteQuestion(question) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { question in
            Text("\"\(question.text)\" will be removed from this survey.")
        }
    }

    private struct EditorTarget: Identifiable {
        let id = UUID()
        let question: Question?
    }
}

// MARK: - Details

private struct DetailsSection: View {
    let viewModel: ManageSurveyViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        if let form = Binding($viewModel.infoForm) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    FormTextField(title: "Title", text: form.title, prompt: "Survey title")

                    FormTextField(title: "Description", text: form.description, prompt: "What is this survey about?", minLines: 3)

                    PickerField(
                        title: "Category",
                        placeholder: viewModel.categories.isEmpty ? "Loading…" : "Select category",
                        items: viewModel.categories,
                        selection: Binding(
                            get: { viewModel.categories.first { $0.id == form.wrappedValue.categoryId } },
                            set: { if let category = $0 { form.wrappedValue.categoryId = category.id } }
                        ),
                        label: \.name
                    )

                    StepperRow(title: "Estimated time", value: form.minutes, range: 1...60, suffix: " min")

                    Text("The target country and region can't be changed after creation.")
                        .font(.caption)
                        .foregroundStyle(Color.appOnSurfaceVariant)

                    PrimaryButton(title: "Save details", isLoading: viewModel.isBusy) {
                        Task { await viewModel.saveInfo() }
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Publish

private struct PublishSection: View {
    let survey: Survey
    let viewModel: ManageSurveyViewModel

    @State private var isConfirming = false

    var body: some View {
        @Bindable var viewModel = viewModel
        let form = viewModel.publishForm
        let balanceAfter = viewModel.balance - form.totalCost
        let hasQuestions = survey.questionCount > 0
        let canPublish = hasQuestions && form.answers > 0 && form.points > 0 && balanceAfter >= 0

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label(
                    hasQuestions ? "\(pluralize(survey.questionCount, "question")) ready" : "Add at least one question",
                    systemImage: hasQuestions ? "checkmark.circle.fill" : "exclamationmark.circle"
                )
                .font(.body)
                .foregroundStyle(hasQuestions ? Color.appOnSurface : Color.appError)
                .symbolRenderingMode(.hierarchical)

                Text("Reward")
                    .font(.headline)

                HStack(alignment: .top, spacing: 12) {
                    FormTextField(
                        title: "Responses", text: $viewModel.publishForm.expectedAnswers,
                        helper: "How many you need", keyboard: .numberPad
                    )
                    FormTextField(
                        title: "Points each", text: $viewModel.publishForm.pointsPerAnswer,
                        helper: "Paid per response", keyboard: .numberPad
                    )
                }

                VStack(spacing: 10) {
                    CostRow(label: "Your balance", value: "\(viewModel.balance.pointsText) pts")
                    CostRow(label: "Reward pool", value: "− \(form.totalCost.pointsText) pts")
                    Divider()
                    CostRow(
                        label: "Balance after publishing",
                        value: "\(balanceAfter.pointsText) pts",
                        emphasize: true,
                        valueColor: balanceAfter < 0 ? .appError : .appOnSurface
                    )
                }
                .padding(Spacing.md)
                .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))

                Text("The pool is reserved when you publish and paid out as responses arrive. Deleting the survey refunds whatever hasn't been paid.")
                    .font(.caption)
                    .foregroundStyle(Color.appOnSurfaceVariant)

                if balanceAfter < 0 {
                    Text("Not enough points. Lower the reward or the number of responses.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appError)
                }

                PrimaryButton(title: "Publish survey", systemImage: "paperplane.fill", isLoading: viewModel.isBusy) {
                    isConfirming = true
                }
                .disabled(!canPublish)
            }
            .padding(Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Publish survey?", isPresented: $isConfirming) {
            Button("Publish") {
                Task { await viewModel.publish() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(form.totalCost.pointsText) points will be reserved from your balance. Questions can't be edited once the survey is live.")
        }
    }
}

private struct CostRow: View {
    let label: String
    let value: String
    var emphasize = false
    var valueColor: Color = .appOnSurface

    var body: some View {
        HStack {
            Text(label)
                .font(emphasize ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(Color.appOnSurface)
            Spacer()
            Text(value)
                .font(emphasize ? .headline : .body)
                .monospacedDigit()
                .foregroundStyle(valueColor)
        }
    }
}

#Preview {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    let viewModel = ManageSurveyViewModel(surveyId: 2, repository: container.interviewerRepository, session: container.session)
    NavigationStack {
        DraftEditorView(survey: .sample(id: 2, state: .draft), viewModel: viewModel)
    }
}
