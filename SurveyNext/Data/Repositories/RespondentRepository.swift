import Foundation

/// Answering surveys. Equivalent of `RespondentRepository` on Android.
protocol RespondentRepository {
    func home() async throws -> RespondentHome

    func availableSurveys(page: Int, limit: Int) async throws -> Page<Survey>

    /// A survey with its questions, ready to answer.
    func survey(id: Int) async throws -> Survey

    /// - Parameter answers: responses keyed by question id; every question must be present.
    func submitAnswers(surveyId: Int, answers: [Int: [String]]) async throws -> Answer

    func savedSurveys() async throws -> [Survey]

    func savedSurveyIds() async throws -> Set<Int>

    func saveSurvey(id: Int) async throws

    func removeSavedSurvey(id: Int) async throws

    func completedSurveys(page: Int, limit: Int) async throws -> Page<Survey>

    func answerDetails(surveyId: Int) async throws -> AnswerDetails
}

/// The backend caps the saved list at five.
let maxSavedSurveys = 5

final class DefaultRespondentRepository: RespondentRepository {
    private let api: APIClient
    private let notifier: DataChangeNotifier

    init(api: APIClient, notifier: DataChangeNotifier) {
        self.api = api
        self.notifier = notifier
    }

    func home() async throws -> RespondentHome {
        try await api.send(.respondentHome)
    }

    func availableSurveys(page: Int, limit: Int) async throws -> Page<Survey> {
        try await api.send(.availableSurveys(page: page, limit: limit))
    }

    func survey(id: Int) async throws -> Survey {
        try await api.send(.respondentSurvey(id: id))
    }

    func submitAnswers(surveyId: Int, answers: [Int: [String]]) async throws -> Answer {
        let request = SubmitAnswerRequest(
            answers: answers.map { UserAnswerRequest(questionId: $0.key, responses: $0.value) }
        )
        let answer: Answer = try await api.send(.submitAnswers(surveyId: surveyId, request))
        notifier.notifyChanged()
        return answer
    }

    func savedSurveys() async throws -> [Survey] {
        try await api.send(.savedSurveys)
    }

    func savedSurveyIds() async throws -> Set<Int> {
        let ids: [Int] = try await api.send(.savedSurveyIds)
        return Set(ids)
    }

    func saveSurvey(id: Int) async throws {
        try await api.perform(.saveSurvey(id: id))
        notifier.notifyChanged()
    }

    func removeSavedSurvey(id: Int) async throws {
        try await api.perform(.removeSavedSurvey(id: id))
        notifier.notifyChanged()
    }

    func completedSurveys(page: Int, limit: Int) async throws -> Page<Survey> {
        try await api.send(.completedSurveys(page: page, limit: limit))
    }

    func answerDetails(surveyId: Int) async throws -> AnswerDetails {
        try await api.send(.answerDetails(surveyId: surveyId))
    }
}
