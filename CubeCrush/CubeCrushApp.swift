import SwiftUI

@main
struct CubeCrushApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .preferredColorScheme(.dark)
                .statusBarHidden()
        }
    }
}
