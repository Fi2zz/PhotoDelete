//
//  SettingsView.swift
//  PhotoDelete
//
//  Created by PhotoDelete Team on 11/7/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppConstants.hapticsEnabledKey) private var hapticsEnabled = true
    @AppStorage(AppConstants.appLanguageKey) private var appLanguageValue = AppLanguage.system.rawValue
    @AppStorage(AppConstants.leftSwipeActionKey) private var leftSwipeActionValue = SwipeGesturePreset.standard.leftAction.rawValue
    @AppStorage(AppConstants.rightSwipeActionKey) private var rightSwipeActionValue = SwipeGesturePreset.standard.rightAction.rawValue
    @AppStorage(AppConstants.upSwipeActionKey) private var upSwipeActionValue = SwipeGesturePreset.standard.upAction.rawValue
    @AppStorage(AppConstants.reviewVideoAutoPlayKey) private var reviewVideoAutoPlay = true
    @AppStorage(AppConstants.reviewLivePhotoAutoPlayKey) private var reviewLivePhotoAutoPlay = false
    @AppStorage(AppConstants.reviewSortOrderKey) private var reviewSortOrderValue = PhotoReviewSortOrder.newestFirst.rawValue
    @State private var activeSheet: SettingsSheet?
    @State private var settingsToast: PhotoDeleteToast?

    var body: some View {
        NavigationStack {
            ZStack {
                PhotoDeleteScreenBackground()

                ScrollView {
                    VStack(spacing: PhotoDeleteStyle.sectionSpacing) {
                        // 使用统计
                        statsSection

                        // 偏好设置
                        preferencesSection

                        // 关于与支持
                        aboutSection

                        // 版本信息
                        versionInfo

                        // 底部安全区域
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, PhotoDeleteStyle.screenHorizontalPadding)
                    .padding(.top, PhotoDeleteStyle.rootContentTopSpacing)
                    .frame(maxWidth: PhotoDeleteAdaptiveLayout.readableContentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                }

                if let settingsToast {
                    settingsToastView(settingsToast)
                }
            }
            .navigationTitle(L10n.string("设置"))
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .about:
                AboutView()
            case .privacy:
                PrivacyInfoView()
            case .gestureSettings:
                GestureSettingsView()
            case .languageSettings:
                LanguageSettingsView()
            }
        }
    }

    // MARK: - 使用统计
    private var statsSection: some View {
        let stats = dataManager.makeSettingsStatsSummary()

        return VStack(spacing: 16) {
            HStack {
                Text(L10n.string("使用统计"))
                    .photoDeleteSectionHeading()
                Spacer()
            }

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    StatCard(
                        value: "\(stats.totalAssets)",
                        label: L10n.string("照片"),
                        color: PhotoDeleteStyle.accent
                    )

                    StatCard(
                        value: "\(stats.organizedAssets)",
                        label: L10n.string("已整理"),
                        color: PhotoDeleteStyle.positive
                    )

                    StatCard(
                        value: "\(stats.deletedAssets)",
                        label: L10n.string("已删除"),
                        color: PhotoDeleteStyle.destructive
                    )

                    StatCard(
                        value: stats.formattedSpaceSaved,
                        label: L10n.string("删除内容"),
                        color: PhotoDeleteStyle.warning
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                SettingsStorageSummaryRow(storage: stats.storageSnapshot)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .photoDeleteCard()
        }
    }

    // MARK: - 关于与支持
    private var aboutSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L10n.string("关于与支持"))
                    .photoDeleteSectionHeading()
                Spacer()
            }

            VStack(spacing: 0) {
                SettingRow(
                    icon: "lock.shield",
                    iconColor: PhotoDeleteStyle.positive,
                    title: L10n.string("隐私说明"),
                    action: {
                        activeSheet = .privacy
                    }
                )

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                SettingRow(
                    icon: "info.circle",
                    iconColor: PhotoDeleteStyle.secondaryText,
                    title: L10n.string("关于删图"),
                    subtitle: L10n.string("版本 \(AppConstants.displayVersion)"),
                    action: {
                        activeSheet = .about
                    }
                )
            }
            .photoDeleteCard()
        }
    }

    // MARK: - 偏好设置
    private var preferencesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L10n.string("偏好设置"))
                    .photoDeleteSectionHeading()
                Spacer()
            }

            VStack(spacing: 0) {
                SettingRow(
                    icon: "hand.draw",
                    title: L10n.string("手势与播放"),
                    subtitle: gestureSettingsSubtitle,
                    action: {
                        activeSheet = .gestureSettings
                    }
                )

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                ReviewSortOrderSettingRow(selectedValue: $reviewSortOrderValue)

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                SettingRow(
                    icon: "globe",
                    title: L10n.string("语言"),
                    subtitle: selectedLanguage.title,
                    action: {
                        activeSheet = .languageSettings
                    }
                )

                SettingToggleRow(
                    icon: "hand.tap",
                    title: L10n.string("触感反馈"),
                    subtitle: L10n.string("滑动、撤销和归类时提供轻微反馈"),
                    isOn: $hapticsEnabled
                )

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                SettingRow(
                    icon: "photo.badge.checkmark",
                    title: L10n.string("照片访问权限"),
                    subtitle: photoAccessSubtitle,
                    action: {
                        dataManager.managePhotoLibraryAccessSettings()
                    }
                )
            }
            .photoDeleteCard()
        }
    }

    // MARK: - 版本信息
    private var versionInfo: some View {
        VStack(spacing: 8) {
            Text("\(AppConstants.appDisplayName) v\(AppConstants.displayVersion)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(PhotoDeleteStyle.secondaryText)

            Text(L10n.string("让照片整理变得简单"))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(PhotoDeleteStyle.tertiaryText)
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageValue) ?? .system
    }

    private func settingsToastView(_ toast: PhotoDeleteToast) -> some View {
        VStack {
            Spacer()
            PhotoDeleteToastView(toast: toast)
                .padding(.bottom, 96)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var photoAccessSubtitle: String {
        switch dataManager.photoLibraryManager.authorizationStatus {
        case .authorized:
            return L10n.string("全部照片")
        case .limited:
            return L10n.string("仅 \(dataManager.photoLibraryManager.totalPhotosCount) 张")
        case .denied, .restricted:
            return L10n.string("未授权")
        case .notDetermined:
            return L10n.string("未选择")
        @unknown default:
            return L10n.string("查看权限")
        }
    }

    private var gestureSettingsSubtitle: String {
        let left = "\(shortDirectionTitle(.left))\(shortActionTitle(currentGestureAction(for: .left)))"
        let right = "\(shortDirectionTitle(.right))\(shortActionTitle(currentGestureAction(for: .right)))"
        let up = "\(shortDirectionTitle(.up))\(shortActionTitle(currentGestureAction(for: .up)))"
        let videoPlayback = reviewVideoAutoPlay ? L10n.string("视频自动") : L10n.string("视频手动")
        let livePhotoPlayback = reviewLivePhotoAutoPlay ? L10n.string("实况自动") : L10n.string("实况手动")
        return "\(left) · \(right) · \(up) · \(videoPlayback) · \(livePhotoPlayback)"
    }

    private var usesChineseCompactText: Bool {
        switch selectedLanguage {
        case .zhHans, .zhHant:
            return true
        case .system:
            return Locale.autoupdatingCurrent.language.languageCode?.identifier == "zh"
        default:
            return false
        }
    }

    private func shortDirectionTitle(_ direction: SwipeGestureDirection) -> String {
        if usesChineseCompactText {
            switch direction {
            case .left:
                return L10n.string("左")
            case .right:
                return L10n.string("右")
            case .up:
                return L10n.string("上")
            }
        }

        switch direction {
        case .left:
            return "L"
        case .right:
            return "R"
        case .up:
            return "Up"
        }
    }

    private func shortActionTitle(_ action: SwipeGestureAction) -> String {
        if usesChineseCompactText {
            switch action {
            case .previous:
                return L10n.string("上张")
            case .next:
                return L10n.string("下张")
            case .close:
                return L10n.string("返回")
            case .delete:
                return L10n.string("删")
            case .keep:
                return L10n.string("留")
            case .favorite:
                return L10n.string("收藏")
            }
        }

        switch action {
        case .previous:
            return "Prev"
        case .next:
            return "Next"
        case .close:
            return "Back"
        case .delete:
            return "Delete"
        case .keep:
            return "Keep"
        case .favorite:
            return "Favorite"
        }
    }

    private func currentGestureAction(for direction: SwipeGestureDirection) -> SwipeGestureAction {
        switch direction {
        case .left:
            return SwipeGesturePreferences.normalizedAction(leftSwipeActionValue, fallback: SwipeGesturePreferences.defaultAction(for: .left))
        case .right:
            return SwipeGesturePreferences.normalizedAction(rightSwipeActionValue, fallback: SwipeGesturePreferences.defaultAction(for: .right))
        case .up:
            return SwipeGesturePreferences.normalizedAction(upSwipeActionValue, fallback: SwipeGesturePreferences.defaultAction(for: .up))
        }
    }

    private func showSettingsToast(_ message: String, icon: String, style: PhotoDeleteToastStyle) {
        let toast = PhotoDeleteToast(message: message, icon: icon, style: style)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            settingsToast = toast
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard settingsToast?.id == toast.id else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                settingsToast = nil
            }
        }
    }
}

