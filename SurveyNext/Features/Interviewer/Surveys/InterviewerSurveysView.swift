import SwiftUI

/// All of the interviewer's surveys, filterable by state, loaded page by page.
/// Equivalent of `InterviewerSurveysScreen`.
struct InterviewerSurveysView: View {
    let model: InterviewerSurveysViewModel

    @Environment(Router.self) private var router
    @Environment(DataChangeNotifier.self) private var notifier

    private let filters: [SurveyState?] = [nil] + SurveyState.allCases

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            listContent
                .frame(maxHeight: .infinity)
        }
        .background(Color.appBackground)
        .navigationTitle("My surveys")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.isCreatingSurvey = true
                } label: {
                    Label("New survey", systemImage: "plus")
                }
            }
        }
        .task(id: LoadKey(version: notifier.version, filter: model.filter)) {
            await model.load(version: notifier.version)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(filters, id: \.self) { state in
                    let isSelected = model.filter == state
                    Button {
                        model.selectFilter(state)
                    } label: {
                        Text(state?.label ?? "All")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? Color.brandOnPrimaryContainer : Color.appOnSurfaceVariant)
                            .background(isSelected ? Color.brandPrimaryContainer : Color.clear, in: .capsule)
                            .overlay {
                                Capsule().stroke(isSelected ? Color.clear : Color.appOutlineVariant)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    @ViewBuilder
    private var listContent: some View {
        let list = model.list
        if list.items.isEmpty {
            if list.isInitialLoading {
                LoadingView()
            } else if let error = list.error {
                ErrorStateView(message: error, retry: list.retry)
            } else {
                ScrollView {
                    EmptyStateView(
                        systemImage: "list.bullet.clipboard",
                        title: model.filter.map { "Nothing \($0.label.lowercased())" } ?? "No surveys yet",
                        message: model.filter == nil
                            ? "Tap + to draft your first survey."
                            : "Surveys will show up here as they move through their lifecycle."
                    )
                }
                .refreshable { await list.reload() }
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(list.items) { survey in
                        NavigationLink(value: Route.manageSurvey(id: survey.id)) {
                            SurveyCard(survey: survey, showState: true)
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

    private struct LoadKey: Hashable {
        let version: Int
        let filter: SurveyState?
    }
}

#Preview {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    NavigationStack {
        InterviewerSurveysView(model: InterviewerSurveysViewModel(repository: container.interviewerRepository))
    }
    .environment(Router())
    .environment(container.notifier)
}
