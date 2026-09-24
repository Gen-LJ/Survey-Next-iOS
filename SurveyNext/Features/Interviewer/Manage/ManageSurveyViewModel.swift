import Foundation
import Observation

/// One option row in the editor. The id keeps rows stable while you add and remove them.
struct OptionDraft: Identifiable, Equatable {
    let id = UUID()
    var text = ""
}

/// A question as edited in the sheet, before it is sent.
struct QuestionDraft: Equatable {
    var text = ""
    var type: QuestionType = .multipleChoice
    var allowMultiAnswer = false
    var options = [OptionDraft(), OptionDraft()]

    static let maxOptions = 10

    var cleanOptions: [String] {
        options.map(\.text.trimmed).filter { !$0.isEmpty }
    }

    /// Nil when the draft can be saved.
    var validationError: String? {
        if text.trimmed.isEmpty { return "Write the question" }
        if type == .multipleChoice {
            if cleanOptions.count < 2 { return "Add at least two options" }
            if Set(cleanOptions).count != cleanOptions.count { return "Options must be different" }
        }
        return nil
    }

    init() {}

    init(_ question: Question) {
        text = question.text
        type = question.questionType
        allowMultiAnswer = question.allowMultiAnswer
        let existing = question.sortedOptions.map { OptionDraft(text: $0.text) }
        options = existing.isEmpty ? [OptionDraft(), OptionDraft()] : existing
    }
}

/// The Details tab's fields.
struct SurveyInfoForm: Equatable {
    var title: String
    var description: String
    var minutes: Int
    var categoryId: Int

    init(_ survey: Survey) {
        title = survey.title
        description = survey.description
        minutes = survey.minutes
        categoryId = survey.categoryId
    }
}

/// The Publish tab's fields, as typed.
struct PublishForm: Equatable {
    var expectedAnswers = "20"
    var pointsPerAnswer = "10"

    var answers: Int { Int(expectedAnswers) ?? 0 }
    var points: Int { Int(pointsPerAnswer) ?? 0 }
    var totalCost: Int { answers * points }
}

/// One survey from the author's side: the draft editor, or the overview once
/// it's live. Equivalent of `ManageSurveyViewModel`.
@Observable
final class ManageSurveyViewModel {
    let surveyId: Int

    private(set) var state: LoadState<Survey> = .loading
    private(set) var categories: [Category] = []
    var infoForm: SurveyInfoForm?
    var publishForm = PublishForm() {
        didSet {
            // Digits only, at most six.
            let cleaned = PublishForm(
                expectedAnswers: String(publishForm.expectedAnswers.filter(\.isNumber).prefix(6)),
                pointsPerAnswer: String(publishForm.pointsPerAnswer.filter(\.isNumber).prefix(6))
            )
            if cleaned != publishForm { publishForm = cleaned }
        }
    }

    /// An operation is in flight; action buttons show progress.
    private(set) var isBusy = false
    /// Result of the last action, shown as a toast.
    var message: String?
    /// Set after the survey is deleted; the screen closes itself.
    private(set) var isDeleted = false

    @ObservationIgnored private let repository: any InterviewerRepository
    @ObservationIgnored private let session: SessionStore

    init(surveyId: Int, repository: any InterviewerRepository, session: SessionStore) {
        self.surveyId = surveyId
        self.repository = repository
        self.session = session
    }

    var survey: Survey? { state.value }

    /// The author's current points, kept fresh by the session.
    var balance: Int { session.user?.points ?? 0 }

    /// First load shows a spinner; coming back to the screen refreshes quietly.
    func load() async {
        guard !isDeleted else { return }
        if state.value != nil {
            await fetch()
            return
        }
        state = .loading
        async let categories: Void = loadCategories()
        await fetch()
        await categories
    }

    func retry() async {
        state = .loading
        await load()
    }

    func saveInfo() async {
        guard let form = infoForm else { return }
        guard !form.title.trimmed.isEmpty, !form.description.trimmed.isEmpty else {
            message = "Title and description can't be empty"
            return
        }
        let request = EditSurveyInfoRequest(
            title: form.title.trimmed, description: form.description.trimmed,
            minutes: form.minutes, categoryId: form.categoryId
        )
        let saved = await perform("Details saved") {
            try await self.repository.editSurveyInfo(id: self.surveyId, request)
        }
        // Show what the backend stored, so later reloads keep the form in sync.
        if saved, let survey {
            infoForm = SurveyInfoForm(survey)
        }
    }

    /// Returns true once the backend accepts the question, so the editor can close.
    func saveQuestion(existing: Question?, draft: QuestionDraft) async -> Bool {
        if let error = draft.validationError {
            message = error
            return false
        }
        let text = draft.text.trimmed
        return await perform(existing == nil ? "Question added" : "Question updated") {
            if let existing {
                // Only choice questions have options; nil leaves them alone.
                let options = existing.questionType == .multipleChoice ? draft.cleanOptions : nil
                try await self.repository.editQuestion(surveyId: self.surveyId, questionId: existing.id, text: text, options: options)
            } else {
                _ = try await self.repository.addQuestion(
                    surveyId: self.surveyId, text: text, type: draft.type,
                    allowMultiAnswer: draft.allowMultiAnswer, options: draft.cleanOptions
                )
            }
        }
    }

    func deleteQuestion(_ question: Question) async {
        await perform("Question deleted") {
            try await self.repository.deleteQuestion(surveyId: self.surveyId, questionId: question.id)
        }
    }

    func publish() async {
        let form = publishForm
        await perform("Survey published") {
            try await self.repository.publishSurvey(id: self.surveyId, expectedAnswers: form.answers, pointsPerAnswer: form.points)
        }
    }

    func setPaused(_ paused: Bool) async {
        await perform(paused ? "Survey paused" : "Survey resumed") {
            try await self.repository.setPaused(id: self.surveyId, paused: paused)
        }
    }

    func delete() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await repository.deleteSurvey(id: surveyId)
            isDeleted = true
        } catch is CancellationError {
        } catch {
            message = error.localizedDescription
        }
    }

    private func fetch() async {
        do {
            let survey = try await repository.survey(id: surveyId)
            // Keep unsaved edits in the Details tab; otherwise show the latest.
            let previous = state.value.map(SurveyInfoForm.init)
            if infoForm == nil || infoForm == previous {
                infoForm = SurveyInfoForm(survey)
            }
            state = .loaded(survey)
        } catch is CancellationError {
        } catch {
            if state.value == nil {
                state = .failed(error.localizedDescription)
            } else {
                message = error.localizedDescription
            }
        }
    }

    private func loadCategories() async {
        if let form = try? await repository.createSurveyForm() {
            categories = form.categoryList
        }
    }

    /// Runs an action with the busy flag, then reloads the survey.
    @discardableResult
    private func perform(_ successMessage: String, action: () async throws -> Void) async -> Bool {
        guard !isBusy else { return false }
        isBusy = true
        defer { isBusy = false }
        do {
            try await action()
            await fetch()
            message = successMessage
            return true
        } catch is CancellationError {
            return false
        } catch {
            message = error.localizedDescription
            return false
        }
    }
}
