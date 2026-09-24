import SwiftUI

/// Response summary per question. Equivalent of `AnalyticsScreen`.
struct AnalyticsView: View {
    @State private var analytics: Loader<Analytics>

    init(surveyId: Int, repository: any InterviewerRepository) {
        _analytics = State(initialValue: Loader { try await repository.analytics(surveyId: surveyId) })
    }

    var body: some View {
        LoadStateView(state: analytics.state, loadingMessage: "Crunching responses…", retry: analytics.retry) { data in
            content(data)
        }
        .background(Color.appBackground)
        .navigationTitle("Responses")
        .navigationBarTitleDisplayMode(.inline)
        .task { await analytics.load() }
    }

    private func content(_ data: Analytics) -> some View {
        let survey = data.survey
        let completion = survey.expectedAnswerCounts == 0
            ? 0
            : Int((Double(data.answerTotal) * 100 / Double(survey.expectedAnswerCounts)).rounded())

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    StateBadge(state: survey.state)
                    Text(survey.title)
                        .font(.title2.bold())
                        .foregroundStyle(Color.appOnSurface)
                }

                HStack(spacing: 12) {
                    StatCard(systemImage: "person.3.fill", value: "\(data.answerTotal)", label: "Responses")
                    StatCard(systemImage: "percent", value: "\(completion)%", label: "Of target", accent: .brandSecondary)
                    StatCard(
                        systemImage: "star.circle.fill",
                        value: (data.answerTotal * survey.pointsPerAnswer).pointsText,
                        label: "Points paid",
                        accent: .brandGold
                    )
                }

                if data.answerTotal == 0 {
                    EmptyStateView(
                        systemImage: "chart.bar.xaxis",
                        title: "No responses yet",
                        message: "Results appear here as respondents in your target region answer. Pull down to refresh."
                    )
                } else {
                    ForEach(Array(data.summary.enumerated()), id: \.element.id) { index, summary in
                        QuestionSummaryCard(number: index + 1, summary: summary)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .refreshable { await analytics.refresh() }
    }
}

private struct QuestionSummaryCard: View {
    let number: Int
    let summary: QuestionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                "Q\(number) · \(summary.questionType.label) · \(summary.responseCount) answered",
                systemImage: summary.questionType.systemImage
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.appOnSurfaceVariant)

            Text(summary.text)
                .font(.headline)
                .foregroundStyle(Color.appOnSurface)

            switch summary.questionType {
            case .multipleChoice:
                ChoiceBreakdown(summary: summary)
            case .rating:
                RatingBreakdown(summary: summary)
            case .textInput:
                TextResponses(responses: summary.textResponses ?? [])
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))
    }
}

private struct ChoiceBreakdown: View {
    let summary: QuestionSummary

    var body: some View {
        let counts = summary.optionCounts ?? []
        // Multi-select questions can total more picks than respondents; percentages are per respondent.
        let base = Double(max(summary.responseCount, 1))
        let top = counts.map(\.count).max() ?? 0

        VStack(spacing: 10) {
            ForEach(counts, id: \.option) { option in
                let share = Double(option.count) / base
                let isTop = option.count == top && top > 0
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.option)
                            .font(.subheadline)
                            .foregroundStyle(Color.appOnSurface)
                        Spacer()
                        Text("\(Int((share * 100).rounded()))% · \(option.count)")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color.appOnSurfaceVariant)
                    }
                    BarTrack(fraction: share, color: isTop ? .brandPrimary : .brandPrimary.opacity(0.45))
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct RatingBreakdown: View {
    let summary: QuestionSummary

    var body: some View {
        let buckets = summary.ratingCounts ?? []
        let total = Double(max(buckets.reduce(0, +), 1))
        let average = summary.averageRating ?? 0

        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(average.formatted(.number.precision(.fractionLength(1))))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appOnSurface)
                RatingStars(rating: Int(average.rounded()), size: 16)
                Text("average")
                    .font(.caption)
                    .foregroundStyle(Color.appOnSurfaceVariant)
            }

            VStack(spacing: 6) {
                ForEach((1...5).reversed(), id: \.self) { stars in
                    let count = buckets.indices.contains(stars - 1) ? buckets[stars - 1] : 0
                    HStack(spacing: Spacing.sm) {
                        Text("\(stars)")
                            .font(.caption.weight(.semibold))
                            .frame(width: 12)
                        BarTrack(fraction: Double(count) / total, color: .brandGold, height: 8)
                        Text("\(count)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Color.appOnSurfaceVariant)
                            .frame(width: 28, alignment: .trailing)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(pluralize(stars, "star")): \(count)")
                }
            }
        }
    }
}

private struct TextResponses: View {
    let responses: [String]
    @State private var isExpanded = false

    private let previewCount = 3

    var body: some View {
        let shown = isExpanded ? responses : Array(responses.prefix(previewCount))

        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, text in
                Text("“\(text)”")
                    .font(.subheadline)
                    .foregroundStyle(Color.appOnSurface)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSurfaceHigh, in: .rect(cornerRadius: Radius.small))
            }
            if responses.count > previewCount {
                Button(isExpanded ? "Show less" : "Show all \(responses.count)") {
                    withAnimation { isExpanded.toggle() }
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }
}

#Preview {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    NavigationStack {
        AnalyticsView(surveyId: 1, repository: container.interviewerRepository)
    }
}
