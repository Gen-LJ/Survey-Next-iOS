import Foundation

// Request bodies. `APIClient` encodes property names as snake_case, and nil
// optionals are left out of the JSON entirely.

struct CreateSurveyRequest: Encodable {
    let title: String
    let description: String
    let categoryId: Int
    let countryId: Int
    let regionId: Int
    let minutes: Int
}

struct EditSurveyInfoRequest: Encodable {
    let title: String
    let description: String
    let minutes: Int
    let categoryId: Int
}

struct PublishSurveyRequest: Encodable {
    let expectedAnswerCounts: Int
    let pointsPerAnswer: Int
}

struct PauseSurveyRequest: Encodable {
    let paused: Bool
}

struct AddQuestionRequest: Encodable {
    let text: String
    let questionType: QuestionType
    let allowMultiAnswer: Bool
    /// Multiple choice only.
    let options: [String]?
}

struct EditQuestionRequest: Encodable {
    let text: String
    /// Nil leaves the existing choices untouched.
    let options: [String]?
}

struct SubmitAnswerRequest: Encodable {
    let answers: [UserAnswerRequest]
}

struct UserAnswerRequest: Encodable {
    let questionId: Int
    let responses: [String]
}
