import SwiftUI
import Observation

enum AppTab: Hashable {
    case home, surveys, discover, history, account
}

/// Screens you can push inside a tab. Equivalent of the `Screen` routes on Android.
/// `RouteView` turns each one into its view.
enum Route: Hashable {
    case manageSurvey(id: Int)
    case analytics(surveyId: Int)
    case surveyInfo(id: Int)
    case answerDetails(surveyId: Int)
}

/// Navigation state of the signed-in app: the selected tab and each tab's
/// back stack. Each tab keeps its own stack, so switching tabs doesn't lose
/// your place (the iOS convention).
///
/// `NavigationLink(value: Route…)` pushes onto the current tab by itself;
/// use `push` only for navigation in code, e.g. after creating a survey.
@Observable
final class Router {
    var selectedTab: AppTab = .home
    var isCreatingSurvey = false
    private var paths: [AppTab: [Route]] = [:]

    func path(for tab: AppTab) -> Binding<[Route]> {
        Binding(
            get: { self.paths[tab] ?? [] },
            set: { self.paths[tab] = $0 }
        )
    }

    func push(_ route: Route) {
        paths[selectedTab, default: []].append(route)
    }

    func popToRoot() {
        paths[selectedTab] = []
    }
}

/// Builds the screen for a `Route`, in one place like `AppNavHost`.
struct RouteView: View {
    let route: Route
    @Environment(AppContainer.self) private var container

    var body: some View {
        switch route {
        case .manageSurvey(let id):
            ManageSurveyView(surveyId: id, repository: container.interviewerRepository, session: container.session)
        case .analytics(let surveyId):
            AnalyticsView(surveyId: surveyId, repository: container.interviewerRepository)
        case .surveyInfo(let id):
            SurveyInfoView(surveyId: id, repository: container.respondentRepository)
        case .answerDetails(let surveyId):
            AnswerDetailsView(surveyId: surveyId, repository: container.respondentRepository)
        }
    }
}