private enum SettingsSheet: Identifiable {
    case about
    case privacy
    case gestureSettings
    case languageSettings

    var id: String {
        switch self {
        case .about: return "about"
        case .privacy: return "privacy"
        case .gestureSettings: return "gestureSettings"
        case .languageSettings: return "languageSettings"
        }
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .bold()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .allowsTightening(true)

            Text(label)
                .photoDeleteSecondaryLabel(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsStorageSummaryRow: View {
    let storage: DeviceStorageSnapshot

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "internaldrive")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PhotoDeleteStyle.accent)
                    .frame(width: 22)

                Text(L10n.string("手机存储空间"))
                    .photoDeletePrimaryLabel(.body.weight(.semibold))

                Spacer()

                Text("\(Int(storage.usedFraction * 100))%")
                    .photoDeleteSecondaryLabel(.subheadline.weight(.semibold))
            }

            ProgressView(value: storage.usedFraction)
                .progressViewStyle(LinearProgressViewStyle(tint: PhotoDeleteStyle.accent))
                .clipShape(Capsule(style: .continuous))

            HStack {
                Text(L10n.string("已用 \(storage.formattedUsed)"))
                Spacer()
                Text(L10n.string("可用 \(storage.formattedFree)"))
            }
            .font(.caption)
            .foregroundStyle(PhotoDeleteStyle.tertiaryText)
        }
    }
}

