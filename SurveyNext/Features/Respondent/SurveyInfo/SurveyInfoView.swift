import SwiftUI

/// What a survey asks and pays, before you start it.
/// Equivalent of `SurveyInfoScreen`.
struct SurveyInfoView: View {
    let repository: any RespondentRepository

    @State private var viewModel: SurveyInfoViewModel
    @State private var isAnswering = false
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss

    init(surveyId: Int, repository: any RespondentRepository) {
        self.repository = repository
        _viewModel = State(initialValue: SurveyInfoViewModel(surveyId: surveyId, repository: repository))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            switch viewModel.state {
            case .loading:
                LoadingView()
            case .failed(let message):
                ScrollView {
                    EmptyStateView(systemImage: "nosign", title: "Survey unavailable", message: message) {
                        Button("Go back") { dismiss() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .defaultScrollAnchor(.center)
            case .loaded(let survey):
                content(survey)
            }
        }
        .background(Color.appBackground)
        // Before safeAreaInset, so the toast sits above the Start button.
        .toast($viewModel.message)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.survey != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.toggleSaved() }
                    } label: {
                        Label(
                            viewModel.isSaved ? "Remove from saved" : "Save for later",
                            systemImage: viewModel.isSaved ? "bookmark.fill" : "bookmark"
                        )
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let survey = viewModel.survey {
                PrimaryButton(title: "Start survey", systemImage: "arrow.right") {
                    isAnswering = true
                }
                .disabled(survey.questions?.isEmpty ?? true)
                .padding(Spacing.md)
                .background(Color.appBackground)
            }
        }
        .fullScreenCover(isPresented: $isAnswering) {
            AnswerSurveyView(surveyId: viewModel.surveyId, repository: repository) { submitted in
                isAnswering = false
                if submitted {
                    // Like popUpTo(Main): back to the tab's first screen.
                    router.popToRoot()
                }
            }
        }
        .task {
            if viewModel.survey == nil {
                await viewModel.load()
            }
        }
    }

    private func content(_ survey: Survey) -> some View {
        let questions = survey.questions ?? []
        let typeCounts = Dictionary(grouping: questions, by: \.questionType).mapValues(\.count)

        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(survey.categoryName.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Text(survey.title)
                        .font(.title.bold())
                        .foregroundStyle(Color.appOnSurface)
                    Text(survey.description)
                        .font(.body)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }

                HStack(spacing: 12) {
                    InfoTile(systemImage: "clock", value: "\(survey.minutes) min", label: "to complete")
                    InfoTile(systemImage: "questionmark.circle", value: "\(questions.count)", label: questions.count == 1 ? "question" : "questions")
                    InfoTile(systemImage: "star.circle", value: "+\(survey.pointsPerAnswer.pointsText)", label: "points", accent: .brandGold)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Spots filling up")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(pluralize(survey.spotsLeft, "spot")) left")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                    ProgressView(value: survey.progress)
                        .tint(Color.brandPrimary)
                    Text("Points are paid to the first \(survey.expectedAnswerCounts) people who finish.")
                        .font(.caption)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
                .padding(Spacing.md)
                .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))

                if !typeCounts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What to expect")
                            .font(.headline)
                        ForEach(QuestionType.allCases) { type in
                            if let count = typeCounts[type] {
                                Label(pluralize(count, type.noun), systemImage: type.systemImage)
                                    .font(.body)
                                    .foregroundStyle(Color.appOnSurface)
                            }
                        }
                        Text("Every question needs an answer before you can submit.")
                            .font(.caption)
                            .foregroundStyle(Color.appOnSurfaceVariant)
                    }
                }
            }
            .padding(20)
        }
    }
}

private struct InfoTile: View {
    let systemImage: String
    let value: String
    let label: String
    var accent: Color = .brandPrimary

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(accent)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.appOnSurface)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.appOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))
        .accessibilityElement(children: .combine)
    }
}

private extension QuestionType {
    var noun: String {
        switch self {
        case .multipleChoice: "multiple-choice question"
        case .rating: "star rating"
        case .textInput: "written answer"
        }
    }
}

#Preview {
    let container = AppContainer.preview()
    NavigationStack {
        SurveyInfoView(surveyId: 1, repository: container.respondentRepository)
    }
    .environment(Router())
}
