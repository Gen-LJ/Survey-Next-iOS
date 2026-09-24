import Foundation
import Observation

/// Equivalent of `SurveyInfoViewModel`.
@Observable
final class SurveyInfoViewModel {
    let surveyId: Int
    private(set) var state: LoadState<Survey> = .loading
    private(set) var isSaved = false
    private(set) var isSaving = false
    var message: String?

    @ObservationIgnored private let repository: any RespondentRepository

    init(surveyId: Int, repository: any RespondentRepository) {
        self.surveyId = surveyId
        self.repository = repository
    }

    var survey: Survey? { state.value }

    func load() async {
        state = .loading
        async let savedIds = try? repository.savedSurveyIds()
        do {
            // The backend answers 409 with a readable reason when the survey
            // is closed or already answered; that becomes the error message.
            state = .loaded(try await repository.survey(id: surveyId))
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
        if let ids = await savedIds {
            isSaved = ids.contains(surveyId)
        }
    }

    func toggleSaved() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let saving = !isSaved
        do {
            if saving {
                try await repository.saveSurvey(id: surveyId)
            } else {
                try await repository.removeSavedSurvey(id: surveyId)
            }
            isSaved = saving
            message = saving ? "Saved for later" : "Removed from saved"
        } catch is CancellationError {
        } catch {
            message = error.localizedDescription
        }
    }
}
