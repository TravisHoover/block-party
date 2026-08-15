import AVFoundation
import UIKit

/// Plays the game's short synthesized sound effects. Sounds are stored as
/// data sets in the asset catalog and preloaded once. The whole thing is
/// gated by the "soundEnabled" setting (default on) and uses the .ambient
/// audio session, so it respects the silent switch and never interrupts
/// music or videos playing in the background.
final class Sounds {
    private static let shared = Sounds()
    private static let soundEnabledKey = "soundEnabled"

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        for name in ["pickup", "place", "clear", "combo", "gameover", "newbest"] {
            guard let asset = NSDataAsset(name: name),
                  let player = try? AVAudioPlayer(data: asset.data,
                                                  fileTypeHint: AVFileType.wav.rawValue)
            else { continue }
            player.prepareToPlay()
            players[name] = player
        }
    }

    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: soundEnabledKey) as? Bool ?? true
    }

    private static func play(_ name: String) {
        guard isEnabled, let player = shared.players[name] else { return }
        player.currentTime = 0
        player.play()
    }

    static func pickUp() { play("pickup") }
    static func place() { play("place") }
    static func clear() { play("clear") }
    static func combo() { play("combo") }
    static func gameOver() { play("gameover") }
    static func newBest() { play("newbest") }
}
