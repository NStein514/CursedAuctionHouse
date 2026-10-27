# CursedAuctionHouse
A Flutter/Dart app for iOS and Android called Cursed Auction House. Where the user is an artifact dealer participating in increasingly dangerous auctions. Every item has a hidden value, secret abilities, and potentially devastating curses. Unique twist: Competing AI bidders have personalities, budgets, and preferences. You learn their behavior to determine when they're bluffing, recognize valuable artifacts, and manipulate bidding wars.
# Cursed Auction House (Flutter, iOS + Android)

## Setup
    flutter create --platforms=ios,android --org com.example cursed_auction_house
    # copy this project's lib/ and pubspec.yaml over the generated ones
    cd cursed_auction_house && flutter pub get && flutter run

Requires Flutter 3.16+ (Dart 3). No third-party packages.

## How to play
- 10 lots, goal 3500🪙. Run out of gold or sanity and you lose.
- Every lot has a hidden true value, maybe a curse (more likely and nastier each round), maybe a charm.
- Rivals have hidden personas (miser, gambler, collector, bluffer, occultist). Learn them:
  * Tells: each rival has a personal "bluff tell" and "honest tell", ~80% reliable. After each lot, bluffs are exposed and the Dossier updates tell stats.
  * Category interest and wins reveal collectors; occultists chase cursed lots (a leak about curses).
  * Purse shows who is drained.
- Manipulate: Taunt makes proud rivals overbid (20% backfire: sanity loss). Drain rich rivals, let bluffers overpay.
- Appraise (60🪙) shows value and curse severity; 15% of curses are masked.
- Low sanity corrupts estimates and tells.

## Running on PC (for testing)
Run `flutter doctor` first and fix anything it flags for your target.

- Windows: install Visual Studio with the "Desktop development with C++" workload, then
      flutter config --enable-windows-desktop
      flutter create --platforms=windows,ios,android .
      flutter run -d windows
- Browser (no extra tools besides Chrome/Edge):
      flutter create --platforms=web .
      flutter run -d chrome
- macOS: `flutter config --enable-macos-desktop`, `flutter create --platforms=macos .`, `flutter run -d macos`
- Linux: `flutter config --enable-linux-desktop`, `flutter create --platforms=linux .`, `flutter run -d linux`

Run `flutter create` inside the project folder; it only adds the missing platform folders and keeps your lib/.
During `flutter run`, press `r` for hot reload and `R` for hot restart.

## Difficulty and rivals
Before each run you choose a difficulty (Apprentice, Dealer, Master, Nightmare) and 5 of 10 rivals.
Difficulty changes: starting gold, goal, per-lot house fees (passing is no longer free), curse odds and damage,
rival budgets and income, tell reliability, masked curses, appraisal cost, and sanity drain per lot.
New rivals: Ravenna Cross (waits, then strikes late), Professor Ash (knows true values),
Lord Harrow (fights back when you lead), Jinx Marlowe (follows the public estimate), Baron Gilt (whale who overpays).

## Version 3 additions
- Rival reads: tag each rival with a type in the Dossier (field guide included). +100🪙 per correct read at season end; the end screen reveals everyone.
- Black Market shop after lots 3, 6 and 8: charms, sanity restore, and an informant who reveals a rival's true type.
- Finale lot 10: the Crown of Nine Sorrows (huge value, severity-5 curse). Rivals get +600🪙. Save a Ward Sigil.
- End screen: grade (S to F), titles, stats, rival reveal.
- Atmosphere: red vignette as sanity falls, haptics on wins and curses (mobile), lot lore text.
