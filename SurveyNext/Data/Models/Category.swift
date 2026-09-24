import Foundation

struct Category: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
}

/// Categories are seeded in a fixed order on the backend, so their ids are
/// stable. Respondents have no endpoint that lists them, so names are resolved
/// from here.
enum Categories {
    private static let seeded = [
        "Energy & Environment",
        "Gender & Inclusion",
        "Climate Change & Sustainability",
        "Health & Well-being",
        "Education & Literacy",
        "Employment & Labor Market",
        "Income & Poverty",
        "Food Security & Agriculture",
        "Technology & Digital Access",
        "Housing & Infrastructure",
        "Transport & Mobility",
        "Governance & Political Participation",
        "Disaster Preparedness & Response",
        "Social Cohesion & Community Engagement",
        "Consumer Behavior & Market Trends",
    ]

    static func name(for id: Int) -> String {
        seeded.indices.contains(id - 1) ? seeded[id - 1] : "General"
    }
}

/// `data` of `GET /interviewer/survey/form`.
struct CreateSurveyForm: Decodable {
    let categoryList: [Category]
    /// Countries here come without regions; load them with `/regions/{id}`.
    let countryList: [Country]
}
