import SwiftUI

/// One of the two "How will you use Survey Next?" cards.
struct RoleOptionCard: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.appOnSurfaceVariant)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? Color.brandOnPrimaryContainer : Color.appOnSurface)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
            .background(
                isSelected ? Color.brandPrimaryContainer : Color.appSurfaceLow,
                in: .rect(cornerRadius: Radius.medium)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Radius.medium)
                    .stroke(isSelected ? Color.brandPrimary : Color.appOutlineVariant,
                            lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
