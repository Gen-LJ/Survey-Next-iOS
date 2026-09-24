import SwiftUI

/// Interviewer dashboard: balance, counts by state, recent surveys.
/// Equivalent of `InterviewerHomeScreen`.
struct InterviewerHomeView: View {
    let userName: String
    /// Opens the Surveys tab filtered to a state (nil = all).
    let onOpenSurveys: (SurveyState?) -> Void

    @State private var home: Loader<InterviewerHome>
    @Environment(Router.self) private var router
    @Environment(DataChangeNotifier.self) private var notifier

    init(userName: String, repository: any InterviewerRepository, onOpenSurveys: @escaping (SurveyState?) -> Void) {
        self.userName = userName
        self.onOpenSurveys = onOpenSurveys
        _home = State(initialValue: Loader { try await repository.home() })
    }

    var body: some View {
        LoadStateView(state: home.state, retry: home.retry) { data in
            content(data)
        }
        .background(Color.appBackground)
        .navigationTitle("Hi, \(userName.firstName)")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.isCreatingSurvey = true
                } label: {
                    Label("New survey", systemImage: "plus")
                }
            }
        }
        .task(id: notifier.version) {
            await home.load(version: notifier.version)
        }
    }

    private func content(_ data: InterviewerHome) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("Here's how your surveys are doing")
                    .font(.subheadline)
                    .foregroundStyle(Color.appOnSurfaceVariant)

                PointsCard(
                    label: "Available balance",
                    points: data.points,
                    caption: "Publishing a survey reserves its reward pool from this balance"
                )

                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        stat(.draft, count: data.draftCount, systemImage: "square.and.pencil", label: "Drafts")
                        stat(.published, count: data.publishedCount, systemImage: "play.circle", label: "Live")
                    }
                    GridRow {
                        stat(.paused, count: data.pausedCount, systemImage: "pause.circle", label: "Paused")
                        stat(.completed, count: data.completedCount, systemImage: "checkmark.circle", label: "Completed")
                    }
                }

                if !data.hasSurveys {
                    EmptyStateView(
                        systemImage: "doc.badge.plus",
                        title: "Create your first survey",
                        message: "Draft your questions, set a reward, and publish to respondents in your target region."
                    ) {
                        Button("Start a survey") { router.isCreatingSurvey = true }
                            .buttonStyle(.borderedProminent)
                    }
                }

                if !data.recentPublished.isEmpty {
                    SectionHeader(title: "Live now", actionLabel: "See all") { onOpenSurveys(.published) }
                    ForEach(rows(data.recentPublished, section: "live")) { row in
                        surveyLink(row.survey)
                    }
                }

                if !data.recentDrafts.isEmpty {
                    SectionHeader(title: "Recent drafts", actionLabel: "See all") { onOpenSurveys(.draft) }
                    ForEach(rows(data.recentDrafts, section: "draft")) { row in
                        surveyLink(row.survey)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .refreshable { await home.refresh() }
    }

    private func stat(_ state: SurveyState, count: Int, systemImage: String, label: String) -> some View {
        StatCard(systemImage: systemImage, value: "\(count)", label: label, accent: state.badgeForeground) {
            onOpenSurveys(state)
        }
    }

    /// Row ids per section ("live-4", "draft-4"), like the Android keys. A lazy
    /// stack tracks rows by id across the whole stack, so without the prefix a
    /// survey that moves from Recent drafts to Live now keeps its old card.
    private func rows(_ surveys: [Survey], section: String) -> [SectionRow] {
        surveys.map { SectionRow(id: "\(section)-\($0.id)", survey: $0) }
    }

    private struct SectionRow: Identifiable {
        let id: String
        let survey: Survey
    }

    private func surveyLink(_ survey: Survey) -> some View {
        NavigationLink(value: Route.manageSurvey(id: survey.id)) {
            SurveyCard(survey: survey, showState: true)
        }
        .buttonStyle(CardButtonStyle())
    }
}

#Preview {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    NavigationStack {
        InterviewerHomeView(userName: "Iva Tun", repository: container.interviewerRepository) { _ in }
    }
    .environment(Router())
    .environment(container.notifier)
}
