import Foundation

/// App-wide settings. Equivalent of `NetworkModule.BASE_URL` on Android.
enum AppConfig {
    /// The hosted backend. It sleeps when idle, so the first request can take ~30s.
    static let baseURL: URL = {
        #if DEBUG
        // Debug builds can point at another server without a code change:
        // Product ▸ Scheme ▸ Edit Scheme… ▸ Run ▸ Arguments ▸ Environment Variables,
        // add SURVEYNEXT_API_URL = http://localhost:8080
        if let override = ProcessInfo.processInfo.environment["SURVEYNEXT_API_URL"],
           let url = URL(string: override) {
            return url
        }
        #endif
        return URL(string: "https://survey-backend-2934.onrender.com")!
    }()

    // The Simulator shares the Mac's network, so a Go server on your Mac is
    // reachable at plain localhost (no 10.0.2.2 like the Android emulator).

    /// Generous because of the cold start above.
    static let requestTimeout: TimeInterval = 60
}
