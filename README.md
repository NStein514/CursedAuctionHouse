# Cursed Auction House

A Flutter game for iOS, Android, Windows, macOS, Linux and the web.
You are an artifact dealer in increasingly dangerous auctions. Every lot hides a true value, maybe a charm, and maybe a curse.
Five AI rivals bid against you. Each has a secret personality, a budget and preferences. **Learn them, read their tells, and manipulate the bidding wars.**

> Status: playable and feature-complete for a first release. Written without access to a Flutter compiler, so if the first build reports an error, please report it.

## Quick start

Requires Flutter 3.16+ (Dart 3).

```bash
# 1. One time: add platform folders (android, ios, windows, web...). Does not touch the game code.
powershell -ExecutionPolicy Bypass -File .\setup.ps1      # Windows
bash setup.sh                                              # macOS / Linux

# 2. Run
flutter run -d edge        # browser, no extra tooling (or -d chrome)
flutter run -d windows     # needs Visual Studio "Desktop development with C++"
flutter run                # a connected phone or emulator
```

Run these from the folder that contains `pubspec.yaml`. If you only see Flutter's counter demo, you are in the wrong folder or an old `main.dart` was restored. The only entry point is `lib/main.dart`.
Press `r` for hot reload and `R` for hot restart while running. `flutter test` runs the included tests.

## How to play

1. **Menu → Enter the Auction.** Pick a mode, a difficulty and exactly 5 rivals out of 10.
2. **Each lot:** you see a public estimate, an "aura" hint (about curses, sometimes wrong) and lore. Open the bidding, raise, or pass. Rivals respond one at a time.
3. **Read your rivals.** Each rival shows a *tell* when they bid. Every rival has one tell for bluffing and one for real interest, but tells are only mostly reliable. After each lot, bluffs are exposed and the **Dossier** records how often each tell meant a bluff. It also tracks which categories each rival bids on and whether their purse is running low.
4. **Manipulate.** Taunt proud rivals into overbidding (drains their purse, but 20% chance of a sanity-costing backfire). Let bluffers get stuck with overpriced lots. Burn rich rivals so they cannot afford the next lot.
5. **Win a lot:** you resell it at its true value. Profit is true value minus your bid. But curses hit your gold and sanity.
6. **Tag every rival** in the Dossier with your best guess. Each correct read pays **+100🪙** at the end of a season, or when you retire from Endless.
7. **Black Market** appears between lots (after 3, 6 and 8 in a season; every 4 lots in Endless).
8. **Sanity** matters: low sanity distorts estimates and makes tells lie more often, and a red vignette creeps in. At 0 you lose.

## Modes

| Mode | Goal |
|---|---|
| **Season** | 10 lots. Reach your difficulty's gold goal. Lot 10 is the **Finale**, the Crown of Nine Sorrows (huge value, severity-5 curse, rivals get +600🪙). Save a Ward Sigil. |
| **Endless** | No goal. Rivals get richer each lot and bolder every 5 lots. Fees and sanity drain climb. A boss lot arrives every 10 lots with growing value. You end by dying (sanity 0 or bankruptcy) or by **retiring** to bank your reads. Graded on lots survived. |

## Difficulty

| | Start | Goal | Fees/lot | Curse damage | Rivals | Tell accuracy | Sanity drain/lot |
|---|---|---|---|---|---|---|---|
| 🌱 Apprentice | 1200 | 2500 | 0 | ×0.6 | poorer | 90% | 0 |
| ⚖️ Dealer | 1000 | 3500 | 50 | ×1 | normal | 80% | 0 |
| 🔥 Master | 900 | 4000 | 90 | ×1.5 | richer | 70% | 1 |
| 💀 Nightmare | 800 | 4500 | 130 | ×2 | much richer | 60% | 3 |

Higher difficulties also raise curse frequency, mask more curses from appraisal and make auras more misleading. Master unlocks after winning a season on Dealer, Nightmare after winning on Master.

## Charms

| Charm | Type | Effect | Unlock |
|---|---|---|---|
| Seer's Eye | manual | Reveals one rival's true limit on this lot | start |
| Ward Sigil | auto | Blocks the next curse | start |
| Gilded Touch | auto | +25% on your next resale | start |
| Smoke Bomb | manual | Forces a rival out of this lot | Win a season |
| Lantern of Truth | manual | Reveals true value and curse, even masked | Finish 3 runs |
| Haggler's Seal | auto | 20% off your next winning bid | Win 10 lots (lifetime) |
| Mirror Shard | auto | Halves the next curse | Suffer 5 curses (lifetime) |

Charms drop from lots and are sold at the Black Market (along with a Cleansing Rite for +20 sanity and an Informant's Rumor that reveals one rival's true type).

## Progress, unlocks and sound

Progress is saved on the device (shared_preferences): lifetime stats, a top-10 **Hall of Fame**, and unlocks.

- Rivals 6-10 unlock through play (hints are shown in the setup screen and Hall of Fame).
- **Hall of Fame → Settings** has a sound toggle, **Unlock everything (for testing)** and a reset button.
- Sound effects are small generated WAV files in `assets/sfx/`. Regenerate or tweak them with `python tool/gen_sfx.py`. Sound fails silently if a platform cannot play audio.

## Project layout

```
lib/
  main.dart           the single entry point: app, theme, menu
  models.dart         artifacts, curses, charms, rivals (personas), difficulty table
  state.dart          the game engine: bidding rounds, rival AI, resolution, shop, endless rules
  storage.dart        saved Profile: stats, hall of fame, unlock rules
  sfx.dart            sound effects
  setup_screen.dart   mode / difficulty / rival selection
  auction_screen.dart the auction UI, results, Black Market, end screen
  dossier_screen.dart tells, category interest, your reads, field guide
  hall_screen.dart    Hall of Fame, unlocks, settings
assets/sfx/           generated sound effects
tool/gen_sfx.py       sound generator
test/widget_test.dart smoke tests
setup.ps1, setup.sh   one-time platform setup
```

## Tuning the game

- Difficulty numbers: the `diffs` list at the bottom of `lib/models.dart`.
- Rival personalities and tells: `bidderPool` in `lib/models.dart`; their valuation rules are in `_valuation` and `_bidderTurn` in `lib/state.dart`.
- Endless escalation: the top of `startRound` in `lib/state.dart`; fees and drain in `_finish`.
- Unlock rules: `lib/storage.dart`.

## Troubleshooting

- **"Unable to find suitable Visual Studio toolchain"**: install the VS "Desktop development with C++" workload (with MSVC v142, C++ CMake tools and a Windows 10 SDK), or run in Edge with `flutter run -d edge`.
- **Flutter's counter app appears**: run from the project folder, then run `setup.ps1` again; it restores `lib/` after generating platform folders.
- **No sound on a desktop target**: the game still works; check the sound toggle in Hall of Fame → Settings.

## Spoilers: the ten rivals

Miser (Silas Penny), Gambler (Duchess Vane), Collector (Orrin Kade), Bluffer (Madame Vex), Occultist (Brother Morrow),
Sniper (Ravenna Cross), Expert (Professor Ash), Spiteful (Lord Harrow), Speculator (Jinx Marlowe), Whale (Baron Gilt).
Each type's behavior is listed in the in-game field guide.

## Ideas for later

Sealed-bid lots, rival-vs-rival grudges, daily seeded challenges, cloud-synced scores, more rival types, and a tutorial lot.
