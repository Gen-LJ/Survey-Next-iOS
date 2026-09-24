#if DEBUG
import Foundation

// Sample data and fake repositories so SwiftUI previews render without the
// backend. Nothing here ships in a release build.

extension Question {
    static let sampleChoice = Question(
        id: 1, surveyId: 1, text: "How do you usually get to work?", questionType: .multipleChoice,
        allowMultiAnswer: false, position: 0,
        options: [
            QuestionOption(id: 1, text: "Bus", position: 0),
            QuestionOption(id: 2, text: "Bike", position: 1),
            QuestionOption(id: 3, text: "Car", position: 2),
        ]
    )
    static let sampleRating = Question(
        id: 2, surveyId: 1, text: "How would you rate your commute?", questionType: .rating,
        allowMultiAnswer: false, position: 1, options: []
    )
    static let sampleText = Question(
        id: 3, surveyId: 1, text: "What would make it better?", questionType: .textInput,
        allowMultiAnswer: false, position: 2, options: []
    )
}

extension Survey {
    static func sample(
        id: Int = 1,
        title: String = "Commute habits",
        state: SurveyState = .published,
        answerCount: Int = 12,
        questions: [Question]? = [.sampleChoice, .sampleRating, .sampleText],
        answeredAt: Date? = nil
    ) -> Survey {
        Survey(
            id: id, title: title,
            description: "How people in Yangon travel to work, and what would make it easier.",
            categoryId: 11, countryId: 119, regionId: 1, creatorId: 2, minutes: 3,
            expectedAnswerCounts: 20, pointsPerAnswer: 10,
            pendingPoints: state == .draft ? 0 : (20 - answerCount) * 10,
            totalPoints: state == .draft ? 0 : 200,
            answerCount: state == .draft ? 0 : answerCount,
            questionCount: questions?.count ?? 3,
            state: state,
            publishedAt: state == .draft ? nil : .now.addingTimeInterval(-86_400 * 2),
            completedAt: nil,
            lastModifiedAt: .now.addingTimeInterval(-3_600),
            questions: questions,
            answeredAt: answeredAt
        )
    }

    static let samples: [Survey] = [
        .sample(id: 1),
        .sample(id: 2, title: "Healthy eating at school", state: .draft),
        .sample(id: 3, title: "Internet at home", state: .paused, answerCount: 5),
    ]
}

final class PreviewInterviewerRepository: InterviewerRepository {
    func home() async throws -> InterviewerHome {
        InterviewerHome(
            points: 1_000, draftCount: 1, publishedCount: 1, pausedCount: 1, completedCount: 0,
            recentPublished: [.sample(id: 1)], recentDrafts: [.sample(id: 2, title: "Healthy eating at school", state: .draft)]
        )
    }

    func surveys(page: Int, limit: Int, state: SurveyState?) async throws -> Page<Survey> {
        let items = Survey.samples.filter { state == nil || $0.state == state }
        return Page(items: items, meta: PageMeta(page: 1, limit: limit, total: items.count, totalPages: 1, hasNext: false))
    }

    func createSurveyForm() async throws -> CreateSurveyForm {
        CreateSurveyForm(
            categoryList: [Category(id: 4, name: "Health & Well-being"), Category(id: 11, name: "Transport & Mobility")],
            countryList: [Country(id: 119, name: "Myanmar", code: "MMR", regions: nil)]
        )
    }

    func regions(countryId: Int) async throws -> [Region] {
        [Region(id: 1, name: "Yangon", code: "YGN"), Region(id: 2, name: "Mandalay", code: "MDY")]
    }

    func createSurvey(_ request: CreateSurveyRequest) async throws -> Survey { .sample(state: .draft) }

    func survey(id: Int) async throws -> Survey { Survey.samples.first { $0.id == id } ?? .sample() }

    func editSurveyInfo(id: Int, _ request: EditSurveyInfoRequest) async throws {}

    func deleteSurvey(id: Int) async throws {}

    func publishSurvey(id: Int, expectedAnswers: Int, pointsPerAnswer: Int) async throws {}

    func setPaused(id: Int, paused: Bool) async throws {}

    func analytics(surveyId: Int) async throws -> Analytics {
        Analytics(
            survey: .sample(),
            answers: [],
            summary: [
                QuestionSummary(
                    questionId: 1, text: Question.sampleChoice.text, questionType: .multipleChoice, responseCount: 12,
                    optionCounts: [OptionCount(option: "Bus", count: 7), OptionCount(option: "Bike", count: 2), OptionCount(option: "Car", count: 3)],
                    ratingCounts: nil, averageRating: nil, textResponses: []
                ),
                QuestionSummary(
                    questionId: 2, text: Question.sampleRating.text, questionType: .rating, responseCount: 12,
                    optionCounts: [], ratingCounts: [1, 1, 3, 4, 3], averageRating: 3.6, textResponses: []
                ),
                QuestionSummary(
                    questionId: 3, text: Question.sampleText.text, questionType: .textInput, responseCount: 4,
                    optionCounts: [], ratingCounts: nil, averageRating: nil,
                    textResponses: ["More buses at rush hour", "Bike lanes", "Cheaper fares", "Less traffic"]
                ),
            ],
            answerTotal: 12
        )
    }

    func addQuestion(
        surveyId: Int, text: String, type: QuestionType, allowMultiAnswer: Bool, options: [String]
    ) async throws -> Question { .sampleChoice }

    func editQuestion(surveyId: Int, questionId: Int, text: String, options: [String]?) async throws {}

    func deleteQuestion(surveyId: Int, questionId: Int) async throws {}
}

final class PreviewRespondentRepository: RespondentRepository {
    func home() async throws -> RespondentHome {
        RespondentHome(points: 250, availableCount: 3, answeredCount: 4, savedCount: 1, recentSurveys: Survey.samples)
    }

    func availableSurveys(page: Int, limit: Int) async throws -> Page<Survey> {
        Page(items: Survey.samples, meta: PageMeta(page: 1, limit: limit, total: 3, totalPages: 1, hasNext: false))
    }

    func survey(id: Int) async throws -> Survey { .sample(id: id) }

    func submitAnswers(surveyId: Int, answers: [Int: [String]]) async throws -> Answer {
        Answer(id: 1, surveyId: surveyId, respondentId: 1, pointsEarned: 10, answeredAt: .now, userAnswers: [])
    }

    func savedSurveys() async throws -> [Survey] { [.sample(id: 1)] }

    func savedSurveyIds() async throws -> Set<Int> { [1] }

    func saveSurvey(id: Int) async throws {}

    func removeSavedSurvey(id: Int) async throws {}

    func completedSurveys(page: Int, limit: Int) async throws -> Page<Survey> {
        let items = [Survey.sample(id: 4, title: "Mobile banking", answeredAt: .now.addingTimeInterval(-7_200))]
        return Page(items: items, meta: PageMeta(page: 1, limit: limit, total: 1, totalPages: 1, hasNext: false))
    }

    func answerDetails(surveyId: Int) async throws -> AnswerDetails {
        AnswerDetails(
            survey: .sample(id: surveyId),
            answer: Answer(
                id: 1, surveyId: surveyId, respondentId: 1, pointsEarned: 10, answeredAt: .now,
                userAnswers: [
                    UserAnswer(questionId: 1, responses: ["Bus"]),
                    UserAnswer(questionId: 2, responses: ["4"]),
                    UserAnswer(questionId: 3, responses: ["More buses at rush hour"]),
                ]
            )
        )
    }
}
#endif
