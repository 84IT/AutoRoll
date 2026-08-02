# AutoRoll v3.1

AutoRoll is an ultra-lightweight, event-driven automatic loot evaluation and rolling suite engineered specifically for World of Warcraft private server frameworks (optimized for the *Conquest of Azeroth* / *Ascension* Vanilla/TBC client layout). 

The addon strips away manual looting clutter by executing programmatic loot decisions (`Need`, `Greed`, `Pass`) the exact microsecond a loot window prompt rolls into view, backed by a robust 5-second safety timeout engine, a 2-second login ignition shield, and a multi-dimensional real-time gear scoring matrix.

---

## 💾 Installation Instructions

To ensure the World of Warcraft game client securely indexes the addon and prevents silent file architecture loading errors, follow these exact directory placement steps:

### 1. Download & Extract
* Download the project zip archive to your desktop.
* Extract/unzip the contents using a tool like WinRAR, 7-Zip, or your native OS extractor.

### 2. Rename the Folder (Critical)
* The extraction tool will generate a directory folder named something generic like `AutoRoll-main`.
* **You must rename this folder exactly to:** `AutoRoll`
* *Note: If the folder name contains hyphens, version numbers, or trailing characters, the game client will completely fail to load your settings.*

### 3. Verify Folder Contents
Double-click your newly renamed `AutoRoll` folder. Ensure that the core project files are sitting directly inside it without being nested inside secondary sub-folders. The contents must look exactly like this:
```text
AutoRoll \
  ├── Profiles.lua
  ├── EngineCore.lua
  ├── InterfaceGUI.lua
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

### 1. Inverted Matrix Priority Stream
To completely safeguard usable gear upgrades from being swept away by general color automation, AutoRoll v3.1 shifts specific inventory configurations, live skill validations, and stat calculations *above* rarity filters. Items pass through a strict top-to-bottom hierarchy stream:

* **Priority 0 [The Interceptor]: Usable Unknown Recipes**
  - Instantly scans spellbook data to detect unlearned profession formulas.
  - Automatically executes a `NEED` command to secure the blueprint before general rules can apply.
* **Priority 1 [The Safety Shield]: Hard Block Usability Scanner**
  - Queries your character's live skills cache (Armor Proficiencies and Weapon Skills).
  - Instantly drops unwearable gear (like Plate on a Tinker) using `GREED/PASS` rules before running math.
* **Priority 2 [The Upgrade Tracker]: Smart Stats Module**
  - Runs real-time calculations using your custom class-profile decimal weight matrix.
  - Compares the item's score against your equipped gear baseline. If it's an upgrade, it rolls `NEED` immediately.
* **Priority 3 [The Specific Override]: Individual Type Dropdowns**
  - Evaluates your exact menu choices for individual sub-classes (e.g., Mail, Cloth, Daggers, Staves).
  - Weapons carry a safety hard-stop that pauses automation for manual review if no specific dropdown rule is set.
* **Priority 4 [The Cleanup Fallback]: Universal Quality Sweep**
  - Fires only as a final safety cushion for items that didn't match any specific slot rules higher up.
  - Applies broad background choices from your `Green`, `Blue`, and `Purple` dropdown settings.
### 2. Dynamic Server-Skills Synchronization Engine
Dumps legacy color tracking. The addon queries the game's native skills database via `GetSkillLineInfo` to cache your character's real-time `Armor Proficiencies` and `Weapon Skills` lists. If an item drops that isn't in your cache (like Plate on a Tinker), it flags it unusable across all systems instantly.

### 3. Asymmetric Multi-Slot & Pairing Logic
* **Rings & Trinkets:** Queries both equipped gear positions simultaneously, locks onto whichever item carries the absolute lowest stat value score as a baseline challenge, and evaluates the dropped item against your weakest link.
* **Dual-Wield vs. 2-Handers:** Automatically calculates your combined Main-Hand and Off-Hand/Shield scores, enabling accurate measurements of whether a massive 2-Handed weapon actually beats your current dagger-and-shield setup.

### 4. Prefix Anchor Shield
Prevents multiline set-text arrays from triggering accidental false color evaluations. The engine compiles an explicit string anchor check (`^`) that forces the color reader to validate only the first 10 characters at the absolute beginning of an item link, guaranteeing multi-drop safety during raid loot sweeps.

---

## 🛠️ Graphical User Interface (GUI)

AutoRoll includes a sleek, space-saving options dashboard accessible via `/autoroll`.

* **Compact Scrolling Panel:** The entire configuration matrix fits into a locked 490x480 pixel frame utilizing a native UI scroll frame track to completely eliminate screen clutter.
* **Mechanical Cogwheel Button (⚙️):** Click the custom mechanical icon next to the standard close box to instantly execute a complete backend saved variables audit, printing your live character proficiencies and skills inventory dump straight to chat.
* **Interactive Info Toggle Button (?):** Click the custom `?` button next to the standard close box to instantly toggle the internal functions explanation card beneath the main frame layout window.
* **Escape Key Window Sync Hook:** Fully integrated into the client's global `UISpecialFrames` database table. Hitting your `Esc` key instantly closes the options menu and sweeps away all active sub-panels simultaneously with zero script errors.

---

## 🔬 Diagnostic Command Tools

### `/archeck [Item Link]`
Type `/archeck ` followed by a **Shift-Click** on any item link to open up the interactive Copyable Diagnostic Inspector. The window opens with the item's raw text lines completely pre-highlighted in blue, allowing you to hit **`Ctrl + C`** right away to copy clean data rows straight to your computer's clipboard for rapid filtering review.

### `Ctrl + Hover` Chat Diagnostics
Hold down your keyboard's **`Ctrl`** key while hovering over any piece of gear inside your inventory bags or loot frames to stream a comprehensive mathematical stat breakdown directly into your chat log window, displaying exactly what regex patterns matched and which class profile weights were used to calculate the score. If the item is unwearable based on your skills cache, it skips the math entirely and throws a clean, prominent `[UNEQUIPPABLE]` warning banner instead.
