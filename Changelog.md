# Changelog - AutoRoll v3.1

All notable changes, structural logic corrections, and interface optimization updates to the AutoRoll addon project are documented in this file.

---

## [3.1] - Delayed Ignition & Priority Inversion Release

### Added
- **2-Second Delayed Ignition Engine:** Integrated a timed initialization wrapper using background `OnUpdate` script ticks inside the `PLAYER_LOGIN` event. The addon now pauses for exactly 2 seconds upon world login, allowing memory-heavy tools (like GatherMate2) to fully cache spatial notes before AutoRoll runs its inventory scans.
- **Dynamic Server-Skills Cache Engine:** Replaced fragile hardcoded class filters with a native skills tab scanner using `GetSkillLineInfo`. The addon reads weapon skills and armor masteries directly from your logged-in character's live skill sheets, adapting filters instantly across multi-character rosters.
- **Vertical Visual Build Stamp Alignment:** Repositioned the `v3.1 Stable Build` configuration text layer directly under the main title frame widget to guarantee crisp layouts regardless of character name string length.
- **Absolute Manual Exit Shield:** Upgraded Priority Five with an ironclad return barrier. If a specific item rarity is set to `Manual (0)`, the script immediately stops execution and freezes the loot window open, permanently preventing uncategorized items from falling through empty bulk variables into accidental auto-greeds.

### Changed
- **Inverted Matrix Priority Stream:** Completely reordered the master execution core layout inside `ProcessLootRoll`. Specific tool upgrades, weapon archetypes, and armor filters are calculated *above* universal colors. This safeguards high-tier upgrades from being rolled away by generic background quality sweeps.
---

## [3.0] - Architecture Matrix Overhaul

### Changed
- **Modular Multi-File Refactor:** Split the massive single file into clean, isolated modules (`EngineCore.lua` and `InterfaceGUI.lua`) to permanently protect the codebase from chat truncation boundaries.
- **Rarity Prefix Anchor Filter:** Redesigned the color regex scanner using explicit prefix string markers (`^`). The loop now examines strictly the absolute start of an item link, making the addon 100% immune to false color matches triggered by uncollected set text lines (e.g., *Vestments of the Devout* text lines).

---

## [2.7] - Core Usability Patch

### Added
- **Explicit Class Restriction Shield:** Hardcoded specific weapon and relic subclass exclusions (`Fist Weapons`, `Librams`, `Idols`, `Totems`) right into the core calculation engines to protect characters from invalid gear evaluations.
- **`Ctrl + Hover` Usability Guard:** Connected the `IsItemUnusable` loop straight to the global tooltip inspector, forcing the tool to print a prominent `[UNEQUIPPABLE]` warning and stop upgrade scoring on unwearable gear.

### Fixed
- **Line-Isolated Tooltip Leak:** Rewrote the color scanning loops to analyze lines independently, preventing general text filters (like level requirements) from blinding the scanner to red `Can't Equip` text tags lower down.
- **Cross-File Variable Scope Leaks:** Cleared infinite call-loops by standardizing global variable environment registries (`_G`) and stripping out circular local stubs across the multi-file split boundaries.
- **GetProfessions Nil API Crash:** Patched a severe client crash on Vanilla/TBC private server engine architectures by swapping out the modern `GetProfessions()` global API call for a completely backward-compatible spellbook loop (`GetSpellName`), restoring flawless recipe parsing without errors.
