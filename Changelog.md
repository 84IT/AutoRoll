# Changelog - AutoRoll 2.5

All notable changes, structural logic corrections, and interface optimization updates to the AutoRoll addon project are documented in this file.

---

## - Stable Release Build

### Added
- **Multi-Line Row Splitter Engine:** Added a custom `string.gmatch` line splitting loop to parse compressed item attributes (`\n`) common on scaled private server layouts, ensuring stats like Haste and Spell Power are scored simultaneously.
- **Dual-Column Scanner Integration:** Upgraded tooltip scanning to evaluate `TextLeft` and `TextRight` labels simultaneously to capture floating structural values like weapon type (`Crossbow`, `Wand`) and attack `Speed`.
- **Interactive Info Toggle (?):** Added a help button next to the window close frame that toggles the internal operational rules box as a clean attached bubble frame.
- **Escape Key Group Close Hook:** Integrated main panel assets directly into the global `UISpecialFrames` database table paired with an `OnHide` script hook to collapse all open sub-panels simultaneously when pressing `Esc`.
- **Selectable Copy Inspector (`/archeck`):** Developed a read-only multi-line `EditBox` diagnostic logging window that auto-focuses and highlights raw item strings, enabling instant clipboard copying (`Ctrl + C`).
- **Missing Weapon Support Arrays:** Expanded default character database templates to natively support specialized categories, including `Fist Weapons`, `Polearms`, `Wands`, and `Thrown`.

### Changed
- **Scroll Frame GUI Realignment:** Repositioned all 15 weapon fields, 5 armor slots, and rarity columns inside an interactive vertical scroll frame track, decreasing total window height from 695 to a compact 480 pixels.
- **Dual-Column Visual Margin Tweak:** Pulled the right-hand dropdown column layout inward from 240 to 210 pixels to achieve a tight, visually balanced alignment across the scrolling menu pane.
- **Unusable Requirement Filtering Safeties:** Modified the bright red color tracker string filter within `IsItemUnusable` to look directly for hidden hex formatting code strings (`|cffff0000`), preventing dynamic level scaling lines (e.g., `Requires Level 61`) from trapping the automation loops.
- **Adaptive Precision Weapon Splits:** Re-separated the broad missile weapon category into independent options for `Guns` (kept on `Manual` to preserve character weapon inspections) and `Bows & Crossbows` (targeted for rapid automation sweeps).

### Fixed
- **Arithmetic Nil Pointer Crash:** Fixed a silent script crash inside `CalculateItemScore` by introducing an explicit type-validation wrapper (`if tonumber(match) then`) to prevent plain text words from breaking math multiplication loops.
- **Server Cache String Synchronization:** Resolved a critical execution delay bug by embedding a resilient `OnUpdate` retry buffer loop inside `START_LOOT_ROLL` events to wait for server-scaled database items to cache in RAM before running calculations.
- **Name-Clipping False Positives:** Corrected a string indexing mismatch within the fallback armor scanning sub-loops by forcing text matching routines to start exclusively at Line 2, successfully bypassing word collisions in item titles (e.g., *Skul's Fingerbone Claws* clipping into Ring slots).
- **Standalone Weapon Suffix Overrides:** Implemented an intelligent server-adaptive keyword normalizer to interpret singular weapon formatting properties (`Crossbow` vs `Crossbows`) and reassign generic database tags (`One-Hand`, `Ranged`) to their correct dashboard rows.
