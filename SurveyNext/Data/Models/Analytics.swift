import Foundation

/// `data` of `GET /interviewer/survey/{id}/analytics`.
struct Analytics: Decodable {
    let survey: Survey
    let answers: [Answer]
    let summary: [QuestionSummary]
    let answerTotal: Int
}

/// Server-side tally of one question. Only the fields that apply to the
/// question's type are filled in.
struct QuestionSummary: Decodable, Identifiable {
    let questionId: Int
    let text: String
    let questionType: QuestionType
    let responseCount: Int
    let optionCounts: [OptionCount]?
    /// Five buckets, ratings 1...5.
    let ratingCounts: [Int]?
    let averageRating: Double?
    let textResponses: [String]?

    var id: Int { questionId }
}

struct OptionCount: Decodable, Hashable {
    let option: String
    let count: Int
}
