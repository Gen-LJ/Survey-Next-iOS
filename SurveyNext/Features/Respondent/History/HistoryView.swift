import SwiftUI

/// Surveys you've answered, and what they paid. Equivalent of `HistoryScreen`.
struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @Environment(DataChangeNotifier.self) private var notifier

    init(repository: any RespondentRepository) {
        _viewModel = State(initialValue: HistoryViewModel(repository: repository))
    }

    var body: some View {
        let list = viewModel.list

        Group {
            if list.items.isEmpty {
                if list.isInitialLoading {
                    LoadingView()
                } else if let error = list.error {
                    ErrorStateView(message: error, retry: list.retry)
                } else {
                    ScrollView {
                        EmptyStateView(
                            systemImage: "clock.arrow.circlepath",
                            title: "No answers yet",
                            message: "Surveys you complete, and the points they earned you, show up here."
                        )
                    }
                    .refreshable { await list.reload() }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Surveys you've answered")
                            .font(.subheadline)
                            .foregroundStyle(Color.appOnSurfaceVariant)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(list.items) { survey in
                            NavigationLink(value: Route.answerDetails(surveyId: survey.id)) {
                                SurveyCard(
                                    survey: survey,
                                    footer: "Answered \(DateText.relative(survey.answeredAt)) · +\(survey.pointsPerAnswer.pointsText) pts"
                                )
                            }
                            .buttonStyle(CardButtonStyle())
                        }
                        PagingFooter(list: list)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                }
                .refreshable { await list.reload() }
            }
        }
        .background(Color.appBackground)
        .navigationTitle("History")
        .task(id: notifier.version) {
            await viewModel.load(version: notifier.version)
        }
    }
}

#Preview {
    let container = AppContainer.preview()
    NavigationStack {
        HistoryView(repository: container.respondentRepository)
    }
    .environment(container.notifier)
}