// MARK: - 设置行
struct SettingRow: View {
    let icon: String
    var iconColor: Color? = nil
    let title: String
    var subtitle = ""
    var showsChevron = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                PhotoDeleteIconTile(icon: icon, tint: iconColor)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        titleLabel
                        Spacer(minLength: 8)
                        subtitleLabel
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        titleLabel
                        subtitleLabel
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PhotoDeleteStyle.tertiaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: PhotoDeleteStyle.rowMinHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title.appLocalized))
        .accessibilityValue(Text(subtitle.appLocalized))
    }

    private var titleLabel: some View {
        Text(title.appLocalized)
            .photoDeletePrimaryLabel()
            .lineLimit(1)
    }

    @ViewBuilder
    private var subtitleLabel: some View {
        if !subtitle.isEmpty {
            Text(subtitle.appLocalized)
                .photoDeleteSecondaryLabel()
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .multilineTextAlignment(.trailing)
                .truncationMode(.tail)
        }
    }
}

struct SettingToggleRow: View {
    @Environment(\.photoDeleteTheme) private var theme
    let icon: String
    var iconColor: Color? = nil
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                PhotoDeleteIconTile(icon: icon, tint: iconColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title.appLocalized)
                        .photoDeletePrimaryLabel()
                        .lineLimit(1)

                    Text(subtitle.appLocalized)
                        .photoDeleteSecondaryLabel(.caption)
                        .lineLimit(2)
                }
            }
        }
        .tint(theme.selectionTint)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: PhotoDeleteStyle.rowMinHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReviewSortOrderSettingRow: View {
    @Binding var selectedValue: String

    private var selectedOrder: PhotoReviewSortOrder {
        PhotoReviewSortOrder.normalized(selectedValue)
    }

    var body: some View {
        Menu {
            ForEach(PhotoReviewSortOrder.allCases) { order in
                Button {
                    selectedValue = order.rawValue
                } label: {
                    Label(
                        order.title,
                        systemImage: order == selectedOrder ? "checkmark" : order.icon
                    )
                }
            }
        } label: {
            HStack(spacing: 12) {
                PhotoDeleteIconTile(icon: "arrow.up.arrow.down")

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.string("照片顺序"))
                        .photoDeletePrimaryLabel()
                        .lineLimit(1)

                    Text(selectedOrder.title)
                        .photoDeleteSecondaryLabel(.caption)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PhotoDeleteStyle.tertiaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: PhotoDeleteStyle.rowMinHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.string("照片顺序")))
        .accessibilityValue(Text(selectedOrder.title))
    }
}

