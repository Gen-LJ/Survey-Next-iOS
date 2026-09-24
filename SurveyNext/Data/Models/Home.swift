import Foundation

/// `data` of `GET /interviewer/home`.
struct InterviewerHome: Decodable {
    let points: Int
    let draftCount: Int
    let publishedCount: Int
    let pausedCount: Int
    let completedCount: Int
    let recentPublished: [Survey]
    let recentDrafts: [Survey]

    var hasSurveys: Bool {
        draftCount + publishedCount + pausedCount + completedCount > 0
    }
}

/// `data` of `GET /respondent/home`.
struct RespondentHome: Decodable {
    let points: Int
    let availableCount: Int
    let answeredCount: Int
    let savedCount: Int
    let recentSurveys: [Survey]
}
