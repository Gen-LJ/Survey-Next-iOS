import Foundation
import Observation

/// Surveys you've answered, page by page. Equivalent of `HistoryViewModel`.
@Observable
final class HistoryViewModel {
    let list: PagedList<Survey>
    @ObservationIgnored private var loadedVersion: Int?

    init(repository: any RespondentRepository) {
        list = PagedList { page, limit in
            try await repository.completedSurveys(page: page, limit: limit)
        }
    }

    func load(version: Int) async {
        guard version != loadedVersion else { return }
        await list.reload()
        if list.hasLoaded, list.error == nil {
            loadedVersion = version
        }
    }
}