struct RandomReviewBatchSizeSettingRow: View {
    @Binding var selectedValue: Int

    private var selectedSize: PhotoRandomReviewBatchSize {
        PhotoRandomReviewBatchSize.normalized(selectedValue)
    }

    var body: some View {
        Menu {
            ForEach(PhotoRandomReviewBatchSize.allCases) { size in
                Button {
                    selectedValue = size.rawValue
                } label: {
                    Label(
                        size.title,
                        systemImage: size == selectedSize ? "checkmark" : "photo.stack"
                    )
                }
            }
        } label: {
            HStack(spacing: 12) {
                PhotoDeleteIconTile(icon: "photo.stack")

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.string("每轮照片数量"))
                        .photoDeletePrimaryLabel()
                        .lineLimit(1)

                    Text(selectedSize.subtitle)
                        .photoDeleteSecondaryLabel(.caption)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PhotoDeleteStyle.tertiaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: PhotoDeleteStyle.rowMinHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.string("每轮照片数量")))
        .accessibilityValue(Text(selectedSize.subtitle))
        .accessibilityIdentifier("random-review-batch-size-setting")
    }
}

private struct AppPromotionRow: View {
    let imageName: String
    let title: String
    let subtitle: String
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(PhotoDeleteStyle.hairline, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .photoDeletePrimaryLabel()
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    Text(subtitle)
                        .photoDeleteSecondaryLabel(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }

                Spacer(minLength: 12)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PhotoDeleteStyle.tertiaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: PhotoDeleteStyle.rowMinHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(subtitle))
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - 手势设置
struct GestureSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppConstants.leftSwipeActionKey) private var leftSwipeActionValue = SwipeGesturePreset.standard.leftAction.rawValue
    @AppStorage(AppConstants.rightSwipeActionKey) private var rightSwipeActionValue = SwipeGesturePreset.standard.rightAction.rawValue
    @AppStorage(AppConstants.upSwipeActionKey) private var upSwipeActionValue = SwipeGesturePreset.standard.upAction.rawValue
    @AppStorage(AppConstants.reviewVideoAutoPlayKey) private var reviewVideoAutoPlay = true
    @AppStorage(AppConstants.reviewLivePhotoAutoPlayKey) private var reviewLivePhotoAutoPlay = false
    @AppStorage(AppConstants.reviewVideoMutedKey) private var reviewVideoMuted = true
    @AppStorage(AppConstants.reviewSortOrderKey) private var reviewSortOrderValue = PhotoReviewSortOrder.newestFirst.rawValue
    @AppStorage(AppConstants.hapticsEnabledKey) private var hapticsEnabled = true
    @AppStorage(AppConstants.randomReviewHideFiledPhotosKey) private var randomReviewHideFiledPhotos = true
    @AppStorage(AppConstants.randomReviewBatchSizeKey) private var randomReviewBatchSizeValue = PhotoRandomReviewBatchSize.defaultValue.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                PhotoDeleteScreenBackground()

                ScrollView {
                    VStack(spacing: PhotoDeleteStyle.sectionSpacing) {
                        reviewSortOrderSection
                        randomReviewSection
                        mediaPlaybackSection
                        currentGesturePreview
                        downSwipeNoteSection
                        presetSection
                        customGestureSection
                        resetButton
                    }
                    .padding(.horizontal, PhotoDeleteStyle.screenHorizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: PhotoDeleteAdaptiveLayout.readableContentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(L10n.string("手势与播放"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.string("完成")) {
                        dismiss()
                    }
                    .foregroundColor(PhotoDeleteStyle.accent)
                }
            }
        }
    }

    private var reviewSortOrderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("浏览顺序"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            ReviewSortOrderSettingRow(selectedValue: $reviewSortOrderValue)
                .photoDeleteCard()
        }
    }

    private var randomReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("随机浏览"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            VStack(spacing: 0) {
                RandomReviewBatchSizeSettingRow(selectedValue: $randomReviewBatchSizeValue)

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                SettingToggleRow(
                    icon: "rectangle.stack.badge.minus",
                    title: L10n.string("隐藏已归类照片"),
                    subtitle: L10n.string("默认不再显示已加入用户相册的照片"),
                    isOn: $randomReviewHideFiledPhotos
                )
            }
            .photoDeleteCard()
        }
    }

    private var mediaPlaybackSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("播放"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            VStack(spacing: 0) {
                SettingToggleRow(
                    icon: "play.circle",
                    title: L10n.string("视频自动播放"),
                    subtitle: L10n.string("只播放当前视频，切换后会自动停止"),
                    isOn: $reviewVideoAutoPlay
                )

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                SettingToggleRow(
                    icon: "livephoto",
                    title: L10n.string("实况照片自动播放"),
                    subtitle: L10n.string("进入当前照片时只播放一次，也可点右上角手动控制"),
                    isOn: $reviewLivePhotoAutoPlay
                )

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                SettingToggleRow(
                    icon: reviewVideoMuted ? "speaker.slash" : "speaker.wave.2",
                    title: L10n.string("视频和实况照片静音播放"),
                    subtitle: L10n.string("开启后每次进入整理页默认静音；整理页可临时打开声音"),
                    isOn: $reviewVideoMuted
                )

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.horizontal, 16)

                SettingToggleRow(
                    icon: "hand.tap",
                    title: L10n.string("触感反馈"),
                    subtitle: L10n.string("滑动、撤销和归类时提供轻微反馈"),
                    isOn: $hapticsEnabled
                )
            }
            .photoDeleteCard()
        }
    }

    private var currentGesturePreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("当前手势"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            HStack(spacing: 10) {
                ForEach(SwipeGestureDirection.allCases) { direction in
                    GesturePreviewTile(
                        direction: direction,
                        action: currentAction(for: direction)
                    )
                }
            }
        }
    }

    private var downSwipeNoteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("下滑动作"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            VStack(spacing: 0) {
                FixedGestureNoteRow(
                    icon: "arrow.down",
                    title: L10n.string("普通整理"),
                    detail: L10n.string("下滑返回列表")
                )

                Divider()
                    .background(PhotoDeleteStyle.hairline)
                    .padding(.leading, 60)

                FixedGestureNoteRow(
                    icon: "rectangle.stack.badge.minus",
                    title: L10n.string("相册整理"),
                    detail: L10n.string("下滑移出相册，不删除照片"),
                    color: PhotoDeleteStyle.warning
                )
            }
            .photoDeleteCard()
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("快速方案"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            VStack(spacing: 10) {
                ForEach(SwipeGesturePreset.presets) { preset in
                    GesturePresetButton(
                        preset: preset,
                        isSelected: matches(preset)
                    ) {
                        applyPreset(preset)
                    }
                }
            }
        }
    }

    private var customGestureSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("自定义"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)

            VStack(spacing: 0) {
                ForEach(SwipeGestureDirection.allCases) { direction in
                    GestureActionPickerRow(
                        direction: direction,
                        selectedAction: currentAction(for: direction),
                        onSelect: { action in
                            setAction(action, for: direction)
                        }
                    )

                    if direction != .up {
                        Divider()
                            .background(PhotoDeleteStyle.hairline)
                            .padding(.leading, 60)
                    }
                }
            }
            .photoDeleteCard()
        }
    }

    private var resetButton: some View {
        Button(action: {
            applyPreset(.standard)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                Text(L10n.string("恢复默认"))
            }
        }
        .photoDeleteSecondaryButton()
    }

    private func currentAction(for direction: SwipeGestureDirection) -> SwipeGestureAction {
        switch direction {
        case .left:
            return SwipeGesturePreferences.normalizedAction(leftSwipeActionValue, fallback: SwipeGesturePreferences.defaultAction(for: .left))
        case .right:
            return SwipeGesturePreferences.normalizedAction(rightSwipeActionValue, fallback: SwipeGesturePreferences.defaultAction(for: .right))
        case .up:
            return SwipeGesturePreferences.normalizedAction(upSwipeActionValue, fallback: SwipeGesturePreferences.defaultAction(for: .up))
        }
    }

    private func setAction(_ action: SwipeGestureAction, for direction: SwipeGestureDirection) {
        switch direction {
        case .left:
            leftSwipeActionValue = action.rawValue
        case .right:
            rightSwipeActionValue = action.rawValue
        case .up:
            upSwipeActionValue = action.rawValue
        }
        HapticManager.impact(.light)
    }

    private func applyPreset(_ preset: SwipeGesturePreset) {
        leftSwipeActionValue = preset.leftAction.rawValue
        rightSwipeActionValue = preset.rightAction.rawValue
        upSwipeActionValue = preset.upAction.rawValue
        HapticManager.impact(.light)
    }

    private func matches(_ preset: SwipeGesturePreset) -> Bool {
        currentAction(for: .left) == preset.leftAction &&
            currentAction(for: .right) == preset.rightAction &&
            currentAction(for: .up) == preset.upAction
    }
}

