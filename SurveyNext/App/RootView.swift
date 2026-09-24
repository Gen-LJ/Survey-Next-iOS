import SwiftUI

/// Chooses the screen tree from the session, like `AppNavHost`'s start
/// destination. Because it reads `session.user`, logging in, logging out, or
/// a 401 swaps the screen automatically; no `popUpTo(0)` needed.
struct RootView: View {
    let container: AppContainer

    var body: some View {
        Group {
            if let user = container.session.user {
                MainTabView(user: user, container: container)
                    .transition(.opacity)
            } else {
                AuthFlowView(repository: container.authRepository)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: container.session.isLoggedIn)
        .tint(.brandPrimary)
        // Any screen can now read these with @Environment(AppContainer.self) etc.
        .environment(container)
        .environment(container.session)
        .environment(container.notifier)
    }
}
