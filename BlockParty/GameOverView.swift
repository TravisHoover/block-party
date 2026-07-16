import SwiftUI

/// One falling, tumbling confetti rectangle. Each piece loops its fall
/// forever with its own speed, delay, drift, and spin.
private struct ConfettiPieceView: View {
    @Environment(\.theme) private var theme
    let spec: ConfettiSpec
    let screenHeight: CGFloat
    @State private var falling = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(theme.color(for: spec.color))
            .frame(width: spec.size, height: spec.size * 1.6)
            .rotationEffect(.degrees(falling ? spec.spin : 0))
            .rotation3DEffect(.degrees(falling ? spec.spin * 1.7 : 0), axis: (x: 1, y: 1, z: 0))
            .offset(x: falling ? spec.drift : 0,
                    y: falling ? screenHeight + 60 : -60)
            .onAppear {
                withAnimation(.linear(duration: spec.duration)
                    .repeatForever(autoreverses: false)
                    .delay(spec.delay)) {
                    falling = true
                }
            }
    }
}

private struct ConfettiSpec: Identifiable {
    let id = UUID()
    let x: CGFloat        // horizontal position, 0...1 across the screen
    let drift: CGFloat    // sideways sway over the fall, in points
    let size: CGFloat
    let color: BlockColor
    let duration: Double
    let delay: Double
    let spin: Double

    static func shower(count: Int) -> [ConfettiSpec] {
        (0..<count).map { _ in
            ConfettiSpec(x: .random(in: 0.02...0.98),
                         drift: .random(in: -60...60),
                         size: .random(in: 7...13),
                         color: BlockColor.allCases.randomElement() ?? .yellow,
                         duration: .random(in: 2.2...4.0),
                         delay: .random(in: 0...1.6),
                         spin: .random(in: 360...1080) * (Bool.random() ? 1 : -1))
        }
    }
}

/// A full-screen confetti shower for the New Best celebration.
private struct ConfettiView: View {
    @State private var specs = ConfettiSpec.shower(count: 60)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(specs) { spec in
                    ConfettiPieceView(spec: spec, screenHeight: proxy.size.height)
                        .position(x: proxy.size.width * spec.x, y: 0)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct GameOverView: View {
    @ObservedObject var engine: GameEngine

    private var isNewBest: Bool {
        engine.score > engine.previousBest && engine.score > 0
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            if isNewBest {
                ConfettiView()
            }

            VStack(spacing: 18) {
                Text(isNewBest ? "New Best! 🎉" : "Nice Try!")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                VStack(spacing: 6) {
                    Text("Score")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(engine.score)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Label("Best: \(engine.highScore)", systemImage: "crown.fill")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                }

                Button {
                    engine.newGame()
                } label: {
                    Text("Play Again")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(Color(red: 0.98, green: 0.60, blue: 0.23))
                        )
                }
                .padding(.top, 6)
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 0.22, green: 0.18, blue: 0.46))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            )
            .padding(28)
        }
    }
}