private struct GesturePreviewTile: View {
    let direction: SwipeGestureDirection
    let action: SwipeGestureAction

    var body: some View {
        VStack(spacing: 8) {
            PhotoDeleteIconTile(
                icon: direction.icon,
                tint: action.tint,
                size: 34,
                cornerRadius: 10
            )

            VStack(spacing: 3) {
                Text(direction.title.appLocalized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.primaryText)

                Text(action.title.appLocalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PhotoDeleteStyle.secondaryText)
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .photoDeleteCard()
    }
}

private struct FixedGestureNoteRow: View {
    let icon: String
    let title: String
    let detail: String
    var color = PhotoDeleteStyle.accent

    var body: some View {
        HStack(spacing: 12) {
            PhotoDeleteIconTile(icon: icon, tint: color, size: 36, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title.appLocalized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.primaryText)
                    .lineLimit(1)

                Text(detail.appLocalized)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(PhotoDeleteStyle.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

private struct GesturePresetButton: View {
    let preset: SwipeGesturePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(preset.title.appLocalized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.primaryText)
                    .lineLimit(1)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(isSelected ? PhotoDeleteStyle.positive : PhotoDeleteStyle.tertiaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: PhotoDeleteStyle.cardRadius, style: .continuous)
                    .fill(PhotoDeleteStyle.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: PhotoDeleteStyle.cardRadius, style: .continuous)
                            .stroke(isSelected ? PhotoDeleteStyle.positive.opacity(0.38) : PhotoDeleteStyle.hairline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(preset.subtitle.appLocalized))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(Text(isSelected ? L10n.string("已选") : L10n.string("未选择")))
    }
}

private struct GestureActionPickerRow: View {
    let direction: SwipeGestureDirection
    let selectedAction: SwipeGestureAction
    let onSelect: (SwipeGestureAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            PhotoDeleteIconTile(
                icon: direction.icon,
                tint: selectedAction.tint,
                size: 36,
                cornerRadius: 10
            )

            Text(direction.title.appLocalized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.primaryText)
                .lineLimit(1)

            Spacer()

            Menu {
                ForEach(SwipeGestureAction.configurableCases) { action in
                    Button {
                        onSelect(action)
                    } label: {
                        Label(action.detailTitle, systemImage: action == selectedAction ? "checkmark" : action.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedAction.title.appLocalized)
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(PhotoDeleteStyle.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(PhotoDeleteStyle.elevatedSurface)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(PhotoDeleteStyle.hairline, lineWidth: 1)
                        )
                    )
                .photoDeleteMinimumTapTarget()
            }
            .accessibilityLabel(Text("\(direction.title.appLocalized) \(L10n.string("手势"))"))
            .accessibilityValue(Text(selectedAction.title.appLocalized))
            .accessibilityHint(Text(selectedAction.detailTitle.appLocalized))
        }
        .padding(16)
    }
}

// MARK: - 语言设置
private struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppConstants.appLanguageKey) private var selectedLanguageID = AppLanguage.system.rawValue
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                PhotoDeleteScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.string("显示语言"))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(PhotoDeleteStyle.primaryText)

                            Text(L10n.string("默认跟随 iPhone 系统语言。也可以在这里固定删图的显示语言。"))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(PhotoDeleteStyle.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        searchField

                        languageList
                    }
                    .padding(.horizontal, PhotoDeleteStyle.screenHorizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: PhotoDeleteAdaptiveLayout.readableContentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(L10n.string("语言"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.string("完成")) {
                        dismiss()
                    }
                    .foregroundColor(PhotoDeleteStyle.accent)
                }
            }
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguageID) ?? .system
    }

