import SwiftUI
import UIKit

// Single fixed look: iOS system colors on a monochrome black/white accent.
// Theme switching was removed for the personal build; appearance
// (light/dark/system) still applies.
enum PhotoDeleteTheme: String, CaseIterable, Identifiable, Equatable {
    // REASON: keeping the enum + environment API so the ~200 `theme.xxx` color
    // call sites keep compiling; collapsed to one case when theme selection
    // was removed. Clean up by inlining the palette if the environment is
    // ever refactored away.
    case system

    static let defaultTheme: PhotoDeleteTheme = .system

    var id: String { rawValue }

    static var current: PhotoDeleteTheme { .defaultTheme }

    var backgroundTop: Color { palette.backgroundTop.color }
    var backgroundBottom: Color { palette.backgroundBottom.color }
    var surface: Color { palette.surface.color }
    var elevatedSurface: Color { palette.elevatedSurface.color }
    var cardStroke: Color { palette.cardStroke.color }
    var hairline: Color { palette.hairline.color }
    var floatingShadow: Color { palette.floatingShadow.color }

    var primaryAccent: Color { palette.primaryAccent.color }
    var primaryAccentPressed: Color { palette.primaryAccentPressed.color }
    var primaryAccentOnFill: Color { palette.primaryAccentOnFill.color }
    var primaryAccentSoftFill: Color { primaryAccent.opacity(0.14) }
    var primaryAccentSoftStroke: Color { primaryAccent.opacity(0.22) }
    var secondaryAccent: Color { palette.secondaryAccent.color }
    var secondaryAccentSoftFill: Color { secondaryAccent.opacity(0.14) }

    var success: Color { palette.success.color }
    var successSoftFill: Color { success.opacity(0.14) }
    var warning: Color { palette.warning.color }
    var warningSoftFill: Color { warning.opacity(0.14) }
    var danger: Color { palette.danger.color }
    var dangerSoftFill: Color { danger.opacity(0.14) }
    var favorite: Color { palette.favorite.color }

    var buttonPrimaryFill: Color { primaryAccent }
    var buttonPrimaryText: Color { primaryAccentOnFill }
    var buttonSecondaryFill: Color { surface }
    var buttonSecondaryText: Color { primaryAccent }
    var buttonSecondaryStroke: Color { primaryAccentSoftStroke }
    var toolbarAction: Color { primaryAccent }
    var tabSelected: Color { primaryAccent }
    var progressTint: Color { primaryAccent }
    var selectionTint: Color { primaryAccent }
    var searchFieldFill: Color { elevatedSurface }
    var searchFieldStroke: Color { primaryAccentSoftStroke }
    var iconTileFill: Color { primaryAccentSoftFill }
    var iconTileStroke: Color { primaryAccentSoftStroke }
    var navigationTint: Color { primaryAccent }

    var readableAccent: Color { primaryAccent }
    var warmAccent: Color { secondaryAccent }
    var primaryButtonText: Color { buttonPrimaryText }

    var uiBackground: UIColor { palette.backgroundBottom.uiColor }
    var uiSurface: UIColor { palette.surface.uiColor }
    var uiHairline: UIColor { palette.hairline.uiColor }
    var uiAccent: UIColor { palette.primaryAccent.uiColor }
    var uiTabSelected: UIColor { palette.primaryAccent.uiColor }
    var uiPrimaryButtonText: UIColor { palette.primaryAccentOnFill.uiColor }
    var uiDanger: UIColor { palette.danger.uiColor }
    var uiFavorite: UIColor { palette.favorite.uiColor }
    var uiSuccess: UIColor { palette.success.uiColor }
    var uiSecondaryText: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.58)
                : UIColor.secondaryLabel
        }
    }

    private var palette: PhotoDeleteThemePalette {
        PhotoDeleteThemePalette(
            backgroundTop: .init(ui: .systemGroupedBackground),
            backgroundBottom: .init(ui: .systemGroupedBackground),
            surface: .init(ui: .secondarySystemGroupedBackground),
            elevatedSurface: .init(ui: .tertiarySystemGroupedBackground),
            cardStroke: .init(ui: .separator),
            hairline: .init(ui: .separator),
            floatingShadow: .init(ui: UIColor.black.withAlphaComponent(0.12)),
            primaryAccent: .init(ui: monochromeAccent),
            primaryAccentPressed: .init(ui: monochromeAccentPressed),
            primaryAccentOnFill: .init(ui: monochromeOnAccent),
            secondaryAccent: .init(ui: .systemGray),
            success: .init(ui: .systemGreen),
            warning: .init(ui: .systemOrange),
            danger: .init(ui: .systemRed),
            favorite: .init(ui: .systemPink)
        )
    }

    private var monochromeAccent: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : .black
        }
    }

    private var monochromeAccentPressed: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.82, alpha: 1)
                : UIColor(white: 0.2, alpha: 1)
        }
    }

    private var monochromeOnAccent: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? .black : .white
        }
    }
}

private struct PhotoDeleteThemePalette {
    let backgroundTop: PhotoDeleteThemeColor
    let backgroundBottom: PhotoDeleteThemeColor
    let surface: PhotoDeleteThemeColor
    let elevatedSurface: PhotoDeleteThemeColor
    let cardStroke: PhotoDeleteThemeColor
    let hairline: PhotoDeleteThemeColor
    let floatingShadow: PhotoDeleteThemeColor
    let primaryAccent: PhotoDeleteThemeColor
    let primaryAccentPressed: PhotoDeleteThemeColor
    let primaryAccentOnFill: PhotoDeleteThemeColor
    let secondaryAccent: PhotoDeleteThemeColor
    let success: PhotoDeleteThemeColor
    let warning: PhotoDeleteThemeColor
    let danger: PhotoDeleteThemeColor
    let favorite: PhotoDeleteThemeColor
}

private struct PhotoDeleteThemeColor {
    let ui: UIColor

    var color: Color {
        Color(uiColor: ui)
    }

    var uiColor: UIColor {
        ui
    }
}

private struct PhotoDeleteThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: PhotoDeleteTheme = .defaultTheme
}

extension EnvironmentValues {
    var photoDeleteTheme: PhotoDeleteTheme {
        get { self[PhotoDeleteThemeEnvironmentKey.self] }
        set { self[PhotoDeleteThemeEnvironmentKey.self] = newValue }
    }
}
