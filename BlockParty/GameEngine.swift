import SwiftUI

/// All game rules and state: the 8x8 board, the tray of three pieces,
/// scoring, line clearing, and game-over detection.
final class GameEngine: ObservableObject {
    static let size = 8
    static let cellCount = size * size

    /// nil = empty cell; otherwise the color of the block occupying it.
    @Published private(set) var cells: [BlockColor?] = Array(repeating: nil, count: GameEngine.cellCount)
    /// Three slots; a slot becomes nil once its piece is placed.
    @Published private(set) var tray: [Piece?] = [nil, nil, nil]
    @Published private(set) var score = 0
    @Published private(set) var highScore: Int
    @Published private(set) var isGameOver = false
    /// Consecutive placements that cleared at least one line.
    @Published private(set) var streak = 0
    /// Cells mid clear-animation: still occupied, but shrinking away on screen.
    @Published private(set) var clearingCells: Set<Int> = []
    /// Transient "+120 Combo x2!" message shown above the board.
    @Published private(set) var eventText: String?

    /// High score at the start of the current game, for "New Best!" detection.
    private(set) var previousBest: Int

    private var eventToken = 0
    private static let highScoreKey = "highScore"

    init() {
        let saved = UserDefaults.standard.integer(forKey: Self.highScoreKey)
        highScore = saved
        previousBest = saved
        refillTray()
    }

    static func index(_ row: Int, _ col: Int) -> Int {
        row * size + col
    }

    func canPlace(_ piece: Piece, at origin: GridPoint) -> Bool {
        for block in piece.blocks {
            let r = origin.row + block.row
            let c = origin.col + block.col
            guard r >= 0, r < Self.size, c >= 0, c < Self.size,
                  cells[Self.index(r, c)] == nil else { return false }
        }
        return true
    }

    func canPlaceAnywhere(_ piece: Piece) -> Bool {
        for r in 0..<Self.size {
            for c in 0..<Self.size where canPlace(piece, at: GridPoint(row: r, col: c)) {
                return true
            }
        }
        return false
    }

    /// The cells that would clear if this piece were placed here (for the drag preview).
    func previewClears(_ piece: Piece, at origin: GridPoint) -> Set<Int> {
        var simulated = cells
        for block in piece.blocks {
            simulated[Self.index(origin.row + block.row, origin.col + block.col)] = piece.color
        }
        let lines = fullLines(in: simulated)
        return cellIndices(rows: lines.rows, cols: lines.cols)
    }

    @discardableResult
    func place(trayIndex: Int, at origin: GridPoint) -> Bool {
        guard !isGameOver,
              let piece = tray[trayIndex],
              canPlace(piece, at: origin) else { return false }

        withAnimation(.easeOut(duration: 0.15)) {
            for block in piece.blocks {
                cells[Self.index(origin.row + block.row, origin.col + block.col)] = piece.color
            }
            tray[trayIndex] = nil
            score += piece.blocks.count
        }

        let lines = fullLines(in: cells)
        let lineCount = lines.rows.count + lines.cols.count

        if lineCount > 0 {
            streak += 1
            let gained = 10 * lineCount * lineCount * streak
            score += gained
            showEvent(lineCount: lineCount, gained: gained)
            Haptics.clear()

            let toClear = cellIndices(rows: lines.rows, cols: lines.cols)
            clearingCells = toClear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                guard let self else { return }
                for i in toClear { self.cells[i] = nil }
                self.clearingCells = []
                self.finishTurn()
            }
        } else {
            streak = 0
            Haptics.place()
            finishTurn()
        }

        if score > highScore {
            highScore = score
            UserDefaults.standard.set(score, forKey: Self.highScoreKey)
        }
        return true
    }

    func newGame() {
        withAnimation(.easeOut(duration: 0.25)) {
            cells = Array(repeating: nil, count: Self.cellCount)
            score = 0
            streak = 0
            isGameOver = false
            clearingCells = []
            eventText = nil
            previousBest = highScore
            refillTray()
        }
    }

    // MARK: - Private helpers

    private func refillTray() {
        for i in 0..<tray.count {
            tray[i] = PieceLibrary.randomPiece()
        }
    }

    private func finishTurn() {
        if tray.allSatisfy({ $0 == nil }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                refillTray()
            }
        }
        let remaining = tray.compactMap { $0 }
        if !remaining.isEmpty && !remaining.contains(where: canPlaceAnywhere) {
            withAnimation(.easeIn(duration: 0.3)) {
                isGameOver = true
            }
            Haptics.gameOver()
        }
    }

    private func fullLines(in grid: [BlockColor?]) -> (rows: [Int], cols: [Int]) {
        var rows: [Int] = []
        var cols: [Int] = []
        for r in 0..<Self.size where (0..<Self.size).allSatisfy({ grid[Self.index(r, $0)] != nil }) {
            rows.append(r)
        }
        for c in 0..<Self.size where (0..<Self.size).allSatisfy({ grid[Self.index($0, c)] != nil }) {
            cols.append(c)
        }
        return (rows, cols)
    }

    private func cellIndices(rows: [Int], cols: [Int]) -> Set<Int> {
        var out = Set<Int>()
        for r in rows {
            for c in 0..<Self.size { out.insert(Self.index(r, c)) }
        }
        for c in cols {
            for r in 0..<Self.size { out.insert(Self.index(r, c)) }
        }
        return out
    }

    private func showEvent(lineCount: Int, gained: Int) {
        var text = "+\(gained)"
        if streak >= 2 {
            text += "  Combo ×\(streak)!"
        } else if lineCount >= 2 {
            text += "  \(lineCount) lines!"
        }
        eventToken += 1
        let token = eventToken
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            eventText = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self, self.eventToken == token else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                self.eventText = nil
            }
        }
    }
}
