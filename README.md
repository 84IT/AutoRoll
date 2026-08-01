# AutoRoll v2.0

AutoRoll is an ultra-lightweight, event-driven automatic loot evaluation and rolling suite engineered specifically for World of Warcraft private server frameworks (optimized for the *Conquest of Azeroth* / *Ascension* launcher architecture). 

The addon strips away manual looting clutter by executing programmatic loot decisions (`Need`, `Greed`, `Pass`) the exact microsecond a loot window prompt rolls into view, backed by a robust 5-second safety timeout engine and a multi-dimensional real-time gear scoring matrix.

---

## 🚀 Key Mechanical Engineering Features

### 1. Multi-Column Tooltip Splitting Engine
Standard WoW addons parse text strings line-by-line using a single column template. This addon deploys a dual-column scanner (`TextLeft` and `TextRight`) paired with a dynamic string-gmatch row splitter. This allows AutoRoll to cleanly parse compressed private server formatting loops, separating squished attributes (e.g., `+10 Intellect\n+10 Spell Power`) and tracking floating right-hand alignment fields like weapon `Crossbow` types and attack `Speed` metrics flawlessly.

### 2. Smart Weapon-Pairing & Multi-Slot Comparison Math
* **Rings & Trinkets:** AutoRoll features an asymmetric multi-slot rule engine. When a ring or trinket drops, the addon queries both equipped gear positions simultaneously, locks onto whichever item carries the absolute lowest stat value score as a baseline challenge, and evaluates the dropped item against your weakest link.
* **Dual-Wield vs. 2-Handers:** When evaluating weapons, the engine automatically calculates your combined Main-Hand and Off-Hand/Shield scores, allowing you to accurately measure whether a massive 2-Handed staff or polearm actually beats your currently equipped dagger-and-shield combo profiles.

### 3. Server-Adaptive Normalization Shield
Designed to combat backend database quirks common on scaled private servers, AutoRoll features an intelligent text-string and name-keyword remapping layout layer. If the server passes generic tags like `One-Hand` or mislabeled plural values (`Crossbow` vs `Crossbows`), the script isolates text anchors directly out of the item title and lines to accurately sort weapons into your precise dashboard sorting channels.

---

## 🛠️ Graphical User Interface (GUI)

AutoRoll includes a sleek, space-saving options dashboard accessible via `/autoroll`.

* **Compact Scrolling Panel:** The entire configuration matrix fits into a locked 490x480 pixel frame utilizing a native UI scroll frame track to completely eliminate screen clutter.
* **Interactive Info Toggle Button (?):** Click the custom `?` button next to the standard close box to instantly toggle the internal functions explanation card beneath the main frame layout window.
* **Escape Key Window Sync Hook:** Fully integrated into the client's global `UISpecialFrames` database table. Hitting your `Esc` key instantly closes the options menu and sweeps away all active sub-panels simultaneously with zero script errors.

---

## 🔬 Diagnostic Command Tools

### `/archeck [Item Link]`
Type `/archeck ` followed by a **Shift-Click** on any item link to open up the interactive Copyable Diagnostic Inspector. The window opens with the item's raw text lines completely pre-highlighted in blue, allowing you to hit **`Ctrl + C`** right away to copy clean data rows straight to your computer's clipboard for rapid filtering review.

### `Ctrl + Hover` Chat Diagnostics
Hold down your keyboard's **`Ctrl`** key while hovering over any piece of gear inside your inventory bags or loot frames to stream a comprehensive mathematical stat breakdown directly into your chat log window, displaying exactly what regex patterns matched and which class profile weights were used to calculate the score.

---

## ⚡ Performance Footprint

* **Memory Draw:** ~30 KB to 50 KB of RAM (virtually undetectable compared to heavy suites like *ElvUI* or *Details!*).
* **CPU Consumption:** 0% during combat and running around. The addon operates on an entirely event-driven framework (`START_LOOT_ROLL` and `OnTooltipSetItem`), sitting completely asleep 99.9% of the time to guarantee zero frame stutters or micro-lag during intense gameplay phases.
