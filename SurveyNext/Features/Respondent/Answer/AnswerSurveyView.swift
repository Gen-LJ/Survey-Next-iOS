import SwiftUI

/// Full-screen, one question at a time. After submitting it shows the
/// reward screen. Equivalent of `AnswerSurveyScreen` + `AnswerCompleteScreen`.
struct AnswerSurveyView: View {
    /// Called with true once answers were submitted and the user taps "Back to home".
    let onClose: (_ submitted: Bool) -> Void

    @State private var viewModel: AnswerSurveyViewModel
    @State private var isConfirmingExit = false

    init(surveyId: Int, repository: any RespondentRepository, onClose: @escaping (_ submitted: Bool) -> Void) {
        self.onClose = onClose
        _viewModel = State(initialValue: AnswerSurveyViewModel(surveyId: surveyId, repository: repository))
    }

    var body: some View {
        if let points = viewModel.earnedPoints {
            AnswerCompleteView(points: points) { onClose(true) }
                .transition(.opacity)
        } else {
            NavigationStack {
                content
                    .background(Color.appBackground)
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                requestExit()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel("Close")
                        }
                    }
            }
            .task {
                if viewModel.state.value == nil {
                    await viewModel.load()
                }
            }
        }
    }

    private var title: String {
        guard viewModel.state.value != nil, !viewModel.questions.isEmpty else { return "" }
        return "Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)"
    }

    @ViewBuilder
    private var content: some View {
        @Bindable var viewModel = viewModel

        switch viewModel.state {
        case .loading:
            LoadingView()
        case .failed(let message):
            ScrollView {
                EmptyStateView(systemImage: "nosign", title: "Can't open this survey", message: message) {
                    Button("Go back") { onClose(false) }
                        .buttonStyle(.borderedProminent)
                }
            }
            .defaultScrollAnchor(.center)
        case .loaded:
            questionFlow
                .toast($viewModel.errorMessage)
                .alert("Leave survey?", isPresented: $isConfirmingExit) {
                    Button("Leave", role: .destructive) { onClose(false) }
                    Button("Keep answering", role: .cancel) {}
                } message: {
                    Text("Your answers so far won't be saved.")
                }
        }
    }

    private var questionFlow: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(viewModel.currentIndex + 1), total: Double(max(viewModel.questions.count, 1)))
                .tint(Color.brandPrimary)
                .padding(.horizontal, Spacing.md)
                .animation(.easeInOut, value: viewModel.currentIndex)

            ZStack {
                if let question = viewModel.current {
                    ScrollView {
                        QuestionPage(question: question, viewModel: viewModel)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .id(question.id)
                    .transition(pageTransition)
                }
            }
            .frame(maxHeight: .infinity)
            .clipped()
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)

            if let question = viewModel.current {
                HStack(spacing: 12) {
                    if viewModel.currentIndex > 0 {
                        Button("Back") { viewModel.previous() }
                            .buttonStyle(OutlinedButtonStyle(fullWidth: false))
                    }
                    PrimaryButton(title: viewModel.isLast ? "Submit" : "Next", isLoading: viewModel.isSubmitting) {
                        if viewModel.isLast {
                            Task { await viewModel.submit() }
                        } else {
                            viewModel.next()
                        }
                    }
                    .disabled(!viewModel.isAnswered(question))
                }
                .padding(Spacing.md)
            }
        }
    }

    private var pageTransition: AnyTransition {
        let forward = viewModel.movedForward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func requestExit() {
        if viewModel.hasAnswers {
            isConfirmingExit = true
        } else {
            onClose(false)
        }
    }
}

private struct QuestionPage: View {
    let question: Question
    let viewModel: AnswerSurveyViewModel

    var body: some View {
        let responses = viewModel.responses(for: question)

        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(question.text)
                    .font(.title2.bold())
                    .foregroundStyle(Color.appOnSurface)
                Text(hint)
                    .font(.subheadline)
                    .foregroundStyle(Color.appOnSurfaceVariant)
            }

            switch question.questionType {
            case .multipleChoice:
                VStack(spacing: 10) {
                    ForEach(question.sortedOptions) { option in
                        OptionRow(
                            text: option.text,
                            isSelected: responses.contains(option.text),
                            isMulti: question.allowMultiAnswer
                        ) {
                            viewModel.selectOption(question, option.text)
                        }
                    }
                }
            case .rating:
                let rating = Int(responses.first ?? "") ?? 0
                VStack(spacing: 12) {
                    RatingStars(rating: rating, size: 48) { viewModel.setRating(question, $0) }
                    Text(ratingLabel(rating))
                        .font(.headline)
                        .foregroundStyle(rating > 0 ? Color.brandGold : Color.appOnSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.sm)
            case .textInput:
                FormTextField(
                    title: "Your answer",
                    text: Binding(
                        get: { responses.first ?? "" },
                        set: { viewModel.setText(question, $0) }
                    ),
                    prompt: "Type your answer",
                    minLines: 5
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hint: String {
        switch question.questionType {
        case .multipleChoice: question.allowMultiAnswer ? "Select all that apply" : "Choose one"
        case .rating: "Rate from 1 to 5 stars"
        case .textInput: "Answer in your own words"
        }
    }
}

/// A choice to tap. The whole row is the button; the radio/checkbox is decoration.
private struct OptionRow: View {
    let text: String
    let isSelected: Bool
    let isMulti: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.appOutline)
                Text(text)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.brandOnPrimaryContainer : Color.appOnSurface)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .background(isSelected ? Color.brandPrimaryContainer : Color.appSurfaceLow, in: .rect(cornerRadius: Radius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.medium)
                    .stroke(isSelected ? Color.brandPrimary : Color.appOutlineVariant, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(.rect(cornerRadius: Radius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var symbol: String {
        if isMulti {
            isSelected ? "checkmark.square.fill" : "square"
        } else {
            isSelected ? "largecircle.fill.circle" : "circle"
        }
    }
}

#Preview {
    let container = AppContainer.preview()
    AnswerSurveyView(surveyId: 1, repository: container.respondentRepository) { _ in }
}
