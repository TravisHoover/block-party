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

## Publishing to the App Store

### One-time setup

1. **Join the Apple Developer Program** ($99/year) at
   [developer.apple.com/programs](https://developer.apple.com/programs/)
   with your Apple ID. Approval usually takes a day or two.
2. **Pick your final bundle ID** (e.g. `com.yourname.blockparty`), set it in
   the Xcode project (target → Signing & Capabilities), and commit that
   change. Then register it at
   [developer.apple.com → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
   (type: App ID → App, capabilities: none needed).
3. **Create the app record** in
   [App Store Connect](https://appstoreconnect.apple.com) → My Apps → **+**:
   - **Name**: the App Store listing name. Must be unique across the entire
     store — plain "Block Party" is likely taken, so have a variant ready
     (e.g. "Block Party — Puzzle Fun"). The name under the icon on the
     device stays "Block Party" regardless.
   - **Bundle ID**: pick the one you registered.
   - **SKU**: your own internal ID for the app — it is never shown to
     customers and just needs to be unique within your account. Something
     like `blockparty-001` is perfect. (It can't be changed later, but it
     also never matters.)
4. **Fill in the listing**: description, keywords, category (Games →
   Puzzle), age rating questionnaire, price (Free).
   - **App Privacy**: answer the questionnaire truthfully with
     **"Data Not Collected"** — this app collects nothing.
   - **Privacy Policy URL**: point at this repo's `PRIVACY.md` (the file's
     GitHub URL works if the repo is public; otherwise host it on GitHub
     Pages).
   - **Screenshots**: run the app on an iPhone simulator and press ⌘S to
     save screenshots. You need one set for a 6.9" or 6.5" iPhone, and one
     for 13" iPad (required because the app supports iPad).

### CI secrets (one-time)

The `Release to App Store Connect` workflow needs six repository secrets
(GitHub → Settings → Secrets and variables → Actions):

| Secret | How to get it |
| --- | --- |
| `APPLE_TEAM_ID` | 10-character ID shown at developer.apple.com → Membership |
| `ASC_KEY_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys → Generate (role: **App Manager**) |
| `ASC_ISSUER_ID` | Shown on the same API keys page |
| `ASC_API_KEY_P8_BASE64` | Download the key's `.p8` file (one chance!), then `base64 -i AuthKey_XXXX.p8 \| pbcopy` |
| `DIST_CERT_P12_BASE64` | In Xcode → Settings → Accounts → Manage Certificates → **+** → Apple Distribution. Then in Keychain Access, find "Apple Distribution: Your Name", right-click → Export as `.p12` with a password. `base64 -i cert.p12 \| pbcopy` |
| `DIST_CERT_PASSWORD` | The password you chose when exporting the `.p12` |

### Releasing

1. Merge everything you want to ship into `main`.
2. Tag it: `git tag v1.0.0 && git push origin v1.0.0` (or run the workflow
   manually from the Actions tab).
3. The workflow builds, signs, and uploads. Ten minutes or so after it
   finishes, the build appears in App Store Connect → TestFlight.
4. First time only: in App Store Connect, attach the build to your 1.0
   version page and **Submit for Review**. Review typically takes 1–2 days.
5. Later updates: bump `MARKETING_VERSION` in the project when you want a
   new store version (e.g. 1.1), tag, and submit the new build.

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
