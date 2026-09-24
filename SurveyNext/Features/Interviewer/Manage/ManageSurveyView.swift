import SwiftUI

/// One of the interviewer's surveys: the draft editor while it's a draft,
/// the live overview after publishing. Equivalent of `ManageSurveyScreen`.
struct ManageSurveyView: View {
    @State private var viewModel: ManageSurveyViewModel
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss

    init(surveyId: Int, repository: any InterviewerRepository, session: SessionStore) {
        _viewModel = State(initialValue: ManageSurveyViewModel(surveyId: surveyId, repository: repository, session: session))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        LoadStateView(state: viewModel.state, retry: viewModel.retry) { survey in
            if survey.state == .draft {
                DraftEditorView(survey: survey, viewModel: viewModel)
            } else {
                LiveOverviewView(survey: survey, viewModel: viewModel)
            }
        }
        .background(Color.appBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.survey != nil {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(role: .destructive) {
                            isConfirmingDelete = true
                        } label: {
                            Label("Delete survey", systemImage: "trash")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if viewModel.isBusy {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(Color.brandPrimary)
            }
        }
        .toast($viewModel.message)
        .alert("Delete survey?", isPresented: $isConfirmingDelete, presenting: viewModel.survey) { _ in
            Button("Delete", role: .destructive) {
                Task { await viewModel.delete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: { survey in
            Text(deleteMessage(for: survey))
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.isDeleted) { _, deleted in
            if deleted { dismiss() }
        }
    }

    private var title: String {
        switch viewModel.survey?.state {
        case .draft: "Edit draft"
        case nil: "Survey"
        default: "Survey overview"
        }
    }

    private func deleteMessage(for survey: Survey) -> String {
        var message = "\"\(survey.title)\" and all of its responses will be permanently deleted."
        if survey.pendingPoints > 0 {
            message += " The \(survey.pendingPoints.pointsText) unpaid points go back to your balance."
        }
        return message
    }
}

#Preview("Draft") {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    NavigationStack {
        ManageSurveyView(surveyId: 2, repository: container.interviewerRepository, session: container.session)
    }
    .environment(container)
}

#Preview("Live") {
    let container = AppContainer.preview(user: PreviewAuthRepository.interviewer)
    NavigationStack {
        ManageSurveyView(surveyId: 1, repository: container.interviewerRepository, session: container.session)
    }
    .environment(container)
}
