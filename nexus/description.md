# Press to Gather - Configurable

Gather nearby harvestable plants and resources when you choose. **Hold B on Xbox / Circle on PlayStation for 0.6 seconds** by default, or **press O** on your keyboard. The gathering distance defaults to **20 metres** and can be set from **10 to 200 metres in 10-metre steps**, using the optional Mod Setting Menu or the settings file.

This mod builds on [Toggleable Auto Gather - Press to Gather by Tic0311](https://www.nexusmods.com/thebloodofdawnwalker/mods/381) with a configurable controller hold shortcut, an in-game gathering distance setting from 10 to 200 metres, and compatibility fixes for Framecore UE4SS Performance mode. Tic0311 credits [Auto Gathering by Volitio](https://www.nexusmods.com/thebloodofdawnwalker/mods/205) as the inspiration for the original mod.

## Controls and features

- Hold your chosen controller button for 0.6 seconds; the default is B on Xbox or Circle on PlayStation. Each hold gathers once; release the button to gather again.
- Select the controller button and gathering distance in the optional Mod Settings menu or edit the settings file.
- Targets eligible harvestable resources, not general loose world items or containers. The game still decides whether each resource can be harvested.

## Installation

- **Vortex:** Install Press-to-Gather-Configurable.zip through Vortex, enable it and deploy.
- **Manual:** Copy the archive's Data/PressToGather folder into ...\steamapps\common\The Blood of Dawnwalker\Dawnwalker\Binaries\Win64\ue4ss\Mods\, preserving the folder structure.

## Configuration

[Mod Setting Menu](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) (1.0.5 or later) is **optional**. Gathering works without it, with a **20-metre default** and **B / Circle held for 0.6 seconds**.

**With the menu:** Open **Main Menu → Mod Settings → Press to Gather - Configurable**. Set **Gather Distance** and **Gather Button**, select **Apply**, then **load a save**. Restarting the game also applies the saved settings.

**Without the menu:**

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

**Save the file and restart the game.** Your saved distance and button are used with or without the menu. The controller shortcut reads the physical button; other game actions assigned to it still work.

**Logging** is Off by default. Enable it using the menu's final entry or by setting **debugLogging = 1** in the same file; **0** turns it off. Messages appear in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

## Credits and source

- **Tic0311** — original [Toggleable Auto Gather - Press to Gather](https://www.nexusmods.com/thebloodofdawnwalker/mods/381) and its gathering logic. Modified and redistributed under the author's credited-use permissions.
- **Volitio** — [Auto Gathering](https://www.nexusmods.com/thebloodofdawnwalker/mods/205), credited by Tic0311 as the inspiration for the original mod.
- **mmarcussa** — the separate Mod Setting Menu framework. **Framecore and the UE4SS contributors** — the separate scripting runtime.

[Source repository and development history](https://github.com/my-mods/Press-to-Gather-Configurable)

## Permissions

Credit Tic0311 and this edition's contributors when sharing or modifying the mod. The original author's permissions allow credited redistribution, modifications, conversions, and asset use. Works using the original assets may not be sold. Donation Points require the original author's separate permission; this listing is not enrolled. The MIT License applies only to the bundled common-library module, not the entire mod. Game imagery retains its owners' rights and is excluded from the mod-code reuse grants.
