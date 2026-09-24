import Foundation
import Observation

/// A list filled page by page as the user scrolls.
/// Equivalent of `PagedList` + the load-more logic in the Android view models.
@Observable
final class PagedList<Item: Identifiable & Decodable> {
    static var pageSize: Int { 10 }

    private(set) var items: [Item] = []
    private(set) var hasNext = false
    private(set) var hasLoaded = false
    private(set) var isLoadingMore = false
    /// Last failure; the list keeps its items and shows a retry row.
    private(set) var error: String?

    @ObservationIgnored private var page = 0
    /// Bumped by `reload()` so an older in-flight request can't overwrite newer results.
    @ObservationIgnored private var generation = 0
    // Explicitly @MainActor: with Xcode 26's "Approachable Concurrency", a stored
    // async closure with parameters is otherwise called with garbage arguments
    // (a Swift 6.2 miscompile). The same applies to other stored async closures.
    @ObservationIgnored private let fetch: @MainActor (_ page: Int, _ limit: Int) async throws -> Page<Item>

    init(fetch: @escaping @MainActor (_ page: Int, _ limit: Int) async throws -> Page<Item>) {
        self.fetch = fetch
    }

    /// Nothing to show yet and nothing went wrong: show a spinner.
    var isInitialLoading: Bool { !hasLoaded && error == nil }

    /// Loads the first page again. Current items stay on screen until it arrives.
    func reload() async {
        generation += 1
        let current = generation
        isLoadingMore = false
        error = nil
        do {
            let result = try await fetch(1, Self.pageSize)
            guard current == generation else { return }
            items = result.items
            page = 1
            hasNext = result.meta.hasNext
            hasLoaded = true
        } catch is CancellationError {
        } catch {
            guard current == generation else { return }
            self.error = error.localizedDescription
        }
    }

    /// Call when the end of the list scrolls into view.
    func loadMore() async {
        guard hasLoaded, hasNext, !isLoadingMore, error == nil else { return }
        let current = generation
        isLoadingMore = true
        do {
            let result = try await fetch(page + 1, Self.pageSize)
            guard current == generation else { return }
            let known = Set(items.map(\.id))
            items += result.items.filter { !known.contains($0.id) }
            page += 1
            hasNext = result.meta.hasNext
        } catch is CancellationError {
        } catch {
            if current == generation {
                self.error = error.localizedDescription
            }
        }
        if current == generation {
            isLoadingMore = false
        }
    }

    func retry() async {
        error = nil
        if hasLoaded {
            await loadMore()
        } else {
            await reload()
        }
    }
}
