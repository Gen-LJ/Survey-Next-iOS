import Foundation
import Observation

/// A ready-made view model for screens that show the result of one request
/// (dashboards, analytics, details). Screens with more going on have their
/// own view model class.
///
/// Usage in a view:
/// ```
/// @State private var home = Loader { try await repository.home() }
/// …
/// .task(id: notifier.version) { await home.load(version: notifier.version) }
/// .refreshable { await home.refresh() }
/// ```
@Observable
final class Loader<Value> {
    private(set) var state: LoadState<Value> = .loading

    @ObservationIgnored private var loadedVersion: Int?
    @ObservationIgnored private let fetch: @MainActor () async throws -> Value

    init(fetch: @escaping @MainActor () async throws -> Value) {
        self.fetch = fetch
    }

    var value: Value? { state.value }

    /// Loads unless this data version was already loaded. Pass the
    /// `DataChangeNotifier` version to reload after writes elsewhere.
    func load(version: Int = 0) async {
        guard version != loadedVersion else { return }
        if await run() {
            loadedVersion = version
        }
    }

    /// Pull-to-refresh: keeps the current content on screen while it loads.
    func refresh() async {
        await run()
    }

    /// After an error: shows the spinner again and retries.
    func retry() async {
        state = .loading
        await run()
    }

    @discardableResult
    private func run() async -> Bool {
        do {
            state = .loaded(try await fetch())
            return true
        } catch is CancellationError {
            return false
        } catch {
            // Keep showing stale data if a background reload fails.
            if state.value == nil {
                state = .failed(error.localizedDescription)
            }
            return false
        }
    }
}
