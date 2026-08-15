import SwiftUI

/// A color theme: remaps the eight logical block colors and the background
/// gradient. Game logic always works in BlockColor terms; themes only change
/// how those colors are rendered.
enum Theme: String, CaseIterable, Identifiable {
    case classic, ocean, candy, pastel

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .ocean:   return "Ocean"
        case .candy:   return "Candy"
        case .pastel:  return "Pastel"
        }
    }

    /// Top and bottom of the background gradient.
    var background: [Color] {
        switch self {
        case .classic: return [Color(red: 0.33, green: 0.20, blue: 0.62),
                               Color(red: 0.14, green: 0.12, blue: 0.35)]
        case .ocean:   return [Color(red: 0.05, green: 0.24, blue: 0.45),
                               Color(red: 0.02, green: 0.10, blue: 0.24)]
        case .candy:   return [Color(red: 0.55, green: 0.16, blue: 0.45),
                               Color(red: 0.24, green: 0.08, blue: 0.30)]
        case .pastel:  return [Color(red: 0.46, green: 0.41, blue: 0.72),
                               Color(red: 0.25, green: 0.24, blue: 0.45)]
        }
    }

    func color(for block: BlockColor) -> Color {
        palette[block.rawValue]
    }

    /// Block colors in BlockColor case order: red, orange, yellow, green,
    /// teal, blue, purple, pink.
    private var palette: [Color] {
        switch self {
        case .classic:
            return BlockColor.allCases.map(\.base)
        case .ocean:
            return [Color(red: 0.98, green: 0.45, blue: 0.42),
                    Color(red: 0.97, green: 0.68, blue: 0.35),
                    Color(red: 0.99, green: 0.85, blue: 0.45),
                    Color(red: 0.30, green: 0.78, blue: 0.56),
                    Color(red: 0.22, green: 0.80, blue: 0.82),
                    Color(red: 0.30, green: 0.62, blue: 0.98),
                    Color(red: 0.55, green: 0.50, blue: 0.95),
                    Color(red: 0.95, green: 0.55, blue: 0.70)]
        case .candy:
            return [Color(red: 0.98, green: 0.30, blue: 0.40),
                    Color(red: 1.00, green: 0.62, blue: 0.40),
                    Color(red: 1.00, green: 0.83, blue: 0.30),
                    Color(red: 0.45, green: 0.85, blue: 0.40),
                    Color(red: 0.35, green: 0.88, blue: 0.75),
                    Color(red: 0.40, green: 0.55, blue: 0.98),
                    Color(red: 0.70, green: 0.45, blue: 0.98),
                    Color(red: 1.00, green: 0.50, blue: 0.80)]
        case .pastel:
            return [Color(red: 0.96, green: 0.60, blue: 0.60),
                    Color(red: 0.98, green: 0.75, blue: 0.55),
                    Color(red: 0.99, green: 0.88, blue: 0.60),
                    Color(red: 0.65, green: 0.88, blue: 0.68),
                    Color(red: 0.60, green: 0.88, blue: 0.88),
                    Color(red: 0.62, green: 0.75, blue: 0.98),
                    Color(red: 0.78, green: 0.70, blue: 0.96),
                    Color(red: 0.96, green: 0.72, blue: 0.86)]
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .classic
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
