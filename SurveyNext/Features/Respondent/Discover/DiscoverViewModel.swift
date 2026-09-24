import Foundation
import Observation

/// Surveys you can answer, and the ones you saved for later.
/// Equivalent of `DiscoverViewModel`.
@Observable
final class DiscoverViewModel {
    var showingSaved = false
    private(set) var available: PagedList<Survey>
    private(set) var saved: LoadState<[Survey]> = .loading
    private(set) var savedIds: Set<Int> = []
    /// Result of the last save/unsave, shown as a toast.
    var message: String?

    @ObservationIgnored private var pendingToggles: Set<Int> = []
    @ObservationIgnored private var loadedVersion: Int?
    @ObservationIgnored private let repository: any RespondentRepository

    init(repository: any RespondentRepository) {
        self.repository = repository
        self.available = PagedList { page, limit in
            try await repository.availableSurveys(page: page, limit: limit)
        }
    }

    /// Loads both lists unless this data version is already on screen.
    func load(version: Int) async {
        guard version != loadedVersion else { return }
        // Both requests at once.
        async let list: Void = reloadAvailable()
        async let savedLoaded = loadSaved()
        let (_, savedOK) = await (list, savedLoaded)
        if available.hasLoaded, available.error == nil, savedOK {
            loadedVersion = version
        }
    }

    func refresh() async {
        async let list: Void = reloadAvailable()
        async let savedLoaded = loadSaved()
        _ = await (list, savedLoaded)
    }

    func retrySaved() async {
        saved = .loading
        await loadSaved()
    }

    func toggleSaved(_ survey: Survey) async {
        guard !pendingToggles.contains(survey.id) else { return }
        let wasSaved = savedIds.contains(survey.id)
        if !wasSaved && savedIds.count >= maxSavedSurveys {
            message = "You can save up to \(maxSavedSurveys) surveys. Answer or remove one first."
            return
        }

        pendingToggles.insert(survey.id)
        defer { pendingToggles.remove(survey.id) }

        // Optimistic; the change notification then reloads both lists.
        setSaved(survey.id, !wasSaved)
        do {
            if wasSaved {
                try await repository.removeSavedSurvey(id: survey.id)
            } else {
                try await repository.saveSurvey(id: survey.id)
            }
            message = wasSaved ? "Removed from saved" : "Saved for later"
        } catch {
            setSaved(survey.id, wasSaved)
            if !(error is CancellationError) {
                message = error.localizedDescription
            }
        }
    }

    /// A plain method (rather than calling `available.reload()` inside
    /// `async let`) keeps the generic list on the main actor.
    private func reloadAvailable() async {
        await available.reload()
    }

    private func setSaved(_ id: Int, _ isSaved: Bool) {
        if isSaved {
            savedIds.insert(id)
        } else {
            savedIds.remove(id)
        }
    }

    @discardableResult
    private func loadSaved() async -> Bool {
        do {
            let surveys = try await repository.savedSurveys()
            savedIds = Set(surveys.map(\.id))
            saved = .loaded(surveys)
            return true
        } catch is CancellationError {
            return false
        } catch {
            if saved.value == nil {
                saved = .failed(error.localizedDescription)
            }
            return false
        }
    }
}