    private var sortedLanguages: [AppLanguage] {
        AppLanguage.appLanguages.sorted {
            $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
    }

    private var visibleLanguages: [AppLanguage] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return [AppLanguage.system] + sortedLanguages
        }

        return [AppLanguage.system]
            .filter { matches($0, query: trimmedQuery) }
            + sortedLanguages.filter { matches($0, query: trimmedQuery) }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.secondaryText)

            TextField(L10n.string("搜索语言"), text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(PhotoDeleteStyle.primaryText)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(PhotoDeleteStyle.tertiaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.string("清除搜索")))
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(PhotoDeleteStyle.elevatedSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PhotoDeleteStyle.hairline, lineWidth: 1)
                )
        )
        .accessibilityHint(Text(L10n.string("按语言名称、地区或代码搜索")))
    }

    @ViewBuilder
    private var languageList: some View {
        if visibleLanguages.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.tertiaryText)

                Text(L10n.string("未找到匹配语言"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .photoDeleteCard()
        } else {
            VStack(spacing: 0) {
                ForEach(visibleLanguages) { language in
                    languageRow(language)

                    if language != visibleLanguages.last {
                        Divider()
                            .background(PhotoDeleteStyle.hairline)
                            .padding(.leading, 16)
                    }
                }
            }
            .photoDeleteCard()
        }
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            selectedLanguageID = language.rawValue
            HapticManager.impact(.light)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedLanguage == language ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(selectedLanguage == language ? PhotoDeleteStyle.positive : PhotoDeleteStyle.tertiaryText)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(language.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(PhotoDeleteStyle.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(language.detail)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(PhotoDeleteStyle.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)

                if language.isRightToLeft {
                    Text("RTL")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(PhotoDeleteStyle.secondaryText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(PhotoDeleteStyle.elevatedSurface)
                        )
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(language.title))
        .accessibilityHint(Text(language.detail))
        .accessibilityAddTraits(selectedLanguage == language ? .isSelected : [])
        .accessibilityValue(Text(selectedLanguage == language ? L10n.string("已选") : L10n.string("未选择")))
    }

    private func matches(_ language: AppLanguage, query: String) -> Bool {
        language.searchTokens.contains { token in
            token.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}

// MARK: - 作者介绍视图
struct PrivacyInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PhotoDeleteScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.string("隐私优先"))
                                .font(.title.weight(.semibold))
                                .foregroundStyle(PhotoDeleteStyle.primaryText)

                            Text(AppConstants.privacyShortText)
                                .photoDeleteSecondaryLabel(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(spacing: 12) {
                            PrivacyInfoRow(
                                icon: "iphone",
                                title: L10n.string("本机整理"),
                                detail: L10n.string("预览、待确认列表和删除确认都保存在你的设备上。")
                            )

                            PrivacyInfoRow(
                                icon: "icloud.slash",
                                title: L10n.string("不上传照片"),
                                detail: L10n.string("删图不接入自己的云端服务，也不会把照片发到服务器。")
                            )

                            PrivacyInfoRow(
                                icon: "person.crop.circle.badge.xmark",
                                title: L10n.string("不需要账号"),
                                detail: L10n.string("授权照片后即可使用，不需要注册或登录。")
                            )
                        }
                    }
                    .padding(.horizontal, PhotoDeleteStyle.screenHorizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(L10n.string("隐私"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.string("完成")) {
                        dismiss()
                    }
                    .foregroundColor(PhotoDeleteStyle.accent)
                }
            }
        }
    }
}

