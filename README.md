# AutoRoll v2.7

AutoRoll is an ultra-lightweight, event-driven automatic loot evaluation and rolling suite engineered specifically for World of Warcraft private server frameworks (optimized for the *Conquest of Azeroth* / *Ascension* Vanilla/TBC client layout). 

The addon strips away manual looting clutter by executing programmatic loot decisions (`Need`, `Greed`, `Pass`) the exact microsecond a loot window prompt rolls into view, backed by a robust 5-second safety timeout engine and a multi-dimensional real-time gear scoring matrix.

---

## 💾 Installation Instructions

To ensure the World of Warcraft game client securely indexes the addon and prevents silent file architecture loading errors, follow these exact directory placement steps:

### 1. Download & Extract
* Download the project zip archive to your desktop.
* Extract/unzip the contents using a tool like WinRAR, 7-Zip, or your native OS extractor.

### 2. Rename the Folder (Critical)
* The extraction tool will generate a directory folder named something generic like `AutoRoll-main` or `AutoRoll-2.5`.
* **You must rename this folder exactly to:** `AutoRoll`
* *Note: If the folder name contains hyphens, version numbers, or trailing characters, the game client will completely fail to load your settings.*

### 3. Verify Folder Contents
Double-click your newly renamed `AutoRoll` folder. Ensure that the core project files are sitting directly inside it without being nested inside secondary sub-folders. The contents must look exactly like this:
```text
AutoRoll \
  ├── Profiles.lua
  ├── AutoRoll.lua
  ├── AutoRoll.toc
  └── README.md
```

### 4. Move to WoW Directory
Cut or copy your completed `AutoRoll` folder and paste it straight into your active game client installation directory path:
`World of Warcraft \ Interface \ AddOns \`

### 5. Load the Addon
* Launch your World of Warcraft client and log into your character select screen.
* Click the **AddOns** button in the bottom-left corner.
* Ensure **AutoRoll** is checked `[✓]` and enabled in your active listings table.
* Enter the world, type `/autoroll` into your chat box, and hit Enter to pull up your dashboard configuration layout panel!

---

## 🚀 Key Mechanical Engineering Features

### 1. Multi-Column Tooltip Splitting Engine
Standard WoW addons parse text strings line-by-line using a single column template. This addon deploys a dual-column scanner (`TextLeft` and `TextRight`) paired with a dynamic string-gmatch row splitter. This allows AutoRoll to cleanly parse compressed private server formatting loops, separating squished attributes (e.g., `+10 Intellect\n+10 Spell Power`) and tracking floating right-hand alignment fields like weapon `Crossbow` types and attack `Speed` metrics flawlessly.

### 2. Smart Weapon-Pairing & Multi-Slot Comparison Math
* **Rings & Trinkets:** AutoRoll features an asymmetric multi-slot rule engine. When a ring or trinket drops, the addon queries both equipped gear positions simultaneously, locks onto whichever item carries the absolute lowest stat value score as a baseline challenge, and evaluates the dropped item against your weakest link.
* **Dual-Wield vs. 2-Handers:** When evaluating weapons, the engine automatically calculates your combined Main-Hand and Off-Hand/Shield scores, allowing you to accurately measure whether a massive 2-Handed staff or polearm actually beats your currently equipped dagger-and-shield combo profiles.

### 3. Hardcoded Class Restriction Shield
To completely eliminate false-positive upgrade claims on unwearable gear classes, AutoRoll features an ironclad restriction interceptor. The script natively maps your class profiles to immediately block armor types and weapon subclasses your character sheet cannot physically wear (e.g., locking out `Fist Weapons`, `Librams`, `Idols`, and `Totems` for Tinkers).

### 4. Priority Zero Automated Recipe Sniper
AutoRoll includes an elite profession scanning loop. By natively cross-referencing tooltip requirement data strings straight against your active tradeskill spellbook layout arrays, it can instantly spot the difference between junk recipes and missing formulas. If a completely unlearned, usable recipe drops, the addon intercepts your rarity filters and triggers an immediate automated **Need** command completely hands-free.

---

## 🛠️ Graphical User Interface (GUI)

AutoRoll includes a sleek, space-saving options dashboard accessible via `/autoroll`.

* **Compact Scrolling Panel:** The entire configuration matrix fits into a locked 490x480 pixel frame utilizing a native UI scroll frame track to completely eliminate screen clutter.
* **Mechanical Cogwheel Button (W):** Click the custom mechanical gear icon next to the standard close box to instantly execute a complete backend saved variables audit, printing a crisp, color-coded breakdown of your active settings straight to your chat stream.
* **Interactive Info Toggle Button (?):** Click the custom `?` button next to the standard close box to instantly toggle the internal functions explanation card beneath the main frame layout window.
* **Escape Key Window Sync Hook:** Fully integrated into the client's global `UISpecialFrames` database table. Hitting your `Esc` key instantly closes the options menu and sweeps away all active sub-panels simultaneously with zero script errors.

---

## 🔬 Diagnostic Command Tools

### `/archeck [Item Link]`
Type `/archeck ` followed by a **Shift-Click** on any item link to open up the interactive Copyable Diagnostic Inspector. The window opens with the item's raw text lines completely pre-highlighted in blue, allowing you to hit **`Ctrl + C`** right away to copy clean data rows straight to your computer's clipboard for rapid filtering review.

### `Ctrl + Hover` Chat Diagnostics
Hold down your keyboard's **`Ctrl`** key while hovering over any piece of gear inside your inventory bags or loot frames to stream a comprehensive mathematical stat breakdown directly into your chat log window, displaying exactly what regex patterns matched and which class profile weights were used to calculate the score. If the item is unwearable, it skips the math entirely and throws a clean, prominent `[UNEQUIPPABLE]` warning banner instead.
