# Press to Gather - Configurable

Gather nearby harvestable plants and resources when you choose. **Hold B on Xbox / Circle on PlayStation for 0.6 seconds** by default, or **press O** on your keyboard. The gathering distance defaults to **20 metres** and can be set from **10 to 200 metres in 10-metre steps**, using Mod Setting Menu or the settings file.

This mod builds on [Toggleable Auto Gather - Press to Gather by Tic0311](https://www.nexusmods.com/thebloodofdawnwalker/mods/381) with a configurable controller hold shortcut, an in-game gathering distance setting from 10 to 200 metres, and compatibility fixes for Framecore UE4SS Performance mode. Tic0311 credits [Auto Gathering by Volitio](https://www.nexusmods.com/thebloodofdawnwalker/mods/205) as the inspiration for the original mod.

## Dependencies

- [UE4SS for BoD](https://www.nexusmods.com/thebloodofdawnwalker/mods/283) 2b or later, or [UE4SS for Dawnwalker](https://www.nexusmods.com/thebloodofdawnwalker/mods/18) 1.3 or later.
- Required: [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).

## Installation

- **Vortex:** Install Press-to-Gather-Configurable.zip through Vortex, enable it and deploy.
- **Manual:** Copy the archive's Data/PressToGather folder into ...\steamapps\common\The Blood of Dawnwalker\Dawnwalker\Binaries\Win64\ue4ss\Mods\, preserving the folder structure.

## Configuration

Mod Setting Menu 1.0.6 or later is required. Its callback bridge also requires `HookProcessConsoleExec = 1` in `UE4SS-settings.ini`. Manage that loader setting through your Vortex loader configuration; this archive contains no replacement global UE4SS INI.

Settings are prepared when the game starts and are available from the main menu before the first save. Press **Apply** to save and update the active game. Changes made while loading are retained for the next valid player. Restore and Discard leave saved settings unchanged; Reset takes effect after Apply.

Distance and Logging update immediately. Changing Gather Button rebuilds its cached key once, clears the current hold, and requires release before gathering again. A gather already in progress finishes with the distance captured when it began.

Logging is the final, sole diagnostic control. It changes immediately; verbose logging is Off by default. Logs are written to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Settings are never polled.

Required: [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271). Open Mod Settings and press Apply to save and update gameplay.

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

**Save the file and restart the game.** Your saved distance and button are also read at startup. The controller shortcut reads the physical button; other game actions assigned to it still work.

**Logging** is Off by default. Enable it using the menu's final entry or by setting **debugLogging = 1** in the same file; **0** turns it off. Messages appear in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

## Credits and source

- **Tic0311** — original [Toggleable Auto Gather - Press to Gather](https://www.nexusmods.com/thebloodofdawnwalker/mods/381) and its gathering logic. Modified and redistributed under the author's credited-use permissions.
- **Volitio** — [Auto Gathering](https://www.nexusmods.com/thebloodofdawnwalker/mods/205), credited by Tic0311 as the inspiration for the original mod.
- **mmarcussa** — the separate Mod Setting Menu framework. **Framecore and the UE4SS contributors** — the separate scripting runtime.

[Source repository and development history](https://github.com/my-mods/Press-to-Gather-Configurable)

See `LICENSE.txt` for reuse terms and the included license notices.
