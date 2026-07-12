import SwiftUI

struct GameView: View {
    @StateObject private var engine = GameEngine()
    @AppStorage("shuffleEnabled") private var shuffleEnabled = false

    /// Which tray slot is being dragged, if any.
    @State private var dragIndex: Int?
    /// Finger location in global (screen) coordinates.
    @State private var dragLocation: CGPoint = .zero
    /// The board grid's frame in global (screen) coordinates.
    @State private var boardFrame: CGRect = .zero
    @State private var showSettings = false

    /// How far the dragged piece floats above the finger, so it isn't hidden by it.
    private let liftOffset: CGFloat = 45

    var body: some View {
        GeometryReader { proxy in
            let boardSide = min(proxy.size.width - 32, 440)
            let cellSize = (boardSide - 12) / CGFloat(GameEngine.size)
            let rootOrigin = proxy.frame(in: .global).origin

            ZStack {
                LinearGradient(colors: [Color(red: 0.33, green: 0.20, blue: 0.62),
                                        Color(red: 0.14, green: 0.12, blue: 0.35)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    header
                    eventBanner
                    BoardView(engine: engine,
                              cellSize: cellSize,
                              preview: placementPreview(cellSize: cellSize),
                              gridFrame: $boardFrame)
                    Spacer(minLength: 10)
                    trayArea(cellSize: cellSize)
                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if let piece = floatingPiece {
                    PieceView(piece: piece, cellSize: cellSize)
                        .position(x: dragLocation.x - rootOrigin.x,
                                  y: dragLocation.y - CGFloat(piece.rowCount) * cellSize / 2
                                      - liftOffset - rootOrigin.y)
                        .allowsHitTesting(false)
                        .shadow(color: .black.opacity(0.35), radius: 10, y: 8)
                }

                if engine.isGameOver {
                    GameOverView(engine: engine)
                        .transition(.opacity)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet { engine.newGame() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("SCORE")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(engine.score)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.25), value: engine.score)
            }
            HStack {
                Label("\(engine.highScore)", systemImage: "crown.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(.white.opacity(0.12)))
                Spacer()
                if shuffleEnabled {
                    Button {
                        Haptics.pickUp()
                        engine.shuffleTray()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.12)))
                    }
                }
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(.white.opacity(0.12)))
                }
            }
        }
    }

    private var eventBanner: some View {
        ZStack {
            if let text = engine.eventText {
                Text(text)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.yellow)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 30)
    }

    // MARK: - Tray

    private func trayArea(cellSize: CGFloat) -> some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    if let piece = engine.tray[i] {
                        PieceView(piece: piece, cellSize: trayCellSize(for: piece))
                            .opacity(dragIndex == i ? 0 : 1)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(dragGesture(for: i, cellSize: cellSize))
            }
        }
    }

    private func trayCellSize(for piece: Piece) -> CGFloat {
        let maxDimension = CGFloat(max(piece.rowCount, piece.colCount))
        return min(18, 84 / maxDimension)
    }

    // MARK: - Drag handling

    private var floatingPiece: Piece? {
        guard let dragIndex else { return nil }
        return engine.tray[dragIndex]
    }

    /// Finds the best legal cell for the floating piece, with a little magnetism:
    /// the nearest valid cell within about one cell of the piece's position wins.
    private func dropTarget(cellSize: CGFloat) -> (piece: Piece, origin: GridPoint)? {
        guard let piece = floatingPiece, boardFrame.width > 0, cellSize > 0 else { return nil }
        let width = CGFloat(piece.colCount) * cellSize
        let height = CGFloat(piece.rowCount) * cellSize
        // Top-left corner of the piece as drawn on screen (lifted above the finger).
        let topLeft = CGPoint(x: dragLocation.x - width / 2,
                              y: dragLocation.y - height - liftOffset)
        // Convert to grid units using the measured on-screen cell size, so the
        // math can never drift from what is actually rendered.
        let measuredCell = boardFrame.width / CGFloat(GameEngine.size)
        let exactCol = (topLeft.x - boardFrame.minX) / measuredCell
        let exactRow = (topLeft.y - boardFrame.minY) / measuredCell

        var best: GridPoint?
        var bestDistance: CGFloat = 0.95
        for row in Int(exactRow.rounded(.down))...Int(exactRow.rounded(.up)) {
            for col in Int(exactCol.rounded(.down))...Int(exactCol.rounded(.up)) {
                let origin = GridPoint(row: row, col: col)
                guard engine.canPlace(piece, at: origin) else { continue }
                let distance = hypot(exactRow - CGFloat(row), exactCol - CGFloat(col))
                if distance < bestDistance {
                    bestDistance = distance
                    best = origin
                }
            }
        }
        guard let best else { return nil }
        return (piece, best)
    }

    private func placementPreview(cellSize: CGFloat) -> PlacementPreview? {
        guard let (piece, origin) = dropTarget(cellSize: cellSize) else { return nil }
        let indices = Set(piece.blocks.map {
            GameEngine.index(origin.row + $0.row, origin.col + $0.col)
        })
        return PlacementPreview(piece: piece,
                                origin: origin,
                                cellIndices: indices,
                                clearIndices: engine.previewClears(piece, at: origin))
    }

    private func dragGesture(for i: Int, cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard engine.tray[i] != nil, !engine.isGameOver else { return }
                if dragIndex == nil {
                    Haptics.pickUp()
                    Sounds.pickUp()
                }
                dragIndex = i
                dragLocation = value.location
            }
            .onEnded { value in
                guard dragIndex == i else { return }
                dragLocation = value.location
                if let target = dropTarget(cellSize: cellSize) {
                    engine.place(trayIndex: i, at: target.origin)
                    dragIndex = nil
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragIndex = nil
                    }
                }
            }
    }
}

// MARK: - Settings

struct SettingsSheet: View {
    @AppStorage("shuffleEnabled") private var shuffleEnabled = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @Environment(\.dismiss) private var dismiss
    let onRestart: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Sounds", isOn: $soundEnabled)
                }
                Section {
                    Toggle("Shuffle button", isOn: $shuffleEnabled)
                } footer: {
                    Text("Adds a button that swaps the current pieces for new ones. Makes the game easier.")
                }
                Section {
                    Button("Restart Game", role: .destructive) {
                        onRestart()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    GameView()
}
