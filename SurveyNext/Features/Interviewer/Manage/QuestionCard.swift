import SwiftUI

/// A question in the author's list. Edit and delete appear only when their
/// callbacks are given, i.e. while the survey is still a draft.
/// Equivalent of `QuestionCard`.
struct QuestionCard: View {
    let number: Int
    let question: Question
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.brandOnPrimaryContainer)
                    .frame(width: 28, height: 28)
                    .background(Color.brandPrimaryContainer, in: .circle)

                Label(
                    question.questionType.label + (question.allowMultiAnswer ? " · multi-select" : ""),
                    systemImage: question.questionType.systemImage
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.appOnSurfaceVariant)

                Spacer(minLength: 0)

                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .accessibilityLabel("Edit question \(number)")
                }
                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.appError)
                    .accessibilityLabel("Delete question \(number)")
                }
            }

            Text(question.text)
                .font(.headline)
                .foregroundStyle(Color.appOnSurface)

            switch question.questionType {
            case .multipleChoice:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(question.sortedOptions) { option in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: question.allowMultiAnswer ? "square" : "circle")
                                .foregroundStyle(Color.appOutline)
                            Text(option.text)
                                .font(.subheadline)
                                .foregroundStyle(Color.appOnSurface)
                        }
                    }
                }
            case .rating:
                RatingStars(rating: 0, size: 22)
            case .textInput:
                Text("Respondents type a free-text answer")
                    .font(.subheadline)
                    .foregroundStyle(Color.appOnSurfaceVariant)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))
    }
}

#Preview {
    VStack(spacing: 12) {
        QuestionCard(number: 1, question: .sampleChoice, onEdit: {}, onDelete: {})
        QuestionCard(number: 2, question: .sampleRating)
        QuestionCard(number: 3, question: .sampleText)
    }
    .padding()
}
