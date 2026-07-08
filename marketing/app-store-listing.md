# App Store Listing Kit — Block Party

Everything App Store Connect will ask for, ready to copy-paste.
Character limits are noted where Apple enforces them.

---

## App record (created once, at My Apps → +)

| Field | Value |
| --- | --- |
| Platform | iOS |
| Name (30 chars max) | `Block Party — Family Puzzle` (27) — if taken, try `Block Party! Kids Puzzle` or `Block Party: Ad-Free Puzzle` |
| Primary language | English (U.S.) |
| Bundle ID | the one you registered (e.g. `com.yourname.blockparty`) |
| SKU | `blockparty-001` |
| User access | Full Access |

## Version information

**Subtitle** (30 chars max):

> Ad-free block puzzle fun

**Promotional text** (170 chars max, can be changed without review):

> No ads, no in-app purchases, nothing to buy — just a colorful,
> satisfying block puzzle for the whole family.

**Description** (4000 chars max):

> Block Party is a colorful, relaxing block puzzle — with no ads,
> no in-app purchases, and no internet required. Ever.
>
> Drag pieces onto the 8×8 board and fill complete rows or columns to
> clear them. Clear several lines at once — or keep a streak going —
> for big combo bonuses. When no piece fits, the round is over. Can you
> beat your best score?
>
> SIMPLE TO PLAY
> • Drag, drop, and clear — that's it
> • A gentle preview shows exactly where each piece will land
> • Satisfying pops, colors, and haptics
>
> MADE FOR FAMILIES
> • No ads of any kind
> • No in-app purchases
> • No accounts, no tracking, no data collection
> • Works completely offline — perfect for car rides and flights
> • Optional shuffle helper for younger players (off by default)
>
> Block Party was built by a parent who wanted a block puzzle his
> daughter could play without inappropriate ads. That's the whole app:
> just the game.

**Keywords** (100 chars max, comma-separated):

> block,puzzle,blocks,brain,logic,kids,family,grid,relax,offline,combo,lines

**Support URL:** your GitHub repo URL (e.g. `https://github.com/TravisHoover/cube-crush`)

**Marketing URL** (optional): leave blank

**Copyright:** `© 2026 Travis Hoover`

## Screenshots (in `marketing/screenshots/`)

| File | Slot | Pixels |
| --- | --- | --- |
| `iphone-6.9-1-gameplay.png` | iPhone 6.9" Display | 1320 × 2868 |
| `iphone-6.9-2-combo.png` | iPhone 6.9" Display | 1320 × 2868 |
| `iphone-6.9-3-newbest.png` | iPhone 6.9" Display | 1320 × 2868 |
| `ipad-13-1-gameplay.png` | iPad 13" Display | 2064 × 2752 |
| `ipad-13-2-newbest.png` | iPad 13" Display | 2064 × 2752 |

Upload order = display order; put the combo shot second or first.
Smaller devices reuse these automatically. The **app icon** uploads with
the build itself — nothing to provide separately.

## App Information

| Field | Value |
| --- | --- |
| Primary category | Games → Puzzle |
| Secondary category | Games → Family |
| Content rights | Does not contain third-party content |
| Age rating questionnaire | Answer **None / No** to everything → rating **4+** |
| Made for Kids | **No** (not required just because kids play it; opting in adds extra review rules) |

## App Privacy

| Question | Answer |
| --- | --- |
| Privacy policy URL | URL of `PRIVACY.md` in this repo (public file URL or GitHub Pages) |
| Data collection | **Data Not Collected** (truthful: the app is fully offline) |

## Pricing and Availability

| Field | Value |
| --- | --- |
| Price | Free (USD 0) |
| Availability | All countries (or just your own — your call) |

## Version release & review

| Field | Value |
| --- | --- |
| Version | 1.0 (must match `MARKETING_VERSION` in the project) |
| Build | pick the build uploaded by the release workflow |
| Export compliance | Already answered by the build (`ITSAppUsesNonExemptEncryption = NO`) |
| Sign-in required for review | No |
| Review notes | "Fully offline puzzle game. No account, no ads, no purchases, no data collection. No special setup needed." |
| Contact info | Your name, email, and phone (only App Review sees this) |
| Release option | Automatically release after approval (or Manual if you want to press the button) |
