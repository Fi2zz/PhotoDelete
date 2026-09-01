import SwiftUI

/// Shared row skeleton: a leading view (icon tile, thumbnail, nothing),
/// a title with optional subtitle, an optional trailing accessory view and
/// an optional chevron. Callers keep their own Button/Toggle/Menu wrappers,
/// accessibility and row-specific padding.
struct PhotoDeleteListRow<Leading: View, Accessory: View>: View {
    let title: String
    var subtitle: String? = nil
    var showsChevron: Bool = false
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(spacing: 12) {
            leading()

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .photoDeletePrimaryLabel()
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .photoDeleteSecondaryLabel()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }

            Spacer(minLength: 8)

            accessory()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PhotoDeleteStyle.tertiaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: PhotoDeleteStyle.rowMinHeight, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

extension PhotoDeleteListRow where Leading == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showsChevron: Bool = false,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            showsChevron: showsChevron,
            leading: { EmptyView() },
            accessory: accessory
        )
    }
}

extension PhotoDeleteListRow where Accessory == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showsChevron: Bool = false,
        @ViewBuilder leading: @escaping () -> Leading
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            showsChevron: showsChevron,
            leading: leading,
            accessory: { EmptyView() }
        )
    }
}
