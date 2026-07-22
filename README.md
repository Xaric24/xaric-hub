# 🎮 Xaric Hub

Xaric Hub is a Roblox script hub with game detection, a searchable launcher, and individual game modules.

## Launch the Hub

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Xaric24/xaric-hub/v2.0.1/xaric_hub.lua"))()
```

For a local checkout, execute `xaric_hub.lua` from your executor workspace instead.

## Included Modules

| Module | Game | Highlights |
|---|---|---|
| 🌷 Bloom v3 | The Garden Frontier | Auto-farm, planting, harvesting, selling, shop actions |
| 🌱 Reseeder | Be A Seed? | Collect, run, settings, movement tools |
| 🐟 Cobalt v3 | BE A FISH BAIT! | Fishing, training, QTE, movement |
| ⚔ Warhead v1 | Missiles vs Cities | Farming, firing, upgrade and utility controls |
| 🧠 BrainSnatch v1 | Catch a Brainrot | Battle automation, ESP, movement |
| 🌿 GreenThumb v1 | My Greenhouse! | Collect, harvest, sell, planting, ESP |
| ⭐ StarForge v1 | Make a Galaxy ✨ | Collect, sell, crate, fusion controls |
| 🐺 Coyote v1 | San Diego Border RP | Player and vehicle utility tools |
| ⛏️ CrushForge v1 | Build An Ore Crusher | Mining, selling, rolling, upgrades |
| 🦠 Pathogen v1 | Parasite.exe | Growth, attacks, dummies, contracts |
| 🪓 Timber v1 | My Wood Farm | Collect, sell, upgrade, spin, equipment, anti-AFK |
| 🔧 Cobalt GUI | Universal Dev Tools | Executor, console, explorer, remote inspection |

## How It Works

1. Run the hub loadstring.
2. Xaric Hub detects the current game when possible.
3. Wait for the automatic launch countdown, or select a module manually.
4. Use the module controls for the selected game.

## Hub Features

- Game detection with manual override
- Searchable module launcher
- Local-file loading when available, with GitHub fallback
- Clear load errors for unavailable or malformed scripts
- Protected UI loading for Rayfield-based modules
- Version-pinned module loading with retryable launch failures

## Compatibility

- Requires an executor that supports `loadstring`, `game:HttpGet`, `getgenv`, and protected UI parenting (`gethui` or `CoreGui`).
- Game updates can change remote names, module paths, and UI layouts. If a module fails, reopen the hub and select it again to retain the displayed error.

## Timber v1 Notes

- Auto Spin scans every available stand and buys only the highest qualifying axe upgrade.
- Auto-Upgrades handles Mutation, Luck, and additional Spin Stands one purchase at a time.
- Anti-AFK and safe reinjection are included.

## Repository Layout

- `xaric_hub.lua` — main launcher
- `*_cheats.lua` — game-specific modules
- `cobalt_gui.lua` — universal developer-tools interface
