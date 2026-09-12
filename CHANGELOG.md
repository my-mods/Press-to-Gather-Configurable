# Changes

## Development changes

- Enable gathering from the local possessed pawn without waiting for character-stat initialization.
- Report player readiness, first controller input and first gather outcome; keyboard O can retry exhausted player discovery.
- Hold RB / R1 for 0.6 seconds to gather once; short taps do not gather.
- Increase the gather radius and supported maximum to 100 metres.
- Keep keyboard O as an optional gather shortcut.
- Reset held input across player changes and loading screens.
- Block gathering while paused, in cinematic mode, when a cursor is shown, or while movement input is disabled.
- Process harvestable interactions in small batches.
- Make detailed gather logging optional.
