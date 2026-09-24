import SwiftUI

/// App entry point, the `MainActivity` + `Application` of iOS.
@main
struct SurveyNextApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
