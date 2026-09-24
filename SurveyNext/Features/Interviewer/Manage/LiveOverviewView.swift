import SwiftUI

/// A survey that is live, paused or completed: read-only, with progress and
/// controls. Equivalent of `LiveOverview`.
struct LiveOverviewView: View {
    let survey: Survey
    let viewModel: ManageSurveyViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    StateBadge(state: survey.state)
                    Text(survey.title)
                        .font(.title2.bold())
                        .foregroundStyle(Color.appOnSurface)
                    Text(survey.description)
                        .font(.body)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                    Text("\(survey.categoryName) · \(survey.minutes) min · published \(DateText.medium(survey.publishedAt))")
                        .font(.caption)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }

                ProgressCard(survey: survey)

                VStack(spacing: Spacing.sm) {
                    NavigationLink(value: Route.analytics(surveyId: survey.id)) {
                        Label("View responses", systemImage: "chart.bar.fill")
                    }
                    .buttonStyle(FilledButtonStyle())

                    switch survey.state {
                    case .published:
                        Button {
                            Task { await viewModel.setPaused(true) }
                        } label: {
                            Label("Pause survey", systemImage: "pause.fill")
                        }
                        .buttonStyle(FilledButtonStyle(tonal: true))
                        .disabled(viewModel.isBusy)
                    case .paused:
                        Button {
                            Task { await viewModel.setPaused(false) }
                        } label: {
                            Label("Resume survey", systemImage: "play.fill")
                        }
                        .buttonStyle(FilledButtonStyle(tonal: true))
                        .disabled(viewModel.isBusy)
                    default:
                        EmptyView()
                    }
                }

                SectionHeader(title: "Questions")
                ForEach(Array(survey.sortedQuestions.enumerated()), id: \.element.id) { index, question in
                    QuestionCard(number: index + 1, question: question)
                }
            }
            .padding(Spacing.md)
        }
        .refreshable { await viewModel.load() }
    }
}

/// Response ring plus the reward numbers.
private struct ProgressCard: View {
    let survey: Survey

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.appSurfaceHighest, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: survey.progress)
                    .stroke(Color.brandPrimary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: survey.progress)
                VStack(spacing: 0) {
                    Text("\(survey.answerCount)")
                        .font(.title.bold())
                        .foregroundStyle(Color.appOnSurface)
                    Text("of \(survey.expectedAnswerCounts)")
                        .font(.caption)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
            }
            .frame(width: 112, height: 112)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(survey.answerCount) of \(survey.expectedAnswerCounts) responses")

            VStack(alignment: .leading, spacing: 12) {
                metric("Reward per response", "\(survey.pointsPerAnswer.pointsText) pts")
                metric("Paid out", "\((survey.totalPoints - survey.pendingPoints).pointsText) pts")
                metric("Left in pool", "\(survey.pendingPoints.pointsText) pts")
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.appOnSurfaceVariant)
            Text(value)
                .font(.headline)
                .foregroundStyle(Color.appOnSurface)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    let viewModel = ManageSurveyViewModel(surveyId: 1, repository: container.interviewerRepository, session: container.session)
    NavigationStack {
        LiveOverviewView(survey: .sample(), viewModel: viewModel)
    }
}
