# Press to Gather - Configurable

Gather nearby harvestable resources by holding **RB / R1 for 0.6 seconds**. Choose a distance from **10 to 200 metres, in 10-metre steps**, in Mod Settings; the default is **20 metres**. Short taps do not gather; each hold gathers once, and releasing the button permits another gather. Keyboard **O** also gathers once.

This personal customization is based on Toggleable Auto Gather by **Tic0311**: https://www.nexusmods.com/thebloodofdawnwalker/mods/381. It retains the original HarvestableComponent eligibility and interaction behavior. General world loot is excluded.

Tic0311 credits **Volitio's Auto Gathering** as the inspiration for the original mod. The upstream permissions allow credited modifications and redistribution; see `LICENSE.txt` for the restrictions and the separate shared-library license.

## Requirements and compatibility

- The Blood of Dawnwalker; reference Steam build 25232147.
- UE4SS with `ExecuteInGameThreadWithDelay`, `LoopInGameThreadWithDelay`, and `CancelDelayedAction`. The reference is Framecore 2b, based on UE4SS revision 97b7e501c.
- Dawnwalker Mod Settings 1.0.5 or later for the settings page; reference menu version 1.0.5.1. Gathering can run without the menu.
- Only one Auto Gather range variant should be active.

Framecore 2b Performance provides the native hooks and EngineTick scheduling used here. Its Blueprint, LoadMap and BeginPlay hooks can remain disabled.

The controller binding reads the physical Unreal key. A remapped game action does not change this binding. Other game actions on the same button can still run. Gathering is blocked while loading, paused, the mouse cursor is shown, or movement input is disabled, including cutscenes that lock movement. After loading or a blocked input, release the button before beginning a new hold.

## Install or update with Vortex

1. Close the game. Back up the previous mod's `TogAutGat/Scripts/config.lua` and `TogAutGat/settings.ini`, or the corresponding files under `PressToGather` when updating this renamed package. The package supplies a complete `config.lua` and does not merge its advanced controls; it does not contain a personal `settings.ini`.
2. Disable the existing Auto Gather entry and deploy in Vortex.
3. Install `Press-to-Gather-Configurable.zip` through Vortex, replacing/reinstalling the existing entry. Select the UE4SS Lua mod type when requested. This renamed package uses a new runtime folder, so run the installer again instead of only redeploying the previous archive. Keep just this gather mod enabled.
4. Deploy, then restart the game. Hold RB / R1 near harvestable resources, or press O.

The runtime folder is `Dawnwalker/Binaries/Win64/ue4ss/Mods/PressToGather`. The package supplies `enabled.txt`, `mod_settings.ini`, and five Lua files in `Scripts`: `main.lua`, `config.lua`, `ControllerHold.lua`, `SettingsMenu.lua`, and `SettingsStore.lua`. This replacement must win any conflicts with an older Auto Gather variant.

The renamed mod creates fresh preferences under `PressToGather` from its packaged defaults: 20 m and Logging Off. It does not read or import the old `TogAutGat/settings.ini`. Later updates use the existing `PressToGather/settings.ini`. Keep the old `TogAutGat` mod disabled to avoid duplicate input handlers and menu entries.

## Configuration

Open **Mod Settings → Press to Gather - Configurable → Gather Distance**. Select **10–200 m** in **10 m** steps, choose **Apply**, then **load a save** to use the new distance. Restarting the game also applies saved values. The final entry, **Logging**, enables detailed troubleshooting and is Off by default.

The mod creates `PressToGather/settings.ini` on its first launch. Distance and Logging are read from this file at startup and when save loading completes. Changes made in the menu wait for one of those events; no settings file is polled during gameplay.

The package's `PressToGather/Scripts/config.lua` contains startup defaults and advanced controls:

| Setting | Default | Meaning |
| --- | --- | --- |
| `GatherRadiusMeters` | `20` | First-run distance, clamped to 10–200 and rounded to the nearest 10. Saved menu preferences take precedence afterward. |
| `GatherKey` | `"Gamepad_RightShoulder"` | Native Unreal controller key; RB / R1. |
| `GatherHoldSeconds` | `0.6` | Hold duration, clamped to 0.2–5 seconds. |
| `KeyboardGatherKey` | `"O"` | UE4SS keyboard key; `false` disables the shortcut. |
| `debugLogging` | `false` | First-run Logging default. Saved menu preferences take precedence afterward. |

Apply advanced control changes through your Vortex-managed files, then restart the game. If the menu is unavailable, distance and Logging can be edited in the generated `settings.ini` before restarting. Detailed logs are written to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`, prefixed with `[PressToGather]`. Player readiness, the first detected controller press/hold, the first gather result, and actionable errors are reported once even with Logging Off. If discovery has stopped, keyboard O retries it; press O again once the player is ready.

## Uninstall

Disable or remove the entry in Vortex and deploy. Restart the game. To restore the original controls/range, reinstall the original Auto Gather archive through Vortex.

## Source

`src` contains the runtime Lua and configuration. `upstream` retains the original scripts; `SOURCE.json` records their hashes and origin. `package` contains metadata and documentation. The ZIP keeps runtime files under `Data/PressToGather` and release metadata at its root, with explicit Vortex instructions that prevent documentation from deploying into the game.

To recreate the archive, place all five `src/*.lua` files in `Data/PressToGather/Scripts`. Place `src/mod_settings.ini` and `package/enabled.txt` in `Data/PressToGather`. Put `package/mod.manifest`, `package/README.txt`, `package/vortex_override_instructions.json`, `LICENSE.txt`, `CHANGELOG.md`, `RELEASE-NOTES.md`, `SOURCE.json`, and `ue4ss-common.lock.json` at the archive root, retaining the `LICENSES/ue4ss-common.txt` path. ZIP those contents as `Press-to-Gather-Configurable.zip`. Do not include the enclosing build folder, upstream snapshots, or a personal `settings.ini`.

`SettingsStore.lua` is included from the MIT-licensed [ue4ss-common](https://github.com/my-mods/ue4ss-common) library. `ue4ss-common.lock.json` pins its source commit and file hashes; no separate common-library installation is required.

Upstream rights remain with their author. See `LICENSE.txt`.
