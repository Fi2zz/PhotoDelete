import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// Single fixed look: the former default sage palette. Theme switching was
// removed for the personal build; appearance (light/dark/system) still applies.
enum PhotoDeleteTheme: String, CaseIterable, Identifiable, Equatable {
    // REASON: keeping the enum + environment API so the ~200 `theme.xxx` color
    // call sites keep compiling; collapsed to one case when theme selection
    // was removed. Clean up by inlining the palette if the environment is
    // ever refactored away.
    case sage

    static let defaultTheme: PhotoDeleteTheme = .sage

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

    var swatches: [Color] {
        [primaryAccent, secondaryAccent, backgroundBottom]
    }

    #if canImport(UIKit)
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
    #endif

    private var palette: PhotoDeleteThemePalette {
        PhotoDeleteThemePalette(
            backgroundTop: .init(light: .init(0.982, 0.980, 0.944), dark: .init(0.044, 0.052, 0.047)),
            backgroundBottom: .init(light: .init(0.900, 0.928, 0.886), dark: .init(0.032, 0.038, 0.035)),
            surface: .init(light: .init(1, 1, 1, 0.82), dark: .init(1, 1, 1, 0.075)),
            elevatedSurface: .init(light: .init(1, 1, 1, 0.92), dark: .init(1, 1, 1, 0.11)),
            cardStroke: .init(light: .init(0.22, 0.42, 0.34, 0.11), dark: .init(1, 1, 1, 0.115)),
            hairline: .init(light: .init(0.22, 0.42, 0.34, 0.14), dark: .init(1, 1, 1, 0.115)),
            floatingShadow: .init(light: .init(0, 0, 0, 0.07), dark: .init(0, 0, 0, 0.24)),
            primaryAccent: .init(light: .init(0.18, 0.39, 0.31), dark: .init(0.62, 0.84, 0.72)),
            primaryAccentPressed: .init(light: .init(0.12, 0.30, 0.23), dark: .init(0.50, 0.72, 0.60)),
            primaryAccentOnFill: .init(light: .init(1, 1, 1), dark: .init(0.03, 0.04, 0.035)),
            secondaryAccent: .init(light: .init(0.62, 0.52, 0.30), dark: .init(0.86, 0.78, 0.52)),
            success: .init(light: .init(0.13, 0.46, 0.26), dark: .init(0.58, 0.88, 0.66)),
            warning: .init(light: .init(0.70, 0.48, 0.12), dark: .init(0.95, 0.78, 0.43)),
            danger: .init(light: .init(0.78, 0.16, 0.13), dark: .init(1.00, 0.44, 0.40)),
            favorite: .init(light: .init(0.76, 0.22, 0.42), dark: .init(1.00, 0.62, 0.74))
        )
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
    let light: PhotoDeleteRGBA
    let dark: PhotoDeleteRGBA

    init(light: PhotoDeleteRGBA, dark: PhotoDeleteRGBA) {
        self.light = light
        self.dark = dark
    }

    var color: Color {
        #if canImport(UIKit)
        Color(uiColor: uiColor)
        #else
        Color(red: light.red, green: light.green, blue: light.blue).opacity(light.alpha)
        #endif
    }

    #if canImport(UIKit)
    var uiColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark.uiColor : light.uiColor
        }
    }
    #endif
}

private struct PhotoDeleteRGBA {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    #if canImport(UIKit)
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    #endif
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
