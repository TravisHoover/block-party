import SwiftUI

struct GameView: View {
    @StateObject private var engine = GameEngine()

    /// Which tray slot is being dragged, if any.
    @State private var dragIndex: Int?
    /// Finger location in the "game" coordinate space.
    @State private var dragLocation: CGPoint = .zero
    /// The board grid's frame in the "game" coordinate space.
    @State private var boardFrame: CGRect = .zero

    /// How far the dragged piece floats above the finger, so it isn't hidden by it.
    private let liftOffset: CGFloat = 45

    var body: some View {
        GeometryReader { proxy in
            let boardSide = min(proxy.size.width - 32, 440)
            let cellSize = (boardSide - 12) / CGFloat(GameEngine.size)

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
                              preview: placementPreview(cellSize: cellSize))
                    Spacer(minLength: 10)
                    trayArea(cellSize: cellSize)
                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if let piece = floatingPiece {
                    PieceView(piece: piece, cellSize: cellSize)
                        .position(floatingCenter(for: piece, cellSize: cellSize))
                        .allowsHitTesting(false)
                        .shadow(color: .black.opacity(0.35), radius: 10, y: 8)
                }

                if engine.isGameOver {
                    GameOverView(engine: engine)
                        .transition(.opacity)
                }
            }
            .onPreferenceChange(BoardFrameKey.self) { boardFrame = $0 }
            .coordinateSpace(name: "game")
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
                Button {
                    engine.newGame()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
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

    /// Center of the floating piece: lifted above the finger so it stays visible.
    private func floatingCenter(for piece: Piece, cellSize: CGFloat) -> CGPoint {
        let height = CGFloat(piece.rowCount) * cellSize
        return CGPoint(x: dragLocation.x,
                       y: dragLocation.y - height / 2 - liftOffset)
    }

    /// The board cell the floating piece's top-left block is over, if placement is legal.
    private func dropTarget(cellSize: CGFloat) -> (piece: Piece, origin: GridPoint)? {
        guard let piece = floatingPiece, boardFrame.width > 0 else { return nil }
        let width = CGFloat(piece.colCount) * cellSize
        let height = CGFloat(piece.rowCount) * cellSize
        let topLeft = CGPoint(x: dragLocation.x - width / 2,
                              y: dragLocation.y - height - liftOffset)
        let col = Int(round((topLeft.x - boardFrame.minX) / cellSize))
        let row = Int(round((topLeft.y - boardFrame.minY) / cellSize))
        let origin = GridPoint(row: row, col: col)
        guard engine.canPlace(piece, at: origin) else { return nil }
        return (piece, origin)
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
        DragGesture(minimumDistance: 0, coordinateSpace: .named("game"))
            .onChanged { value in
                guard engine.tray[i] != nil, !engine.isGameOver else { return }
                if dragIndex == nil { Haptics.pickUp() }
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

#Preview {
    GameView()
}
