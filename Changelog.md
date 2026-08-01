# Changelog - AutoRoll 2.7

All notable changes, structural logic corrections, and interface optimization updates to the AutoRoll addon project are documented in this file.

---

## [2.7] - Core Usability Patch

### Added
- **Explicit Class Restriction Shield:** Hardcoded specific weapon and relic subclass exclusions (`Fist Weapons`, `Librams`, `Idols`, `Totems`) right into the core calculation engines to protect characters from invalid gear evaluations.
- **`Ctrl + Hover` Usability Guard:** Connected the `IsItemUnusable` loop straight to the global tooltip inspector, forcing the tool to print a prominent `[UNEQUIPPABLE]` warning and stop upgrade scoring on unwearable gear.

### Fixed
- **GetProfessions Nil API Crash:** Patched a severe client crash on Vanilla/TBC private server engine architectures by swapping out the modern `GetProfessions()` global API call for a completely backward-compatible spellbook loop (`GetSpellName`), restoring flawless recipe parsing without errors.

---

## [2.5] - Profession & Interface Revision

### Added
- **Priority Zero Recipe Sniper:** Developed an advanced profession interceptor loop that analyzes tooltips to automatically execute **Need** rolls on completely unlearned, usable recipes while letting known duplicates pass safely to gold-farming settings.
- **Mechanical Cogwheel Dashboard Tool:** Integrated a high-definition engineering gear button next to the help layout block, executing a real-time configuration audit straight to your chat log window to catch duplicate options or double-caching visual bugs.
- **Addon Layout Version Stamp:** Implemented a localized version layout stamp (`v2.5+`) right below the character configuration name to establish title tracking density.

### Changed
- **Strict Quality Filter Anchors:** Optimized the Priority One rarity logic checks to enforce an ironclad barrier whenever a quality tier is set to `Manual (0)`, preventing bulk overrides from accidentally auto-greeding premium gear options.
- **Adaptive Regex Pattern Matching:** Re-engineered the core stat capture parameters to search globally anywhere across line rows, allowing the script to cleanly catch Haste properties across separate client-side layout syntaxes (e.g., matching both `+X Haste Rating` and `Improves haste rating by X`).
- **Ranged Option Granularity:** Re-separated the wide missile weapon track back into explicit individual columns for `Guns`, `Bows`, `Crossbows`, and `Thrown` items to match precise character proficiency rules.
