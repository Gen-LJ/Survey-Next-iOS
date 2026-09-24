import Foundation
import Observation

/// Equivalent of `InterviewerSurveysViewModel`.
@Observable
final class InterviewerSurveysViewModel {
    /// Nil shows every state.
    private(set) var filter: SurveyState? = nil
    private(set) var list: PagedList<Survey>

    @ObservationIgnored private var loadedVersion: Int?
    @ObservationIgnored private let repository: any InterviewerRepository

    init(repository: any InterviewerRepository) {
        self.repository = repository
        self.list = Self.makeList(repository: repository, filter: nil)
    }

    func selectFilter(_ state: SurveyState?) {
        guard state != filter else { return }
        filter = state
        list = Self.makeList(repository: repository, filter: state)
        loadedVersion = nil
    }

    /// Reloads when the data version is new or the filter changed.
    func load(version: Int) async {
        guard version != loadedVersion else { return }
        await list.reload()
        if list.hasLoaded, list.error == nil {
            loadedVersion = version
        }
    }

    private static func makeList(repository: any InterviewerRepository, filter: SurveyState?) -> PagedList<Survey> {
        PagedList { page, limit in
            try await repository.surveys(page: page, limit: limit, state: filter)
        }
    }
}
