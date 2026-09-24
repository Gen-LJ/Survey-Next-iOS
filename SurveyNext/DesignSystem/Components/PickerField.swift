import SwiftUI

/// A dropdown that looks like the text fields. Equivalent of an
/// `ExposedDropdownMenuBox`; on iOS it's a `Menu`.
struct PickerField<Item: Identifiable & Hashable>: View {
    let title: String
    let placeholder: String
    let items: [Item]
    @Binding var selection: Item?
    let label: (Item) -> String
    var error: String?
    var helper: String?
    var isDisabled = false

    var body: some View {
        FormField(title: title, error: error, helper: helper) {
            Menu {
                ForEach(items) { item in
                    Button {
                        selection = item
                    } label: {
                        if item == selection {
                            Label(label(item), systemImage: "checkmark")
                        } else {
                            Text(label(item))
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection.map(label) ?? placeholder)
                        .foregroundStyle(selection == nil ? Color.appOutline : Color.appOnSurface)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
                .contentShape(.rect)
            }
            .disabled(isDisabled)
            // Read as "Country, Myanmar" rather than just the current text.
            .accessibilityLabel(title)
            .accessibilityValue(selection.map(label) ?? placeholder)
        }
        .opacity(isDisabled ? 0.5 : 1)
    }
}
