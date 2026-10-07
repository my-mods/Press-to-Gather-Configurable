# Press to Gather - Configurable

Gather nearby harvestable plants and resources when you choose. **Hold B on Xbox / Circle on PlayStation for 0.6 seconds** by default, or **press O** on your keyboard. The gathering distance defaults to **20 metres** and can be set from **10 to 200 metres in 10-metre steps**, using Mod Setting Menu or the settings file.

This mod builds on [Toggleable Auto Gather - Press to Gather by Tic0311](https://www.nexusmods.com/thebloodofdawnwalker/mods/381) with a configurable controller hold shortcut and an in-game gathering distance setting from 10 to 200 metres. Tic0311 credits [Auto Gathering by Volitio](https://www.nexusmods.com/thebloodofdawnwalker/mods/205) as the inspiration for the original mod.

## Controls and features

- Hold your chosen controller button for 0.6 seconds; the default is B on Xbox or Circle on PlayStation. Each hold gathers once; release the button to gather again.
- Choose from **14 controller buttons** and select the gathering distance in Mod Settings or edit the settings file.
- Gathers eligible harvestable resources and 17 additional wild plant types, including Cave Fungus, Comfrey and Green-Gilled Mushroom. Owned and quest-marked plants are excluded.

## Installation

- **Vortex:** Install Press-to-Gather-Configurable.zip through Vortex, enable it and deploy.
- **Manual:** Copy the archive's Data/PressToGather folder into ...\steamapps\common\The Blood of Dawnwalker\Dawnwalker\Binaries\Win64\ue4ss\Mods\, preserving the folder structure.
## Reporting Bugs and other issues

If you encounter an issue, set **Logging** to **Debug** in this mod’s Mod Setting Menu settings, apply the change, reproduce the issue. Then start either a bug report in the Bugs tab on Nexus (preferred method for me to track things), or at least start a new thread in comments and send me **Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log** from your game folder. Do not report unrelated bugs in other people's threads, please, this makes it impossible for me to track issues.

## Configuration

Open Mod Settings and press Apply to save and update gameplay.

**With the menu:** Open **Main Menu → Mod Settings → Press to Gather - Configurable**. Set **Gather Distance** and **Gather Button**, select **Apply** to save and update the active game. Restarting the game also applies the saved settings.

**Editing the settings file:**

1. Launch the game once with the mod enabled, then close it.
2. Open this generated file in a text editor:

```text
<game>/Dawnwalker/Binaries/Win64/ue4ss/Mods/PressToGather/settings.ini
```

In its existing **[Settings]** section, change **GatherRadiusMeters** to a value from **10 to 200**, in steps of **10**. Set **GatherButton** using the table below. Keep the other entries. The default values are:

```ini
[Settings]
GatherRadiusMeters = 20
GatherButton = 0
debugLogging = 0
```

| Value | Xbox button | PlayStation button |
| --- | --- | --- |
| `0` | B (default) | Circle |
| `1` | A | Cross |
| `2` | X | Square |
| `3` | Y | Triangle |
| `4` | LB | L1 |
| `5` | RB | R1 |
| `6` | LT | L2 |
| `7` | RT | R2 |
| `8` | Left stick click | L3 |
| `9` | Right stick click | R3 |
| `10` | D-pad Up | D-pad Up |
| `11` | D-pad Down | D-pad Down |
| `12` | D-pad Left | D-pad Left |
| `13` | D-pad Right | D-pad Right |

**Save the file and restart the game.** Your saved distance and button are read at startup. The controller shortcut reads the physical button; other game actions assigned to it still work.

**Logging** is Off by default. Enable it using the menu's final entry or by setting **debugLogging = 1** in the same file; **0** turns it off. Messages appear in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

Logging includes separate plant counts and reasons for skipped pickups, with up to three plant examples per gather. To investigate a missed plant, enable Logging, try Gather beside it, then check `UE4SS.log`.

## Credits and source

- **Tic0311** — original [Toggleable Auto Gather - Press to Gather](https://www.nexusmods.com/thebloodofdawnwalker/mods/381) and its gathering logic. Modified and redistributed under the author's credited-use permissions.
- **Volitio** — [Auto Gathering](https://www.nexusmods.com/thebloodofdawnwalker/mods/205), credited by Tic0311 as the inspiration for the original mod.
- **mmarcussa** — the separate Mod Setting Menu framework. **Vercadi and the UE4SS contributors** — the separate scripting runtime.

[Source repository and development history](https://github.com/my-mods/Press-to-Gather-Configurable)

## Permissions

Credit Tic0311, Volitio and this edition's contributors when sharing or modifying the mod. The original author's permissions allow credited redistribution, modifications, conversions, and asset use. Works using the original assets may not be sold. Donation Points require the original author's separate permission; this listing is not enrolled. The MIT License applies only to the bundled common-library module, not the entire mod. Game imagery retains its owners' rights and is excluded from the mod-code reuse grants.


## Live settings

Enable `HookProcessConsoleExec = 1` in your Vortex-managed `UE4SS-settings.ini` so Apply can update gameplay. This archive contains no replacement global UE4SS INI.

Settings are prepared when the game starts and are available from the main menu before the first save. Press **Apply** to save and update the active game. Changes made while loading are retained for the next valid player. Restore and Discard leave saved settings unchanged; Reset takes effect after Apply.

## My Dawnwalker mods

### Combat your way

**[Easier Parry and Dodge While Blocking](https://www.nexusmods.com/thebloodofdawnwalker/mods/161)**
Make parry and perfect-dodge windows longer or shorter to suit your timing.
**Highlights:** Consistent same-side or opposite-side ripostes; dodge while blocking; adjustable dodge invulnerability duration.

**[Combat Camera - Configurable](https://www.nexusmods.com/thebloodofdawnwalker/mods/480)**
Choose how your camera follows enemies and how you select your targets.
**Highlights:** Free, smooth or native tracking; camera-directed or fixed targets; automatic lock on hit; optional center dot.

**[Fair Duelist - Customizable Difficulty](https://www.nexusmods.com/thebloodofdawnwalker/mods/284)**
Build your own difficulty with precise control over combat balance.
**Highlights:** Enemy health and damage; stamina costs; normal, low-health and ranged attack delays; coordinated enemy attacks.

**[Health Regen - Configurable](https://www.nexusmods.com/thebloodofdawnwalker/mods/448)**
Set separate health regeneration rates for your human and vampire forms.
**Highlights:** Optional healing during combat; optional recovery of lost vampire segments; healing stops at the selected limit.

### Controls and exploration

**[Controller Tweaks and Remap](https://www.nexusmods.com/thebloodofdawnwalker/mods/203)**
Tailor your controller layout and make walking and menu access more comfortable.
**Highlights:** 31 controller settings; wider walking range; short press for Map, long press for Game Hub; controller stutter fixes.

**[Press to Gather - Configurable](https://www.nexusmods.com/thebloodofdawnwalker/mods/449)**
Gather nearby harvestable resources with one keyboard press or controller hold.
**Highlights:** Adjustable 10–200 m range; 14 controller button choices; support for 17 additional wild plant types.

**[Less Wildlife](https://www.nexusmods.com/thebloodofdawnwalker/mods/711)**
Make ordinary boar herds and wolf packs smaller—or larger.
**Highlights:** Population from 10% to 200%; separate boar and wolf switches; quest and named animals keep their normal values.

### Your view, your style

**[Quiet Dawn - Configurable HUD](https://www.nexusmods.com/thebloodofdawnwalker/mods/452)**
Clear the screen while keeping health and stamina alerts when you need them.
**Highlights:** 17 panels with independent opacity and size; hold-to-peek; configurable combat cues, enemy information and effect icons.

**[Style Without Sacrifice - Your Transmogrification Wardrobe](https://www.nexusmods.com/thebloodofdawnwalker/mods/721)**
Choose your equipment's appearance while keeping its stats.
**Highlights:** Separate day and night outfits; three saved presets; character preview; hide selected equipment; collected or all looks.

**[Night Vision - Configurable](https://www.nexusmods.com/thebloodofdawnwalker/mods/694)**
See in the dark as a vampire with natural colours or your preferred monochrome blend.
**Highlights:** Independent brightness and colour controls; keyboard or controller toggle; stays enabled through save loading and camera changes.
