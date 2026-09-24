import Foundation

struct Question: Decodable, Identifiable, Hashable {
    let id: Int
    let surveyId: Int
    let text: String
    let questionType: QuestionType
    let allowMultiAnswer: Bool
    let position: Int
    let options: [QuestionOption]?

    /// Choices in the author's order.
    var sortedOptions: [QuestionOption] {
        (options ?? []).sorted { $0.position < $1.position }
    }
}

struct QuestionOption: Decodable, Identifiable, Hashable {
    let id: Int
    let text: String
    let position: Int
}

enum QuestionType: String, Codable, CaseIterable, Identifiable, Hashable {
    case multipleChoice = "multiple_choice"
    case rating
    case textInput = "text_input"

    var id: Self { self }

    var label: String {
        switch self {
        case .multipleChoice: "Multiple choice"
        case .rating: "Rating"
        case .textInput: "Text answer"
        }
    }

    var shortLabel: String {
        switch self {
        case .multipleChoice: "Choice"
        case .rating: "Rating"
        case .textInput: "Text"
        }
    }

    /// SF Symbol name.
    var systemImage: String {
        switch self {
        case .multipleChoice: "checklist"
        case .rating: "star"
        case .textInput: "text.alignleft"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = QuestionType(rawValue: raw) ?? .textInput
    }
}
