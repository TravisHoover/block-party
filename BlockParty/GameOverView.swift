import SwiftUI

struct GameOverView: View {
    @ObservedObject var engine: GameEngine

    private var isNewBest: Bool {
        engine.score > engine.previousBest && engine.score > 0
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

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
