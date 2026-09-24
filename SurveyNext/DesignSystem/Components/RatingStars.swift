import SwiftUI

/// Five stars. Read-only unless `onChange` is given. Equivalent of `RatingSelector`.
struct RatingStars: View {
    /// 0 for none, otherwise 1...5.
    let rating: Int
    var size: CGFloat = 40
    var onChange: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: onChange == nil ? 2 : 8) {
            ForEach(1...5, id: \.self) { value in
                if let onChange {
                    Button {
                        onChange(value)
                    } label: {
                        star(value)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(pluralize(value, "star"))
                    .accessibilityAddTraits(value == rating ? .isSelected : [])
                } else {
                    star(value)
                }
            }
        }
        .accessibilityElement(children: onChange == nil ? .ignore : .contain)
        .accessibilityLabel(onChange == nil ? "\(rating) of 5 stars" : "Rating")
    }

    private func star(_ value: Int) -> some View {
        let filled = value <= rating
        return Image(systemName: filled ? "star.fill" : "star")
            .font(.system(size: size * 0.8))
            .foregroundStyle(filled ? Color.brandGold : Color.appOutlineVariant)
            .frame(width: size, height: size)
            .scaleEffect(filled ? 1 : 0.92)
            .animation(.spring(duration: 0.25), value: filled)
    }
}

/// "Poor" ... "Excellent".
func ratingLabel(_ rating: Int) -> String {
    switch rating {
    case 1: "Poor"
    case 2: "Fair"
    case 3: "Good"
    case 4: "Very good"
    case 5: "Excellent"
    default: "Tap a star to rate"
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingStars(rating: 3) { _ in }
        RatingStars(rating: 4, size: 18)
    }
}
