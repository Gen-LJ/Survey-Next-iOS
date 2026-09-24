import Foundation

/// Survey authoring. Equivalent of `InterviewerRepository` on Android.
protocol InterviewerRepository {
    func home() async throws -> InterviewerHome

    /// - Parameter state: nil lists surveys in every state.
    func surveys(page: Int, limit: Int, state: SurveyState?) async throws -> Page<Survey>

    /// Categories and target countries for the create and edit forms.
    func createSurveyForm() async throws -> CreateSurveyForm

    func regions(countryId: Int) async throws -> [Region]

    func createSurvey(_ request: CreateSurveyRequest) async throws -> Survey

    /// One of your own surveys, questions included.
    func survey(id: Int) async throws -> Survey

    func editSurveyInfo(id: Int, _ request: EditSurveyInfoRequest) async throws

    func deleteSurvey(id: Int) async throws

    func publishSurvey(id: Int, expectedAnswers: Int, pointsPerAnswer: Int) async throws

    func setPaused(id: Int, paused: Bool) async throws

    func analytics(surveyId: Int) async throws -> Analytics

    func addQuestion(
        surveyId: Int, text: String, type: QuestionType, allowMultiAnswer: Bool, options: [String]
    ) async throws -> Question

    /// - Parameter options: nil leaves the existing choices untouched.
    func editQuestion(surveyId: Int, questionId: Int, text: String, options: [String]?) async throws

    func deleteQuestion(surveyId: Int, questionId: Int) async throws
}

final class DefaultInterviewerRepository: InterviewerRepository {
    private let api: APIClient
    private let notifier: DataChangeNotifier
    private var cachedForm: CreateSurveyForm?

    init(api: APIClient, notifier: DataChangeNotifier) {
        self.api = api
        self.notifier = notifier
    }

    func home() async throws -> InterviewerHome {
        try await api.send(.interviewerHome)
    }

    func surveys(page: Int, limit: Int, state: SurveyState?) async throws -> Page<Survey> {
        try await api.send(.surveys(page: page, limit: limit, state: state))
    }

    func createSurveyForm() async throws -> CreateSurveyForm {
        if let cachedForm { return cachedForm }
        let form: CreateSurveyForm = try await api.send(.createSurveyForm)
        cachedForm = form
        return form
    }

    func regions(countryId: Int) async throws -> [Region] {
        try await api.send(.regions(countryId: countryId))
    }

    func createSurvey(_ request: CreateSurveyRequest) async throws -> Survey {
        let survey: Survey = try await api.send(.createSurvey(request))
        notifier.notifyChanged()
        return survey
    }

    func survey(id: Int) async throws -> Survey {
        try await api.send(.survey(id: id))
    }

    func editSurveyInfo(id: Int, _ request: EditSurveyInfoRequest) async throws {
        try await api.perform(.editSurveyInfo(id: id, request))
        notifier.notifyChanged()
    }

    func deleteSurvey(id: Int) async throws {
        try await api.perform(.deleteSurvey(id: id))
        notifier.notifyChanged()
    }

    func publishSurvey(id: Int, expectedAnswers: Int, pointsPerAnswer: Int) async throws {
        let request = PublishSurveyRequest(expectedAnswerCounts: expectedAnswers, pointsPerAnswer: pointsPerAnswer)
        try await api.perform(.publishSurvey(id: id, request))
        notifier.notifyChanged()
    }

    func setPaused(id: Int, paused: Bool) async throws {
        try await api.perform(.pauseSurvey(id: id, paused: paused))
        notifier.notifyChanged()
    }

    func analytics(surveyId: Int) async throws -> Analytics {
        try await api.send(.analytics(surveyId: surveyId))
    }

    func addQuestion(
        surveyId: Int, text: String, type: QuestionType, allowMultiAnswer: Bool, options: [String]
    ) async throws -> Question {
        let isChoice = type == .multipleChoice
        let request = AddQuestionRequest(
            text: text,
            questionType: type,
            allowMultiAnswer: isChoice && allowMultiAnswer,
            options: isChoice ? options : nil
        )
        let question: Question = try await api.send(.addQuestion(surveyId: surveyId, request))
        notifier.notifyChanged()
        return question
    }

    func editQuestion(surveyId: Int, questionId: Int, text: String, options: [String]?) async throws {
        let request = EditQuestionRequest(text: text, options: options)
        try await api.perform(.editQuestion(surveyId: surveyId, questionId: questionId, request))
        notifier.notifyChanged()
    }

    func deleteQuestion(surveyId: Int, questionId: Int) async throws {
        try await api.perform(.deleteQuestion(surveyId: surveyId, questionId: questionId))
        notifier.notifyChanged()
    }
}
