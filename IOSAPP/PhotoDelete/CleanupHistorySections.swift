import SwiftUI

struct CleanupMonthlySummarySection: View {
    let summaries: [CleanupMonthlySummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("月度统计"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            if summaries.isEmpty {
                CleanupHistoryEmptyText(L10n.string("完成一次整理后，这里会出现月度记录。"))
            } else {
                VStack(spacing: 0) {
                    ForEach(summaries.prefix(6)) { summary in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(summary.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(PhotoDeleteStyle.primaryText)

                                Text(L10n.string("\(summary.sessions) 次 · 整理 \(summary.organizedPhotos) 张"))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(PhotoDeleteStyle.secondaryText)
                            }

                            Spacer()

                            Text(L10n.string("删除内容约 \(summary.formattedSpaceSaved)"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PhotoDeleteStyle.positive)
                        }
                        .padding(.vertical, 12)

                        if summary.id != summaries.prefix(6).last?.id {
                            CleanupHistoryDivider()
                        }
                    }
                }
            }
        }
        .padding(18)
        .photoDeleteCard()
    }
}

struct CleanupSessionHistorySection: View {
    let sessions: [CleanupSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("清理历史"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            if sessions.isEmpty {
                CleanupHistoryEmptyText(L10n.string("确认删除或收藏后，会在本机留下清理记录。"))
            } else {
                VStack(spacing: 0) {
                    ForEach(sessions) { session in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(PhotoDeleteStyle.positive)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.formattedDate)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(PhotoDeleteStyle.primaryText)

                                Text(L10n.string("删除 \(session.deletedPhotos) 张 · 收藏 \(session.favoritedPhotos) 张"))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(PhotoDeleteStyle.secondaryText)
                            }

                            Spacer()

                            Text(L10n.string("删除内容约 \(session.formattedSpaceSaved)"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(PhotoDeleteStyle.positive)
                        }
                        .padding(.vertical, 12)

                        if session.id != sessions.last?.id {
                            CleanupHistoryDivider()
                        }
                    }
                }
            }
        }
        .padding(18)
        .photoDeleteCard()
    }
}

struct CleanupHistoryDivider: View {
    var body: some View {
        Divider()
            .background(PhotoDeleteStyle.hairline)
            .padding(.leading, 16)
    }
}

private struct CleanupHistoryEmptyText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(PhotoDeleteStyle.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
