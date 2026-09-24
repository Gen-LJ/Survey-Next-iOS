import Foundation

/// One respondent's submission for one survey.
struct Answer: Decodable, Identifiable {
    let id: Int
    let surveyId: Int
    let respondentId: Int
    let pointsEarned: Int
    let answeredAt: Date
    let userAnswers: [UserAnswer]
}

/// The response to one question. Always a list of strings: the picked
/// option texts, a rating as "1"..."5", or the typed text.
struct UserAnswer: Decodable, Hashable {
    let questionId: Int
    let responses: [String]
}

/// `data` of `GET /respondent/completed/{id}`.
struct AnswerDetails: Decodable {
    let survey: Survey
    let answer: Answer
}
