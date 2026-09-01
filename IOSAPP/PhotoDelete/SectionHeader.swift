import SwiftUI

/// Standard section header: leading title with an optional subtitle below
/// and an optional trailing action button.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var actionIcon: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.primaryText)

                Spacer()

                if let actionTitle, let action {
                    Button(action: action) {
                        HStack(spacing: 4) {
                            if let actionIcon {
                                Image(systemName: actionIcon)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Text(actionTitle)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(PhotoDeleteStyle.accent)
                    }
                    .buttonStyle(.plain)
                    .photoDeleteMinimumTapTarget()
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(PhotoDeleteStyle.secondaryText)
            }
        }
        .padding(.horizontal, 2)
    }
}
