import SwiftUI

/// Icon in a circle, title, message and optional actions.
/// Equivalent of `EmptyView` on Android (renamed: `EmptyView` is a SwiftUI type).
struct EmptyStateView<Actions: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.brandOnPrimaryContainer)
                .frame(width: 72, height: 72)
                .background(Color.brandPrimaryContainer, in: .circle)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appOnSurface)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.appOnSurfaceVariant)
                .multilineTextAlignment(.center)
            actions
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, 48)
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.init(systemImage: systemImage, title: title, message: message) { EmptyView() }
    }
}

/// Full-screen spinner. Equivalent of `LoadingView`.
struct LoadingView: View {
    var message = "Loading…"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.appOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Full-screen error with a retry button. Equivalent of `ErrorView`.
struct ErrorStateView: View {
    let message: String
    let retry: @MainActor () async -> Void

    var body: some View {
        ScrollView {
            EmptyStateView(systemImage: "exclamationmark.triangle", title: "Something went wrong", message: message) {
                Button("Retry") {
                    Task { await retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .defaultScrollAnchor(.center)
    }
}

/// Switches between spinner, error and content for a `LoadState`.
struct LoadStateView<Value, Content: View>: View {
    let state: LoadState<Value>
    var loadingMessage = "Loading…"
    let retry: @MainActor () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .loading:
            LoadingView(message: loadingMessage)
        case .failed(let message):
            ErrorStateView(message: message) { await retry() }
        case .loaded(let value):
            content(value)
        }
    }
}

/// Last row of a paged list: a spinner while the next page loads, or a retry
/// button. Appearing on screen asks for the next page.
struct PagingFooter<Item: Identifiable & Decodable>: View {
    let list: PagedList<Item>

    var body: some View {
        Group {
            if list.isLoadingMore {
                ProgressView()
            } else if list.error != nil {
                Button("Couldn't load more · Retry") {
                    Task { await list.retry() }
                }
                .font(.subheadline)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .task(id: list.items.count) {
            await list.loadMore()
        }
    }
}

/// Section title with an optional "See all" style action. Equivalent of `SectionHeader`.
struct SectionHeader: View {
    let title: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.appOnSurface)
            Spacer()
            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.top, Spacing.sm)
    }
}

#Preview("Empty") {
    EmptyStateView(systemImage: "tray", title: "You're all caught up", message: "New surveys for your region will appear here.") {
        Button("Refresh") {}
            .buttonStyle(.borderedProminent)
    }
}

#Preview("Error") {
    ErrorStateView(message: "Can't reach the server. Check your connection.") {}
}
