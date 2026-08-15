import SwiftUI

/// Where the currently dragged piece would land, for ghost rendering.
struct PlacementPreview {
    let piece: Piece
    let origin: GridPoint
    let cellIndices: Set<Int>
    /// Cells belonging to rows/columns that would clear on this placement.
    let clearIndices: Set<Int>
}

/// A single rounded, glossy block.
struct BlockView: View {
    @Environment(\.theme) private var theme
    let color: BlockColor
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(theme.color(for: color))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0)],
                                         startPoint: .topLeading, endPoint: .center))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .frame(width: size, height: size)
    }
}

/// A small ring of dots that bursts outward from a clearing block and fades.
private struct ClearSparkles: View {
    @Environment(\.theme) private var theme
    let color: BlockColor
    let size: CGFloat
    /// True once the block starts shrinking away -- drives the burst.
    let burst: Bool

    private static let angles: [Double] = [15, 75, 135, 195, 255, 315]

    var body: some View {
        ZStack {
            ForEach(Self.angles.indices, id: \.self) { i in
                let radians = Self.angles[i] * .pi / 180
                let distance = size * 0.8
                Circle()
                    .fill(theme.color(for: color))
                    .frame(width: size * 0.15, height: size * 0.15)
                    .offset(x: burst ? cos(radians) * distance : 0,
                            y: burst ? sin(radians) * distance : 0)
                    .opacity(burst ? 0 : 1)
                    .scaleEffect(burst ? 0.2 : 1)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.24), value: burst)
    }
}

/// Renders a whole piece at a given cell size (used in the tray and while dragging).
struct PieceView: View {
    let piece: Piece
    let cellSize: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(piece.blocks.enumerated()), id: \.offset) { _, block in
                BlockView(color: piece.color, size: cellSize - 3)
                    .frame(width: cellSize, height: cellSize)
                    .offset(x: CGFloat(block.col) * cellSize,
                            y: CGFloat(block.row) * cellSize)
            }
        }
        .frame(width: CGFloat(piece.colCount) * cellSize,
               height: CGFloat(piece.rowCount) * cellSize,
               alignment: .topLeading)
    }
}

struct BoardView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var engine: GameEngine
    let cellSize: CGFloat
    let preview: PlacementPreview?
    /// The grid's frame in global (screen) coordinates, written directly as
    /// layout happens so GameView can convert drag locations into board cells.
    @Binding var gridFrame: CGRect

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<GameEngine.size, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<GameEngine.size, id: \.self) { c in
                        cell(r, c)
                    }
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { gridFrame = proxy.frame(in: .global) }
                    .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                        gridFrame = newFrame
                    }
            }
        )
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.28))
        )
        .scaleEffect(engine.comboPulse ? 1.035 : 1)
        .animation(.spring(response: 0.18, dampingFraction: 0.35), value: engine.comboPulse)
    }

    @ViewBuilder
    private func cell(_ r: Int, _ c: Int) -> some View {
        let i = GameEngine.index(r, c)
        let color = engine.cells[i]
        let isPopping = engine.poppingCells.contains(i)
        let isClearing = engine.clearingCells.contains(i)
        let wouldClear = preview?.clearIndices.contains(i) ?? false
        let ghostColor: BlockColor? = (preview?.cellIndices.contains(i) ?? false) ? preview?.piece.color : nil

        ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .padding(1.5)

            if let color {
                ZStack {
                    BlockView(color: color, size: cellSize - 3)
                        .scaleEffect(isClearing ? 0.05 : (isPopping ? 1.22 : 1))
                        .brightness(isClearing ? 0.15 : (isPopping ? 0.55 : 0))
                        .opacity(isClearing ? 0 : 1)
                        .animation(.easeOut(duration: 0.09), value: isPopping)
                        .animation(.easeIn(duration: 0.21), value: isClearing)

                    if isPopping || isClearing {
                        ClearSparkles(color: color, size: cellSize, burst: isClearing)
                    }
                }
            } else if let ghostColor {
                RoundedRectangle(cornerRadius: cellSize * 0.22, style: .continuous)
                    .fill(theme.color(for: ghostColor).opacity(0.4))
                    .padding(1.5)
            }

            if wouldClear {
                RoundedRectangle(cornerRadius: cellSize * 0.22, style: .continuous)
                    .fill(Color.white.opacity(0.3))
                    .padding(1.5)
            }
        }
        .frame(width: cellSize, height: cellSize)
    }
}
