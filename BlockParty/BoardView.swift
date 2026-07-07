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
    let color: BlockColor
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(color.base)
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
    }

    @ViewBuilder
    private func cell(_ r: Int, _ c: Int) -> some View {
        let i = GameEngine.index(r, c)
        let color = engine.cells[i]
        let isClearing = engine.clearingCells.contains(i)
        let wouldClear = preview?.clearIndices.contains(i) ?? false
        let ghostColor: BlockColor? = (preview?.cellIndices.contains(i) ?? false) ? preview?.piece.color : nil

        ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .padding(1.5)

            if let color {
                BlockView(color: color, size: cellSize - 3)
                    .scaleEffect(isClearing ? 0.05 : 1)
                    .opacity(isClearing ? 0 : 1)
                    .animation(.easeIn(duration: 0.25), value: isClearing)
            } else if let ghostColor {
                RoundedRectangle(cornerRadius: cellSize * 0.22, style: .continuous)
                    .fill(ghostColor.base.opacity(0.4))
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
