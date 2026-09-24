import Foundation
import Observation

/// Builds the app's long-lived objects once and wires them together.
/// This is what the Hilt modules do on Android, written out by hand.
///
/// It's injected with `.environment(container)`, so any screen can read it with
/// `@Environment(AppContainer.self)`. (`@Observable` is only there to allow
/// that; nothing in here changes.)
@Observable
final class AppContainer {
    let session: SessionStore
    let notifier: DataChangeNotifier
    let authRepository: any AuthRepository
    let interviewerRepository: any InterviewerRepository
    let respondentRepository: any RespondentRepository

    init(
        session: SessionStore,
        notifier: DataChangeNotifier,
        authRepository: any AuthRepository,
        interviewerRepository: any InterviewerRepository,
        respondentRepository: any RespondentRepository
    ) {
        self.session = session
        self.notifier = notifier
        self.authRepository = authRepository
        self.interviewerRepository = interviewerRepository
        self.respondentRepository = respondentRepository
    }

    /// The real app: everything talks to the backend.
    convenience init() {
        let session = SessionStore()
        let notifier = DataChangeNotifier()
        let api = APIClient(session: session)
        self.init(
            session: session,
            notifier: notifier,
            authRepository: DefaultAuthRepository(api: api, session: session),
            interviewerRepository: DefaultInterviewerRepository(api: api, notifier: notifier),
            respondentRepository: DefaultRespondentRepository(api: api, notifier: notifier)
        )
    }
}
