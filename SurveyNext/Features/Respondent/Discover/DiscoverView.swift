import SwiftUI

/// Surveys matched to your region, plus your saved list.
/// Equivalent of `DiscoverScreen`.
struct DiscoverView: View {
    let model: DiscoverViewModel

    @Environment(DataChangeNotifier.self) private var notifier

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            Picker("List", selection: $model.showingSaved) {
                Text("Available").tag(false)
                Text("Saved \(model.savedIds.count)/\(maxSavedSurveys)").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Group {
                if model.showingSaved {
                    savedList
                } else {
                    availableList
                }
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color.appBackground)
        .navigationTitle("Discover")
        .toast($model.message)
        .task(id: notifier.version) {
            await model.load(version: notifier.version)
        }
    }

    @ViewBuilder
    private var availableList: some View {
        let list = model.available
        if list.items.isEmpty {
            if list.isInitialLoading {
                LoadingView()
            } else if let error = list.error {
                ErrorStateView(message: error, retry: list.retry)
            } else {
                ScrollView {
                    EmptyStateView(
                        systemImage: "binoculars",
                        title: "No surveys right now",
                        message: "Surveys are matched to your country and region. Check back soon."
                    )
                }
                .refreshable { await model.refresh() }
            }
        } else {
            surveyList(list.items) {
                PagingFooter(list: list)
            }
        }
    }

    @ViewBuilder
    private var savedList: some View {
        switch model.saved {
        case .loading:
            LoadingView()
        case .failed(let message):
            ErrorStateView(message: message, retry: model.retrySaved)
        case .loaded(let surveys) where surveys.isEmpty:
            ScrollView {
                EmptyStateView(
                    systemImage: "bookmark",
                    title: "Nothing saved",
                    message: "Bookmark up to \(maxSavedSurveys) surveys to answer later."
                )
            }
            .refreshable { await model.refresh() }
        case .loaded(let surveys):
            surveyList(surveys) { EmptyView() }
        }
    }

    private func surveyList<Footer: View>(_ surveys: [Survey], @ViewBuilder footer: () -> Footer) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(surveys) { survey in
                    NavigationLink(value: Route.surveyInfo(id: survey.id)) {
                        SurveyCard(survey: survey, footer: "\(pluralize(survey.spotsLeft, "spot")) left") {
                            // Room for the bookmark, which sits on top so its tap doesn't open the survey.
                            Color.clear.frame(width: 28, height: 28)
                        }
                    }
                    .buttonStyle(CardButtonStyle())
                    .overlay(alignment: .topTrailing) {
                        bookmark(for: survey)
                            .padding(10)
                    }
                }
                footer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .refreshable { await model.refresh() }
    }

    private func bookmark(for survey: Survey) -> some View {
        let isSaved = model.savedIds.contains(survey.id)
        return Button {
            Task { await model.toggleSaved(survey) }
        } label: {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.title3)
                .foregroundStyle(isSaved ? Color.brandPrimary : Color.appOnSurfaceVariant)
                .frame(width: 36, height: 36)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Remove from saved" : "Save for later")
    }
}

#Preview {
    let container = AppContainer.preview()
    NavigationStack {
        DiscoverView(model: DiscoverViewModel(repository: container.respondentRepository))
    }
    .environment(container.notifier)
}
