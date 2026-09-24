import SwiftUI

/// Respondent dashboard: points, counts, and new surveys for your region.
/// Equivalent of `RespondentHomeScreen`.
struct RespondentHomeView: View {
    let userName: String
    /// Opens Discover, on the Saved list when true.
    let onOpenDiscover: (_ showSaved: Bool) -> Void
    let onOpenHistory: () -> Void

    @State private var home: Loader<RespondentHome>
    @Environment(DataChangeNotifier.self) private var notifier

    init(
        userName: String,
        repository: any RespondentRepository,
        onOpenDiscover: @escaping (_ showSaved: Bool) -> Void,
        onOpenHistory: @escaping () -> Void
    ) {
        self.userName = userName
        self.onOpenDiscover = onOpenDiscover
        self.onOpenHistory = onOpenHistory
        _home = State(initialValue: Loader { try await repository.home() })
    }

    var body: some View {
        LoadStateView(state: home.state, retry: home.retry) { data in
            content(data)
        }
        .background(Color.appBackground)
        .navigationTitle("Hi, \(userName.firstName)")
        .task(id: notifier.version) {
            await home.load(version: notifier.version)
        }
    }

    private func content(_ data: RespondentHome) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("Share your opinion, earn points")
                    .font(.subheadline)
                    .foregroundStyle(Color.appOnSurfaceVariant)

                PointsCard(
                    label: "Points earned",
                    points: data.points,
                    caption: "\(pluralize(data.answeredCount, "survey")) completed so far"
                )

                HStack(spacing: 12) {
                    StatCard(systemImage: "safari", value: "\(data.availableCount)", label: "Available") {
                        onOpenDiscover(false)
                    }
                    StatCard(systemImage: "checkmark.seal", value: "\(data.answeredCount)", label: "Completed", accent: .brandSecondary) {
                        onOpenHistory()
                    }
                    StatCard(systemImage: "bookmark", value: "\(data.savedCount)/\(maxSavedSurveys)", label: "Saved", accent: .brandGold) {
                        onOpenDiscover(true)
                    }
                }

                if data.recentSurveys.isEmpty {
                    EmptyStateView(
                        systemImage: "tray",
                        title: "You're all caught up",
                        message: "New surveys for your region will appear here. Pull down to check again."
                    )
                } else {
                    SectionHeader(title: "New for you", actionLabel: "See all") { onOpenDiscover(false) }
                    ForEach(data.recentSurveys) { survey in
                        NavigationLink(value: Route.surveyInfo(id: survey.id)) {
                            SurveyCard(survey: survey, footer: "\(pluralize(survey.spotsLeft, "spot")) left")
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .refreshable { await home.refresh() }
    }
}

#Preview {
    let container = AppContainer.preview()
    NavigationStack {
        RespondentHomeView(userName: "Ray Moe", repository: container.respondentRepository, onOpenDiscover: { _ in }, onOpenHistory: {})
    }
    .environment(container.notifier)
}
