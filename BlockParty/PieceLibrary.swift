import SwiftUI

/// A position on the board (or an offset within a piece), in row/column units.
struct GridPoint: Hashable, Codable {
    var row: Int
    var col: Int
}

/// The palette used for blocks. Bright, saturated, kid-friendly.
/// Raw values are persisted in saved games -- do not reorder cases.
enum BlockColor: Int, CaseIterable, Codable {
    case red, orange, yellow, green, teal, blue, purple, pink

    var base: Color {
        switch self {
        case .red:    return Color(red: 0.95, green: 0.33, blue: 0.36)
        case .orange: return Color(red: 0.98, green: 0.60, blue: 0.23)
        case .yellow: return Color(red: 0.99, green: 0.78, blue: 0.21)
        case .green:  return Color(red: 0.35, green: 0.80, blue: 0.42)
        case .teal:   return Color(red: 0.22, green: 0.76, blue: 0.78)
        case .blue:   return Color(red: 0.30, green: 0.56, blue: 0.96)
        case .purple: return Color(red: 0.58, green: 0.44, blue: 0.95)
        case .pink:   return Color(red: 0.95, green: 0.45, blue: 0.75)
        }
    }
}

/// One draggable piece: a set of block offsets normalized to a top-left origin.
struct Piece: Identifiable {
    let id = UUID()
    let blocks: [GridPoint]
    let color: BlockColor
    let rowCount: Int
    let colCount: Int

    init(blocks: [GridPoint], color: BlockColor) {
        self.blocks = blocks
        self.color = color
        self.rowCount = (blocks.map(\.row).max() ?? 0) + 1
        self.colCount = (blocks.map(\.col).max() ?? 0) + 1
    }

    /// Builds a piece from a pattern like ["X.", "XX"] where "X" is a block.
    init(pattern: [String], color: BlockColor) {
        var blocks: [GridPoint] = []
        for (r, line) in pattern.enumerated() {
            for (c, ch) in line.enumerated() where ch == "X" {
                blocks.append(GridPoint(row: r, col: c))
            }
        }
        self.init(blocks: blocks, color: color)
    }
}

enum PieceLibrary {
    private struct Template {
        let pattern: [String]
        let color: BlockColor
        let weight: Double
    }

    private static let templates: [Template] = [
        // Single
        Template(pattern: ["X"], color: .yellow, weight: 4),
        // Lines
        Template(pattern: ["XX"], color: .orange, weight: 3),
        Template(pattern: ["X", "X"], color: .orange, weight: 3),
        Template(pattern: ["XXX"], color: .orange, weight: 3),
        Template(pattern: ["X", "X", "X"], color: .orange, weight: 3),
        Template(pattern: ["XXXX"], color: .blue, weight: 2.5),
        Template(pattern: ["X", "X", "X", "X"], color: .blue, weight: 2.5),
        Template(pattern: ["XXXXX"], color: .red, weight: 1.5),
        Template(pattern: ["X", "X", "X", "X", "X"], color: .red, weight: 1.5),
        // Squares and rectangles
        Template(pattern: ["XX", "XX"], color: .yellow, weight: 4),
        Template(pattern: ["XXX", "XXX"], color: .green, weight: 2),
        Template(pattern: ["XX", "XX", "XX"], color: .green, weight: 2),
        Template(pattern: ["XXX", "XXX", "XXX"], color: .red, weight: 1.2),
        // Small corners (3 blocks)
        Template(pattern: ["X.", "XX"], color: .teal, weight: 2),
        Template(pattern: [".X", "XX"], color: .teal, weight: 2),
        Template(pattern: ["XX", "X."], color: .teal, weight: 2),
        Template(pattern: ["XX", ".X"], color: .teal, weight: 2),
        // L pieces (4 blocks)
        Template(pattern: ["X.", "X.", "XX"], color: .blue, weight: 1.5),
        Template(pattern: ["XXX", "X.."], color: .blue, weight: 1.5),
        Template(pattern: ["XX", ".X", ".X"], color: .blue, weight: 1.5),
        Template(pattern: ["..X", "XXX"], color: .blue, weight: 1.5),
        // T pieces
        Template(pattern: ["XXX", ".X."], color: .purple, weight: 1.5),
        Template(pattern: [".X", "XX", ".X"], color: .purple, weight: 1.5),
        Template(pattern: [".X.", "XXX"], color: .purple, weight: 1.5),
        Template(pattern: ["X.", "XX", "X."], color: .purple, weight: 1.5),
        // S / Z pieces
        Template(pattern: [".XX", "XX."], color: .pink, weight: 1.2),
        Template(pattern: ["XX.", ".XX"], color: .pink, weight: 1.2),
        Template(pattern: ["X.", "XX", ".X"], color: .pink, weight: 1.2),
        Template(pattern: [".X", "XX", "X."], color: .pink, weight: 1.2),
        // Big corners (5 blocks)
        Template(pattern: ["X..", "X..", "XXX"], color: .green, weight: 1),
        Template(pattern: ["XXX", "X..", "X.."], color: .green, weight: 1),
        Template(pattern: ["XXX", "..X", "..X"], color: .green, weight: 1),
        Template(pattern: ["..X", "..X", "XXX"], color: .green, weight: 1),
    ]

    private static let totalWeight = templates.reduce(0) { $0 + $1.weight }

    static func randomPiece() -> Piece {
        var target = Double.random(in: 0..<totalWeight)
        for template in templates {
            target -= template.weight
            if target < 0 {
                return Piece(pattern: template.pattern, color: template.color)
            }
        }
        let fallback = templates[0]
        return Piece(pattern: fallback.pattern, color: fallback.color)
    }
}