struct PrivacyInfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(PhotoDeleteStyle.accent)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(PhotoDeleteStyle.elevatedSurface)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .photoDeletePrimaryLabel(.body.weight(.semibold))

                Text(detail)
                    .photoDeleteSecondaryLabel(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .photoDeleteCard()
    }
}

// MARK: - 关于视图
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PhotoDeleteScreenBackground()

                ScrollView {
                    VStack(spacing: 32) {
                        // App图标
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(PhotoDeleteStyle.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(PhotoDeleteStyle.hairline, lineWidth: 1)
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(PhotoDeleteStyle.accent)
                        }

                        // App信息
                        VStack(spacing: 16) {
                            Text(AppConstants.appDisplayName)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(PhotoDeleteStyle.primaryText)

                            Text(L10n.string("版本 \(AppConstants.displayVersion)"))
                                .photoDeleteSecondaryLabel(.body)

                            Text(L10n.string("一个免费的相册整理工具。滑动判断照片去留，完成后再统一确认。"))
                                .photoDeleteSecondaryLabel(.body)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                    }
                    .padding(.horizontal, PhotoDeleteStyle.screenHorizontalPadding)
                    .padding(.top, 52)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(L10n.string("关于"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.string("完成")) {
                        dismiss()
                    }
                    .foregroundColor(PhotoDeleteStyle.accent)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager())
}
