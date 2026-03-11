# THUD Raid Tools
Thud Raid Tools for Turtle WoW. Tracks all standard and custom Turtle WoW consumables. Features an easy-to-use GUI for raid leaders to verify buffs instantly. Coded by Senzei and Erros. Inspired by Method Raid Tools and OG-Raid Helper.
# THUD Raid Tools

A World of Warcraft 1.12 (Vanilla / Turtle WoW) addon designed for raid leaders and Warlocks to streamline recruitment, consumable tracking, ready checks, auto-inviting, and summoning — all from a single compact UI bar.

---

## Table of Contents

- [Installation](#installation)
- [Main UI](#main-ui)
- [Modules](#modules)
  - [Guild Recruit](#guild-recruit)
  - [Ready Check (Rdy)](#ready-check-rdy)
  - [Consume Inspector](#consume-inspector)
  - [Auto Invite](#auto-invite)
  - [Chronicle](#chronicle)
  - [Auto Summon](#auto-summon)
- [Slash Commands](#slash-commands)
- [Requirements](#requirements)

---

## Installation

1. Download or clone this repository
2. Place the `THUD_Raid_Tools` folder into your WoW addons directory:
   ```
   World of Warcraft/Interface/AddOns/THUD_Raid_Tools/
   ```
3. Log in and enable **THUD Raid Tools** in your addon list

---

## Main UI

A small draggable bar appears on screen with buttons for all modules. It can be repositioned anywhere by left-click dragging.

```
┌────────────────────────────────────┐
│           THUD Raid Tools          │
├───────────┬──────┬─────────────────┤
│ Guild Rec │  Rdy │    Consume      │
├───────────┴──────┴─────────────────┤
│  Auto Inv  │  Chronicle │  Auto Sum │
└────────────────────────────────────┘
```

Progress bar panels for active modules (Recruitment, Auto Summon) anchor **above** the main bar with a countdown timer showing time until the next auto-post.

---

## Modules

### Guild Recruit

Automates posting recruitment advertisements to chat channels on a configurable timer.

**Features:**
- 5 message slots — write different ads and switch between them
- Optional second message per slot (posts immediately after the first)
- Message rotation — check multiple slots to cycle through them automatically
- Channel selection: General, Trade, World, or Raid
- Configurable interval in minutes
- **`[TTP]` tag** — automatically replaces with minutes remaining until a set Target Time (e.g. `[TTP] mins until pull!`)
- Progress bar panel above the main bar showing countdown to next post
- Settings persist between sessions via SavedVariables

**Slash Commands:**
```
/thudgr
```

---

### Ready Check (Rdy)

A single button that instantly fires a standard WoW Ready Check on your raid.

---

### Consume Inspector

A full raid buff and consumable inspection window. Scans all raid members and displays their active buffs in a grid.

**Features:**
- Tracks 10 class buffs per player: Fortitude, Mark, Intellect, Spirit, Shadow Protection, Might, Kings, Wisdom, Salvation, Champion
- Tracks a comprehensive list of consumables by priority:
  - **Priority 1 — Flasks:** Flask of Supreme Power, Flask of Distilled Wisdom, Flask of the Titans
  - **Priority 2 — Protection Potions:** GFPP, GSPP, GNPP, GAPP, GFRPP
  - **Priority 3 — Elixirs & Alcohol:** Mongoose, Mageblood, Giants, Shadow Power, Firepower, and many more
  - **Priority 4 — World Buffs & Food:** Juju Might, Juju Power, Zanza, Rage of Ages, Well Fed, Scorpok, etc.
- **Check Flasks** button — reports to officer chat who is missing a Priority 1 flask
- **Announce Buffs** button — announces missing class buffs to raid chat by category
- **Log Consumes** button — exports a full consume log to a `.txt` file via SuperWoW's `ExportFile` (saved to `WoW/Exports/`)
- Supports Ready Check integration — displays ready/not ready icons live during a ready check

**Slash Commands:**
```
/TRT
/THUDinspect   — open the consume inspector window
/trta          — announce missing buffs to raid
/trtlog        — export consume log to file
```

---

### Auto Invite

Automatically invites players who whisper a configured keyword.

**Features:**
- Set one or more keywords separated by commas
- Whisper matching is case-insensitive and exact
- Simple Start / Stop toggle
- Settings persist between sessions

**Slash Commands:**
```
/trtai
```

---


### Chronicle

A quick-access button to open the **ChronicleLog** addon options panel directly from the THUD bar. Requires the ChronicleLog addon to be loaded.

- Single click opens the ChronicleLog options window
- Clicking again while the window is open closes it (toggle)

---

### Auto Summon

*(Warlock-focused)* A full auto-summon system that scans public chat for players looking for summons, auto-invites them, and gives you a one-click popup to cast Ritual of Summoning.

#### Public Chat Scanner

Monitors General, Trade, World, and Whisper channels. All three of the following must be present in a single message to trigger:

1. **Location keyword** — one of your enabled scan locations (e.g. "hyjal", "mount hyjal", "hj")
2. **Intent keyword** — `wtb`, `want to buy`, `lf`, `lf1`, `lf2`, `lf3`, `lfs`, or `looking for`
3. **Summon keyword** — `summon`, `summons`, `summ`, or `sum`

Example trigger: *"LF summon Hyjal"* ✅ | *"LFM Hyjal"* ❌ | *"summon Hyjal"* ❌

When all three match, the addon will:
- Auto-invite the player
- Whisper them confirming the free summon
- Show a summon popup with their name and destination
- Play the ReadyCheck sound

**Scannable Locations:**
| Key | Keywords |
|-----|----------|
| Hyjal | hyjal, mount hyjal, hj |
| EPL | epl, eastern plaguelands, eastern plague |
| Azshara | azshara, azsh |
| UBRS | ubrs, upper blackrock, upper br |
| Winterspring | winterspring, wspring |
| Silithus | silithus, sili |

#### 123 Party/Raid Scanner *(Warlock only)*

Always active regardless of whether auto-summon scanning is running. When any player in your **current party or raid** types `123` in say, yell, party, or raid chat:

- Whispers them `"Summons inc!"`
- Opens the summon popup immediately
- Plays the ReadyCheck sound

Useful for summoning raid members and friends to your current location without any location keywords needed.

#### Summon Popup

A small draggable popup that appears when a summon is triggered. Shows the player's name and destination.

- **Summon** — targets the player by name, casts Ritual of Summoning, sends a party message, and whispers the player confirming the summon
- **Dismiss** — closes the popup without acting
- Popups **queue** if multiple players trigger simultaneously — they appear one at a time so none are missed

#### Auto-Post Timer

Automatically posts your configured message to a channel on a set interval (in minutes) while running. A progress bar panel above the main bar shows the countdown to the next post.

**Channels:** General, Trade, World, Raid

#### Config Window

Accessible via the **Auto Sum** button or slash command. Configure:
- Custom auto-post message (up to 255 characters)
- Channel selection
- Post interval in minutes
- Which locations to scan for

**Slash Commands:**
```
/thudas
/autosummon
```

---

## Slash Commands Summary

| Command | Module | Description |
|---------|--------|-------------|
| `/thudgr` | Guild Recruit | Open recruitment config |
| `/TRT` or `/THUDinspect` | Consume Inspector | Open consume/buff inspector |
| `/trta` | Consume Inspector | Announce missing buffs to raid |
| `/trtlog` | Consume Inspector | Export consume log to file |
| `/trtai` | Auto Invite | Open auto-invite config |
| `/thudas` or `/autosummon` | Auto Summon | Open auto-summon config |

---

## Requirements

- World of Warcraft 1.12.1 (Vanilla) or compatible private server (e.g. Turtle WoW)
- **SuperWoW** — required only for the consume log export (`ExportFile` function). All other features work without it.
- Auto Summon 123 scanner and summon casting require the player to be a **Warlock**

---

## Notes

- Settings are saved between sessions via the `THUD_Settings` and `THUD_AutoInvite` SavedVariables
- The addon is built for the 1.12 Lua environment — it uses `string.gfind`, `math.mod`, `table.getn`, and `this` in event handlers as expected for that client version

Main Panel
<img width="731" height="248" alt="image" src="https://github.com/user-attachments/assets/008c2643-ccb4-43c4-95ab-42f39c1ff6d3" />

Guild Recruitment Panel
<img width="1206" height="1278" alt="image" src="https://github.com/user-attachments/assets/6b3658b1-2f69-4a70-8aa1-f1ea3bdbfa22" />

Consume panel
Log consumes button will log consumes with date time stamp in \TurtleWoW\Imports folder path /trtlog will also accomplish this function
<img width="1148" height="384" alt="image" src="https://github.com/user-attachments/assets/a347b653-8dd8-4d28-aea2-fb962e5a906f" />

Auto Invite window will allow you to put in a string of keywords that when whsipered will autoinvite people to your party
<img width="1091" height="577" alt="image" src="https://github.com/user-attachments/assets/b4310f7f-342c-41d3-b33d-7648f6cd91bf" />

Autosummon Window will allow you to make a custom warlock summon message and scan chat for people looking for summons in certain locations 
<img width="1253" height="1108" alt="image" src="https://github.com/user-attachments/assets/1524aa7e-a030-4db8-813a-57f63d0ce0ae" />

Both auto summon and guild recruitment have a count down timer for thier messages
<img width="900" height="200" alt="image" src="https://github.com/user-attachments/assets/e074768e-86c9-45e8-a8c9-e1c938fd1dd6" />

the check flask button will check for flasks and announce in officer who is missing
<img width="997" height="448" alt="image" src="https://github.com/user-attachments/assets/e712fbea-1a53-47a1-9734-c4d109de7789" />

the announce buffs button will announce who is missing what class buffs in raid
<img width="857" height="478" alt="image" src="https://github.com/user-attachments/assets/45e90605-7047-45c4-9d31-333efd8bda26" />

/trtlog will now log consumes at time of command in a new imports folder


Main Panel
<img width="731" height="248" alt="image" src="https://github.com/user-attachments/assets/008c2643-ccb4-43c4-95ab-42f39c1ff6d3" />

Guild Recruitment Panel
<img width="1206" height="1278" alt="image" src="https://github.com/user-attachments/assets/6b3658b1-2f69-4a70-8aa1-f1ea3bdbfa22" />

Consume panel
Log consumes button will log consumes with date time stamp in \TurtleWoW\Imports folder path /trtlog will also accomplish this function
<img width="1148" height="384" alt="image" src="https://github.com/user-attachments/assets/a347b653-8dd8-4d28-aea2-fb962e5a906f" />

Auto Invite window will allow you to put in a string of keywords that when whsipered will autoinvite people to your party
<img width="1091" height="577" alt="image" src="https://github.com/user-attachments/assets/b4310f7f-342c-41d3-b33d-7648f6cd91bf" />

Autosummon Window will allow you to make a custom warlock summon message and scan chat for people looking for summons in certain locations 
<img width="1253" height="1108" alt="image" src="https://github.com/user-attachments/assets/1524aa7e-a030-4db8-813a-57f63d0ce0ae" />

Both auto summon and guild recruitment have a count down timer for thier messages
<img width="900" height="200" alt="image" src="https://github.com/user-attachments/assets/e074768e-86c9-45e8-a8c9-e1c938fd1dd6" />

the check flask button will check for flasks and announce in officer who is missing
<img width="997" height="448" alt="image" src="https://github.com/user-attachments/assets/e712fbea-1a53-47a1-9734-c4d109de7789" />

the announce buffs button will announce who is missing what class buffs in raid
<img width="857" height="478" alt="image" src="https://github.com/user-attachments/assets/45e90605-7047-45c4-9d31-333efd8bda26" />

/trtlog will now log consumes at time of command in a new imports folder
