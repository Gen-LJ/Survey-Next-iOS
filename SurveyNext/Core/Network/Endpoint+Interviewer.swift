import Foundation

/// `/interviewer/...` routes. Equivalent of `InterviewerApi`.
extension Endpoint {
    static var interviewerHome: Endpoint {
        Endpoint(path: "interviewer/home")
    }

    /// - Parameter state: nil lists surveys in every state.
    static func surveys(page: Int, limit: Int, state: SurveyState?) -> Endpoint {
        var query = [URLQueryItem].page(page, limit: limit)
        if let state {
            query.append(URLQueryItem(name: "state", value: state.rawValue))
        }
        return Endpoint(path: "interviewer/survey/list", query: query)
    }

    static var createSurveyForm: Endpoint {
        Endpoint(path: "interviewer/survey/form")
    }

    static func createSurvey(_ request: CreateSurveyRequest) -> Endpoint {
        Endpoint(path: "interviewer/survey/create", method: .post, body: request)
    }

    static func survey(id: Int) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(id)")
    }

    static func editSurveyInfo(id: Int, _ request: EditSurveyInfoRequest) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(id)", method: .put, body: request)
    }

    static func deleteSurvey(id: Int) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(id)", method: .delete)
    }

    static func publishSurvey(id: Int, _ request: PublishSurveyRequest) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(id)/publish", method: .post, body: request)
    }

    static func pauseSurvey(id: Int, paused: Bool) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(id)/pause", method: .post, body: PauseSurveyRequest(paused: paused))
    }

    static func analytics(surveyId: Int) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(surveyId)/analytics")
    }

    static func addQuestion(surveyId: Int, _ request: AddQuestionRequest) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(surveyId)/questions", method: .post, body: request)
    }

    static func editQuestion(surveyId: Int, questionId: Int, _ request: EditQuestionRequest) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(surveyId)/questions/\(questionId)", method: .put, body: request)
    }

    static func deleteQuestion(surveyId: Int, questionId: Int) -> Endpoint {
        Endpoint(path: "interviewer/survey/\(surveyId)/questions/\(questionId)", method: .delete)
    }
}
