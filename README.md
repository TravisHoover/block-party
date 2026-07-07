# Block Party 🟥🟧🟩🟦

An ad-free, kid-friendly iOS block puzzle game in the style of Block Blast.
Built with SwiftUI. **No ads, no in-app purchases, no tracking, no internet
access — ever.**

## How to play

- Drag pieces from the tray at the bottom onto the 8×8 board.
- When you place all three pieces, you get three new ones.
- Fill a complete **row or column** to clear it and score points.
- Clear multiple lines at once — or on back-to-back moves — for combo bonuses.
- The game ends when none of your pieces fit anywhere. Your best score is
  saved on the device.
- The gear button opens settings: restart the game, or turn on the optional
  **shuffle button** (off by default), which swaps the current pieces for new
  ones — handy for younger kids, but it makes the game much easier.

## Requirements

- A Mac with **Xcode 15 or newer** (free from the Mac App Store)
- An iPhone or iPad running **iOS 17 or newer**
- An Apple ID (a free one works — no paid developer account needed)

## Installing on your kid's device

1. Clone this repo and open `BlockParty.xcodeproj` in Xcode.
2. In Xcode, select the **BlockParty** project in the sidebar, then the
   **BlockParty** target → **Signing & Capabilities** tab.
3. Check **Automatically manage signing** and pick your **Team**. If no team
   is listed, choose *Add an Account…* and sign in with your Apple ID —
   a free "Personal Team" will appear.
4. Change the **Bundle Identifier** from `com.example.BlockParty` to something
   unique to you, e.g. `com.yourname.BlockParty`.
5. Plug in the iPhone, unlock it, and tap **Trust** if prompted.
   Select the phone in Xcode's device menu (top toolbar) and press **Run** (⌘R).
6. First launch will be blocked until you trust yourself as a developer on the
   phone: **Settings → General → VPN & Device Management → your Apple ID →
   Trust**. Then launch the app again.

### Good to know (free Apple ID)

- Apps signed with a free Personal Team **expire after 7 days**. The fix takes
  a minute: plug the phone back in and press Run in Xcode again.
- If you'd rather not re-sign weekly, a paid Apple Developer account
  ($99/year) signs apps for a full year and also unlocks **TestFlight**,
  which lets you install over the air on family devices for 90 days per build.

## Project layout

| File | What it does |
| --- | --- |
| `GameEngine.swift` | Game rules: board state, placement, line clearing, scoring, combos, game over |
| `PieceLibrary.swift` | All piece shapes, their colors, and weighted random generation |
| `GameView.swift` | Main screen: score header, drag-and-drop handling, piece tray |
| `BoardView.swift` | The 8×8 grid, block rendering, and placement ghost preview |
| `GameOverView.swift` | End-of-game overlay with score and Play Again |
| `Haptics.swift` | Little buzzes for picking up, placing, and clearing |

## Tweaking the game

- **Make it easier/harder:** adjust the shape weights in `PieceLibrary.swift` —
  higher weight = appears more often. Removing the big 3×3 and 5-block pieces
  makes it much friendlier for younger kids.
- **Scoring:** the formula lives in `GameEngine.place(trayIndex:at:)`.
- **Colors:** the palette is in `BlockColor` in `PieceLibrary.swift`.
