import SwiftUI

/// The signed-in app: a tab bar whose tabs depend on the role.
/// Equivalent of `MainScreen` on Android.
///
/// - Interviewer: Home, Surveys, Account
/// - Respondent: Home, Discover, History, Account
/// - Admin: Account only (administration isn't in the app)
struct MainTabView: View {
    let user: User
    let container: AppContainer

    @State private var router = Router()
    // Owned here rather than by their tabs so Home's stat cards can preset
    // their filters, like the shared hiltViewModel() on Android.
    @State private var surveysModel: InterviewerSurveysViewModel
    @State private var discoverModel: DiscoverViewModel

    init(user: User, container: AppContainer) {
        self.user = user
        self.container = container
        _surveysModel = State(initialValue: InterviewerSurveysViewModel(repository: container.interviewerRepository))
        _discoverModel = State(initialValue: DiscoverViewModel(repository: container.respondentRepository))
    }

    var body: some View {
        @Bindable var router = router

        Group {
            if user.role == .admin {
                NavigationStack {
                    ProfileView()
                }
            } else {
                TabView(selection: $router.selectedTab) {
                    tabStack(.home) { home }
                        .tabItem { Label("Home", systemImage: "house") }
                        .tag(AppTab.home)

                    if user.role == .interviewer {
                        tabStack(.surveys) { InterviewerSurveysView(model: surveysModel) }
                            .tabItem { Label("Surveys", systemImage: "list.bullet.clipboard") }
                            .tag(AppTab.surveys)
                    } else {
                        tabStack(.discover) { DiscoverView(model: discoverModel) }
                            .tabItem { Label("Discover", systemImage: "safari") }
                            .tag(AppTab.discover)
                        tabStack(.history) { HistoryView(repository: container.respondentRepository) }
                            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                            .tag(AppTab.history)
                    }

                    tabStack(.account) { ProfileView() }
                        .tabItem { Label("Account", systemImage: "person.crop.circle") }
                        .tag(AppTab.account)
                }
            }
        }
        .environment(router)
        .sheet(isPresented: $router.isCreatingSurvey) {
            CreateSurveyView(repository: container.interviewerRepository, session: container.session) { surveyId in
                router.isCreatingSurvey = false
                router.push(.manageSurvey(id: surveyId))
            }
        }
        .task(id: container.notifier.version) {
            // Points move whenever surveys are published or answered.
            _ = try? await container.authRepository.refreshUser()
        }
    }

    @ViewBuilder
    private var home: some View {
        if user.role == .interviewer {
            InterviewerHomeView(userName: user.name, repository: container.interviewerRepository) { state in
                surveysModel.selectFilter(state)
                router.selectedTab = .surveys
            }
        } else {
            RespondentHomeView(
                userName: user.name,
                repository: container.respondentRepository,
                onOpenDiscover: { showSaved in
                    discoverModel.showingSaved = showSaved
                    router.selectedTab = .discover
                },
                onOpenHistory: { router.selectedTab = .history }
            )
        }
    }

    private func tabStack<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: router.path(for: tab)) {
            content()
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route)
                }
        }
    }
}

#Preview("Interviewer") {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    MainTabView(user: PreviewAuthRepository.interviewer, container: container)
        .environment(container)
        .environment(container.notifier)
}

#Preview("Respondent") {
    let container = AppContainer.preview()
    MainTabView(user: PreviewAuthRepository.user, container: container)
        .environment(container)
        .environment(container.notifier)
}
