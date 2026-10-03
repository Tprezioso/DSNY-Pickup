import SwiftUI

/// A label and value side by side, stacked at accessibility text sizes so long values
/// (addresses, hours, DSNY routing times) get the full width instead of being squeezed.
struct DetailRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: LocalizedStringKey
    let value: String

    init(_ title: LocalizedStringKey, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
            }
            .accessibilityElement(children: .combine)
        } else {
            LabeledContent(title, value: value)
        }
    }
}

#Preview {
    List {
        DetailRow("Residential", value: "Daily: 8:00 AM - 9:00 AM and 6:00 PM - 7:00 PM")
    }
    .dynamicTypeSize(.accessibility3)
}
