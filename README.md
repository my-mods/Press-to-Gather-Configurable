# Toggleable Auto Gather - Press to Gather

Gather nearby harvestable resources by holding **RB / R1 for 0.6 seconds**. The radius is **100 metres**. Short taps do not gather; each hold gathers once, and releasing the button permits another gather. Keyboard **O** also gathers once.

This personal customization is based on Toggleable Auto Gather by **Tic0311**: https://www.nexusmods.com/thebloodofdawnwalker/mods/381. It retains the original HarvestableComponent eligibility and interaction behavior. General world loot is excluded.

## Requirements and compatibility

- The Blood of Dawnwalker; reference Steam build 25232147.
- UE4SS with `ExecuteInGameThreadWithDelay`, `LoopInGameThreadWithDelay`, and `CancelDelayedAction`. The reference is Framecore 2b, based on UE4SS revision 97b7e501c.
- Only one Auto Gather range variant should be active.

The controller binding reads the physical Unreal key. A remapped game action does not change this binding. Other game actions on the same button can still run. Gathering is blocked while paused, cinematic mode is active, the mouse cursor is shown, or movement input is disabled. After loading or a blocked input, release the button before beginning a new hold.

## Install or update with Vortex

1. Close the game. Back up any personal Auto Gather `config.lua` preferences; this package replaces that file in full and does not merge settings.
2. Disable the existing Auto Gather entry and deploy in Vortex.
3. Install `Toggleable-Auto-Gather.zip` through Vortex, replacing the existing entry. Select the UE4SS Lua mod type when requested. Keep just this range variant enabled.
4. Deploy, then restart the game. Hold RB / R1 near harvestable resources, or press O.

The runtime folder remains `Dawnwalker/Binaries/Win64/ue4ss/Mods/TogAutGat`. The package supplies `enabled.txt`, `Scripts/main.lua`, `Scripts/config.lua`, and `Scripts/ControllerHold.lua`. This replacement must win any conflicts on those files with an older Auto Gather variant.

## Configuration

The package's `TogAutGat/Scripts/config.lua` contains:

| Setting | Default | Meaning |
| --- | --- | --- |
| `GatherRadiusMeters` | `100` | Radius in metres, clamped to 1–100. |
| `GatherKey` | `"Gamepad_RightShoulder"` | Native Unreal controller key; RB / R1. |
| `GatherHoldSeconds` | `0.6` | Hold duration, clamped to 0.2–5 seconds. |
| `KeyboardGatherKey` | `"O"` | UE4SS keyboard key; `false` disables the shortcut. |
| `debugLogging` | `false` | Detailed events, errors and gather counts. |

Apply configuration changes through your Vortex-managed files, then restart the game. Detailed logs are written to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`, prefixed with `[TBODAutoGather]`. Logging is off by default; startup and actionable errors are still reported.

## Uninstall

Disable or remove the entry in Vortex and deploy. Restart the game. To restore the original controls/range, reinstall the original Auto Gather archive through Vortex.

## Source

`src` contains the runtime Lua and configuration. `upstream` retains the original scripts; `SOURCE.json` records their hashes and origin. `package` contains metadata and documentation. The ZIP keeps runtime files under `Data/TogAutGat` and release metadata at its root, with explicit Vortex instructions that prevent documentation from deploying into the game.

To recreate the archive, place the three `src/*.lua` files in `Data/TogAutGat/Scripts` and `package/enabled.txt` in `Data/TogAutGat`. Put `package/mod.manifest`, `package/README.txt`, `package/vortex_override_instructions.json`, `LICENSE.txt`, `CHANGELOG.md`, `RELEASE-NOTES.md`, and `SOURCE.json` at the archive root. ZIP those contents as `Toggleable-Auto-Gather.zip`. Do not include the enclosing build folder or the upstream snapshots.

Upstream rights remain with their author. See `LICENSE.txt`.
