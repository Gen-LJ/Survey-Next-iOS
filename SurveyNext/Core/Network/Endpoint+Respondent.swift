import Foundation

/// `/respondent/...` routes. Equivalent of `RespondentApi`.
extension Endpoint {
    static var respondentHome: Endpoint {
        Endpoint(path: "respondent/home")
    }

    /// Published, unfilled surveys in the respondent's own country and region.
    static func availableSurveys(page: Int, limit: Int) -> Endpoint {
        Endpoint(path: "respondent/survey/list", query: .page(page, limit: limit))
    }

    /// Fails with 409 when the survey is closed or already answered.
    static func respondentSurvey(id: Int) -> Endpoint {
        Endpoint(path: "respondent/survey/\(id)")
    }

    static func submitAnswers(surveyId: Int, _ request: SubmitAnswerRequest) -> Endpoint {
        Endpoint(path: "respondent/survey/\(surveyId)/answer", method: .post, body: request)
    }

    static var savedSurveys: Endpoint {
        Endpoint(path: "respondent/saved")
    }

    static var savedSurveyIds: Endpoint {
        Endpoint(path: "respondent/saved-ids")
    }

    /// At most five surveys can be saved; the sixth fails with 409.
    static func saveSurvey(id: Int) -> Endpoint {
        Endpoint(path: "respondent/saved/\(id)", method: .post)
    }

    static func removeSavedSurvey(id: Int) -> Endpoint {
        Endpoint(path: "respondent/saved/\(id)", method: .delete)
    }

    static func completedSurveys(page: Int, limit: Int) -> Endpoint {
        Endpoint(path: "respondent/completed", query: .page(page, limit: limit))
    }

    static func answerDetails(surveyId: Int) -> Endpoint {
        Endpoint(path: "respondent/completed/\(surveyId)")
    }
}
