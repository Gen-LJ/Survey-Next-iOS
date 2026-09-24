import SwiftUI

/// Adds a question, or edits `existing`. The backend only lets an existing
/// question change its text and options, so type and multi-select lock then.
/// Equivalent of `QuestionEditorSheet`.
struct QuestionEditorSheet: View {
    let existing: Question?
    let isSaving: Bool
    /// Returns true when saved; the sheet then closes.
    let onSave: @MainActor (QuestionDraft) async -> Bool

    @State private var draft: QuestionDraft
    @State private var showErrors = false
    @Environment(\.dismiss) private var dismiss

    init(existing: Question?, isSaving: Bool, onSave: @escaping @MainActor (QuestionDraft) async -> Bool) {
        self.existing = existing
        self.isSaving = isSaving
        self.onSave = onSave
        if let existing {
            _draft = State(initialValue: QuestionDraft(existing))
        } else {
            _draft = State(initialValue: QuestionDraft())
        }
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Picker("Question type", selection: $draft.type) {
                        ForEach(QuestionType.allCases) { type in
                            Text(type.shortLabel).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isEditing)

                    FormTextField(
                        title: "Question",
                        text: $draft.text,
                        prompt: "What do you want to ask?",
                        error: showErrors && draft.text.trimmed.isEmpty ? "Write the question" : nil,
                        minLines: 2
                    )

                    switch draft.type {
                    case .multipleChoice:
                        optionsEditor
                    case .rating:
                        hint("Respondents rate from 1 to 5 stars.")
                    case .textInput:
                        hint("Respondents answer in their own words.")
                    }

                    if showErrors, let error = draft.validationError {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.appError)
                    }

                    PrimaryButton(title: isEditing ? "Save changes" : "Add question", isLoading: isSaving) {
                        showErrors = true
                        guard draft.validationError == nil else { return }
                        Task {
                            if await onSave(draft) {
                                dismiss()
                            }
                        }
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit question" : "New question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private var optionsEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Options")
                .font(.subheadline.weight(.semibold))

            ForEach($draft.options) { $option in
                let index = draft.options.firstIndex { $0.id == option.id } ?? 0
                HStack(spacing: Spacing.sm) {
                    TextField("Option \(index + 1)", text: $option.text)
                        .accessibilityLabel("Option \(index + 1)")
                        .padding(.horizontal, 14)
                        .frame(minHeight: 48)
                        .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.small))
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.small).stroke(Color.appOutlineVariant)
                        }
                    Button {
                        draft.options.removeAll { $0.id == option.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.appOutline)
                    }
                    .buttonStyle(.plain)
                    .disabled(draft.options.count <= 2)
                    .opacity(draft.options.count <= 2 ? 0.35 : 1)
                    .accessibilityLabel("Remove option \(index + 1)")
                }
            }

            if draft.options.count < QuestionDraft.maxOptions {
                Button {
                    draft.options.append(OptionDraft())
                } label: {
                    Label("Add option", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
            }

            Toggle(isOn: $draft.allowMultiAnswer) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Allow multiple answers")
                    Text(isEditing ? "Can't be changed after the question is created" : "Respondents can pick more than one option")
                        .font(.caption)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
            }
            .disabled(isEditing)
            .padding(.top, Spacing.xs)
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color.appOnSurfaceVariant)
    }
}

#Preview("New") {
    QuestionEditorSheet(existing: nil, isSaving: false) { _ in true }
}

#Preview("Edit") {
    QuestionEditorSheet(existing: .sampleChoice, isSaving: false) { _ in true }
}
