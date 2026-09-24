import Foundation
import Observation

/// One question at a time, then submit. Equivalent of `AnswerSurveyViewModel`.
@Observable
final class AnswerSurveyViewModel {
    private(set) var state: LoadState<Survey> = .loading
    private(set) var questions: [Question] = []
    private(set) var currentIndex = 0
    /// Last move direction, so the page slides the right way.
    private(set) var movedForward = true
    /// Responses by question id, in the backend's shape: always a list of strings.
    private(set) var answers: [Int: [String]] = [:]
    private(set) var isSubmitting = false
    var errorMessage: String?
    /// Points earned, once the submission is accepted.
    private(set) var earnedPoints: Int?

    @ObservationIgnored private let surveyId: Int
    @ObservationIgnored private let repository: any RespondentRepository

    init(surveyId: Int, repository: any RespondentRepository) {
        self.surveyId = surveyId
        self.repository = repository
    }

    var current: Question? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var isLast: Bool { currentIndex == questions.count - 1 }

    var hasAnswers: Bool { answers.values.contains { !$0.isEmpty } }

    func load() async {
        state = .loading
        do {
            let survey = try await repository.survey(id: surveyId)
            questions = survey.sortedQuestions
            state = .loaded(survey)
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func responses(for question: Question) -> [String] {
        answers[question.id] ?? []
    }

    func isAnswered(_ question: Question) -> Bool {
        let responses = responses(for: question)
        switch question.questionType {
        case .textInput: return !(responses.first?.trimmed.isEmpty ?? true)
        default: return !responses.isEmpty
        }
    }

    func selectOption(_ question: Question, _ option: String) {
        var responses = responses(for: question)
        if question.allowMultiAnswer {
            if let index = responses.firstIndex(of: option) {
                responses.remove(at: index)
            } else {
                responses.append(option)
            }
        } else {
            responses = [option]
        }
        answers[question.id] = responses
    }

    func setRating(_ question: Question, _ rating: Int) {
        answers[question.id] = [String(rating)]
    }

    func setText(_ question: Question, _ text: String) {
        answers[question.id] = [text]
    }

    func next() {
        guard currentIndex < questions.count - 1 else { return }
        movedForward = true
        currentIndex += 1
    }

    /// Returns false when already on the first question.
    @discardableResult
    func previous() -> Bool {
        guard currentIndex > 0 else { return false }
        movedForward = false
        currentIndex -= 1
        return true
    }

    func submit() async {
        guard !isSubmitting else { return }
        if let unanswered = questions.firstIndex(where: { !isAnswered($0) }) {
            movedForward = unanswered > currentIndex
            currentIndex = unanswered
            errorMessage = "Please answer every question"
            return
        }

        var payload: [Int: [String]] = [:]
        for question in questions {
            let responses = self.responses(for: question)
            payload[question.id] = question.questionType == .textInput ? responses.map(\.trimmed) : responses
        }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let answer = try await repository.submitAnswers(surveyId: surveyId, answers: payload)
            earnedPoints = answer.pointsEarned
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
