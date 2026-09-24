import SwiftUI

/// Screens you can push while signed out.
enum AuthRoute: Hashable {
    case register
}

/// Login ⇄ Register. `NavigationStack(path:)` is SwiftUI's NavHost: pushing
/// onto `path` navigates, removing pops.
struct AuthFlowView: View {
    let repository: any AuthRepository
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(repository: repository) {
                path.append(.register)
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .register:
                    RegisterView(repository: repository) {
                        path.removeAll()
                    }
                }
            }
        }
    }
}
