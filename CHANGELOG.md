# Changes

## Development changes

- Fix RB and keyboard O being blocked during normal gameplay by an unsupported controller cinematic-state lookup.
- Add Gather Distance to Mod Settings: 10–200 metres in 10-metre steps, with a default of 100 metres. Saved distance changes apply on save load or game restart.
- Add a Logging toggle and persistent menu preferences using ue4ss-common.
- Enable gathering from the local possessed pawn without waiting for character-stat initialization.
- Report player readiness, first controller input and first gather outcome; keyboard O can retry exhausted player discovery.
- Hold RB / R1 for 0.6 seconds to gather once; short taps do not gather.
- Increase the gather radius and supported maximum to 100 metres.
- Keep keyboard O as an optional gather shortcut.
- Reset held input across player changes and loading screens.
- Block gathering while paused, when a cursor is shown, or while movement input is disabled.
- Process harvestable interactions in small batches.
- Make detailed gather logging optional.
