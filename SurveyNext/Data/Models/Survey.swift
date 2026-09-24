import Foundation

/// Covers the backend's summary, detail and answered-survey shapes: Go embeds
/// the summary struct in the others, so they all arrive flat.
/// Equivalent of `SurveyModel`.
struct Survey: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let categoryId: Int
    let countryId: Int
    let regionId: Int
    let creatorId: Int
    let minutes: Int
    let expectedAnswerCounts: Int
    let pointsPerAnswer: Int
    /// Escrow still owed to respondents.
    let pendingPoints: Int
    let totalPoints: Int
    let answerCount: Int
    let questionCount: Int
    let state: SurveyState
    let publishedAt: Date?
    let completedAt: Date?
    let lastModifiedAt: Date?
    /// Detail responses only.
    let questions: [Question]?
    /// The respondent's completed list only.
    let answeredAt: Date?

    var categoryName: String { Categories.name(for: categoryId) }

    /// Share of the target responses collected, 0...1.
    var progress: Double {
        guard expectedAnswerCounts > 0 else { return 0 }
        return min(1, max(0, Double(answerCount) / Double(expectedAnswerCounts)))
    }

    var spotsLeft: Int { max(0, expectedAnswerCounts - answerCount) }

    /// Questions in the author's order.
    var sortedQuestions: [Question] {
        (questions ?? []).sorted { $0.position < $1.position }
    }
}

enum SurveyState: String, Decodable, CaseIterable, Hashable {
    case draft
    case published
    case paused
    case completed

    var label: String {
        switch self {
        case .draft: "Draft"
        case .published: "Live"
        case .paused: "Paused"
        case .completed: "Completed"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SurveyState(rawValue: raw) ?? .draft
    }
}
