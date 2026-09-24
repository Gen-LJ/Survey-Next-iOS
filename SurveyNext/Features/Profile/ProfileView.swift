import SwiftUI

/// Account tab: who you are, your points, logout. Equivalent of `ProfileScreen`.
struct ProfileView: View {
    @Environment(AppContainer.self) private var container
    @State private var location: String?
    @State private var isConfirmingLogout = false
    @State private var isShowingAbout = false

    var body: some View {
        Group {
            if let user = container.session.user {
                content(user)
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Account")
        .alert("Log out?", isPresented: $isConfirmingLogout) {
            Button("Log out", role: .destructive) {
                container.authRepository.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to use Survey Next.")
        }
        .alert("Survey Next", isPresented: $isShowingAbout) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Interviewers publish surveys with a points reward. Respondents in the targeted region answer them and earn those points.")
        }
        .task(id: container.session.user?.id) {
            if let user = container.session.user {
                location = await container.authRepository.locationName(countryId: user.countryId, regionId: user.regionId)
            }
        }
    }

    private func content(_ user: User) -> some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                header(user)

                if user.role == .admin {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Admin account")
                                .font(.headline)
                            Text("Platform administration isn't available in the app. Sign in as an interviewer or respondent.")
                                .font(.subheadline)
                                .foregroundStyle(Color.appOnSurfaceVariant)
                        }
                    } icon: {
                        Image(systemName: "person.badge.shield.checkmark")
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.brandPrimaryContainer, in: .rect(cornerRadius: Radius.large))
                } else {
                    PointsCard(
                        label: user.role == .interviewer ? "Available balance" : "Points earned",
                        points: user.points,
                        caption: user.pendingPoints > 0 ? "\(user.pendingPoints.pointsText) pts pending" : nil
                    )
                }

                VStack(spacing: 0) {
                    InfoRow(systemImage: "envelope", label: "Email", value: user.email)
                    Divider().padding(.leading, 56)
                    InfoRow(systemImage: "person.text.rectangle", label: "Role", value: user.role.label)
                    Divider().padding(.leading, 56)
                    InfoRow(systemImage: "mappin.and.ellipse", label: "Location", value: location ?? "—")
                }
                .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))

                VStack(spacing: 0) {
                    ActionRow(systemImage: "info.circle", label: "About Survey Next") {
                        isShowingAbout = true
                    }
                    Divider().padding(.leading, 56)
                    ActionRow(systemImage: "rectangle.portrait.and.arrow.right", label: "Log out", tint: .appError) {
                        isConfirmingLogout = true
                    }
                }
                .background(Color.appSurfaceLow, in: .rect(cornerRadius: Radius.large))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .refreshable {
            _ = try? await container.authRepository.refreshUser()
        }
    }

    private func header(_ user: User) -> some View {
        VStack(spacing: 4) {
            Text(user.name.initials)
                .font(.title.bold())
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(
                    LinearGradient(colors: [.heroStart, .heroEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .circle
                )
                .accessibilityHidden(true)
            Text(user.name)
                .font(.title2.bold())
                .foregroundStyle(Color.appOnSurface)
                .padding(.top, Spacing.sm)
            Text(user.email)
                .font(.subheadline)
                .foregroundStyle(Color.appOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct InfoRow: View {
    let systemImage: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.appOnSurfaceVariant)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.appOnSurfaceVariant)
                Text(value)
                    .font(.body)
                    .foregroundStyle(Color.appOnSurface)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

private struct ActionRow: View {
    let systemImage: String
    let label: String
    var tint: Color = .appOnSurface
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: systemImage)
                    .frame(width: 24)
                Text(label)
                    .font(.body)
                Spacer(minLength: 0)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let container = AppContainer.preview()
    NavigationStack {
        ProfileView()
    }
    .environment(container)
}
