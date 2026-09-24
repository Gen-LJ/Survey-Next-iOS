import SwiftUI

/// Your own answers to a survey you completed. Equivalent of `AnswerDetailsScreen`.
struct AnswerDetailsView: View {
    @State private var details: Loader<AnswerDetails>

    init(surveyId: Int, repository: any RespondentRepository) {
        _details = State(initialValue: Loader { try await repository.answerDetails(surveyId: surveyId) })
    }

    var body: some View {
        LoadStateView(state: details.state, retry: details.retry) { data in
            content(data)
        }
        .background(Color.appBackground)
        .navigationTitle("Your answers")
        .navigationBarTitleDisplayMode(.inline)
        .task { await details.load() }
    }

    private func content(_ data: AnswerDetails) -> some View {
        let survey = data.survey
        let responses = Dictionary(data.answer.userAnswers.map { ($0.questionId, $0.responses) }, uniquingKeysWith: { first, _ in first })

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(survey.categoryName.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Text(survey.title)
                        .font(.title2.bold())
                        .foregroundStyle(Color.appOnSurface)
                    HStack(spacing: Spacing.sm) {
                        Text("Answered \(DateText.medium(data.answer.answeredAt))")
                            .font(.subheadline)
                            .foregroundStyle(Color.appOnSurfaceVariant)
                        Label("+\(data.answer.pointsEarned.pointsText) pts", systemImage: "star.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandOnGoldContainer)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.brandGoldContainer, in: .capsule)
                    }
                }
                .padding(.bottom, Spacing.xs)

                ForEach(Array(survey.sortedQuestions.enumerated()), id: \.element.id) { index, question in
                    AnsweredQuestionCard(number: index + 1, question: question, responses: responses[question.id] ?? [])
                }
            }
            .padding(Spacing.md)
        }
        .refreshable { await details.refresh() }
    }
}

private struct AnsweredQuestionCard: View {
    let number: Int
    let question: Question
    let responses: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Q\(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appOnSurfaceVariant)
            Text(question.text)
                .font(.headline)
                .foregroundStyle(Color.appOnSurface)

            switch question.questionType {
            case .multipleChoice:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(question.sortedOptions) { option in
                        let picked = responses.contains(option.text)
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(picked ? Color.brandPrimary : Color.appOutlineVariant)
                            Text(option.text)
                                .font(.body)
                                .foregroundStyle(picked ? Color.appOnSurface : Color.appOnSurfaceVariant)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(picked ? .isSelected : [])
                    }
                }
            case .rating:
                let rating = Int(responses.first ?? "") ?? 0
                HStack(spacing: 12) {
                    RatingStars(rating: rating, size: 26)
                    Text(ratingLabel(rating))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appOnSurface)
                }
            case .textInput:
                Text(responses.first ?? "")
                    .font(.body)
                    .foregroundStyle(Color.appOnSurface)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSurfaceHigh, in: .rect(cornerRadius: Radius.small))
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))
    }
}

#Preview {
    let container = AppContainer.preview()
    NavigationStack {
        AnswerDetailsView(surveyId: 4, repository: container.respondentRepository)
    }
}
