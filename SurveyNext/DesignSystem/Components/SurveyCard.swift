import SwiftUI

/// A survey in a list. Equivalent of `SurveyCard`.
///
/// Wrap it in a `Button` (with `CardButtonStyle`) to make it tappable.
struct SurveyCard<Trailing: View>: View {
    let survey: Survey
    /// Show the lifecycle badge and answer progress (the author's view).
    var showState = false
    /// Replaces the default "Updated …" caption.
    var footer: String?
    /// Top-right slot, e.g. a bookmark toggle.
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(survey.categoryName.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .lineLimit(1)
                    Text(survey.title)
                        .font(.headline)
                        .foregroundStyle(Color.appOnSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if showState {
                    StateBadge(state: survey.state)
                }
                trailing
            }

            if !survey.description.isEmpty {
                Text(survey.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            HStack(spacing: Spacing.md) {
                MetaLabel(systemImage: "clock", text: "\(survey.minutes) min")
                MetaLabel(systemImage: "questionmark.circle", text: "\(survey.questionCount) Qs")
                if survey.pointsPerAnswer > 0 {
                    MetaLabel(systemImage: "star.circle", text: "\(survey.pointsPerAnswer.pointsText) pts", highlight: true)
                }
            }

            if showState && survey.state != .draft {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: survey.progress)
                        .tint(Color.brandPrimary)
                    Text("\(survey.answerCount) of \(survey.expectedAnswerCounts) responses")
                        .font(.caption)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
            } else {
                Text(footer ?? "Updated \(DateText.relative(survey.lastModifiedAt))")
                    .font(.caption)
                    .foregroundStyle(Color.appOnSurfaceVariant)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))
        .contentShape(.rect(cornerRadius: Radius.large))
    }
}

extension SurveyCard where Trailing == EmptyView {
    init(survey: Survey, showState: Bool = false, footer: String? = nil) {
        self.init(survey: survey, showState: showState, footer: footer) { EmptyView() }
    }
}

/// Icon + short text, e.g. "3 min".
struct MetaLabel: View {
    let systemImage: String
    let text: String
    var highlight = false

    var body: some View {
        Label(text, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(highlight ? Color.brandGold : Color.appOnSurfaceVariant)
    }
}

/// Coloured pill with the survey's lifecycle state. Equivalent of `StateBadge`.
struct StateBadge: View {
    let state: SurveyState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.badgeForeground)
                .frame(width: 6, height: 6)
            Text(state.label)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(state.badgeForeground)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(state.badgeBackground, in: .capsule)
    }
}

#Preview {
    VStack(spacing: 12) {
        SurveyCard(survey: .sample(), showState: true)
        SurveyCard(survey: .sample(id: 2, state: .draft), showState: true)
        SurveyCard(survey: .sample(), footer: "8 spots left") {
            Image(systemName: "bookmark")
        }
    }
    .padding()
}
