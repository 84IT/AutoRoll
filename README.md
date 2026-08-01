# AutoRoll v3.1

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

### 1. Realigned Matrix Execution Stream
To completely safeguard usable gear upgrades from being swept away by general color automation, AutoRoll v3.0+ shifts specific inventory configurations and stat calculations *above* rarity filters. Items pass through an advanced hierarchy stream:
- **Priority 0:** Usable Unknown Recipes (Auto-Need Interceptor)
- **Priority 1-2:** Specific Armor Class & Weapon Type Dropdowns
- **Priority 3:** Smart Stats Module Point Upgrade Check
- **Priority 4:** Hard Block Usability Scanner (Plate/Relic Exclusion)
- **Priority 5:** Universal Rarity Quality Color Sweep (Final Cleanup Fallback)

### 2. Multi-Column Tooltip Splitting Engine
Standard WoW addons parse text strings line-by-line using a single column template. This addon deploys a dual-column scanner (`TextLeft` and `TextRight`) paired with a dynamic string-gmatch row splitter. This allows AutoRoll to cleanly parse compressed private server formatting loops, separating squished attributes (e.g., `+10 Intellect\n+10 Spell Power`) and tracking floating right-hand alignment fields like weapon `Crossbow` types and attack `Speed` metrics flawlessly.

### 3. Asymmetric Multi-Slot & Pairing Logic
* **Rings & Trinkets:** Queries both equipped gear positions simultaneously, locks onto whichever item carries the absolute lowest stat value score as a baseline challenge, and evaluates the dropped item against your weakest link.
* **Dual-Wield vs. 2-Handers:** Automatically calculates your combined Main-Hand and Off-Hand/Shield scores, enabling accurate measurements of whether a massive 2-Handed weapon actually beats your current dagger-and-shield setup.

### 4. Prefix Anchor Shield
Prevents multiline set-text arrays from triggering accidental false color evaluations. The engine compiles an explicit string anchor check (`^`) that forces the color reader to validate only the first 10 characters at the absolute beginning of an item link, guaranteeing multi-drop safety during raid loot sweeps.

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
