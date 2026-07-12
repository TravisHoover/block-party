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
    /// Cells in the brief "punch" flash right before they shrink away.
    @Published private(set) var poppingCells: Set<Int> = []
    /// Cells mid clear-animation: still occupied, but shrinking away on screen.
    @Published private(set) var clearingCells: Set<Int> = []
    /// Briefly true on a 2+ line streak, for a whole-board "thump".
    @Published private(set) var comboPulse = false
    /// Transient "+120 Combo x2!" message shown above the board.
    @Published private(set) var eventText: String?

    /// High score at the start of the current game, for "New Best!" detection.
    private(set) var previousBest: Int

    private var eventToken = 0
    private static let highScoreKey = "highScore"
    private static let savedGameKey = "savedGame"
    /// Quick bright flash before the shrink -- keep this snappy.
    private static let popDuration: TimeInterval = 0.09
    private static let clearDuration: TimeInterval = 0.21

    /// On-disk snapshot of a game in progress, restored on next launch.
    private struct SavedGame: Codable {
        struct SavedPiece: Codable {
            var blocks: [GridPoint]
            var color: BlockColor
        }
        /// One entry per cell: a BlockColor raw value, or -1 for empty.
        var cells: [Int]
        var tray: [SavedPiece?]
        var score: Int
        var streak: Int
    }

    init() {
        let saved = UserDefaults.standard.integer(forKey: Self.highScoreKey)
        highScore = saved
        previousBest = saved
        if !restoreSavedGame() {
            refillTray()
        }
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

            if streak >= 2 {
                comboPulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.comboPulse = false
                }
            }

            let toClear = cellIndices(rows: lines.rows, cols: lines.cols)
            poppingCells = toClear
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.popDuration) { [weak self] in
                guard let self else { return }
                self.poppingCells = []
                self.clearingCells = toClear
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.popDuration + Self.clearDuration) { [weak self] in
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
        saveState()
        return true
    }

    /// Swaps the remaining tray pieces for fresh random ones (the optional
    /// "easy mode" helper). Deliberately never triggers game over — the player
    /// can shuffle again if the new pieces don't fit either.
    func shuffleTray() {
        guard !isGameOver else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            for i in 0..<tray.count where tray[i] != nil {
                tray[i] = PieceLibrary.randomPiece()
            }
        }
        saveState()
    }

    func newGame() {
        withAnimation(.easeOut(duration: 0.25)) {
            cells = Array(repeating: nil, count: Self.cellCount)
            score = 0
            streak = 0
            isGameOver = false
            poppingCells = []
            clearingCells = []
            comboPulse = false
            eventText = nil
            previousBest = highScore
            refillTray()
        }
        saveState()
    }

    // MARK: - Private helpers

    /// Returns true if a valid in-progress game was restored.
    private func restoreSavedGame() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.savedGameKey),
              let saved = try? JSONDecoder().decode(SavedGame.self, from: data),
              saved.cells.count == Self.cellCount,
              saved.tray.count == tray.count else { return false }
        cells = saved.cells.map { $0 >= 0 ? BlockColor(rawValue: $0) : nil }
        tray = saved.tray.map { piece in
            piece.map { Piece(blocks: $0.blocks, color: $0.color) }
        }
        score = saved.score
        streak = saved.streak
        if tray.allSatisfy({ $0 == nil }) {
            refillTray()
        }
        return true
    }

    private func saveState() {
        guard !isGameOver else {
            UserDefaults.standard.removeObject(forKey: Self.savedGameKey)
            return
        }
        let saved = SavedGame(
            cells: cells.map { $0?.rawValue ?? -1 },
            tray: tray.map { piece in
                piece.map { SavedGame.SavedPiece(blocks: $0.blocks, color: $0.color) }
            },
            score: score,
            streak: streak
        )
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.savedGameKey)
        }
    }

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
        saveState()
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
