## 1.4.0

- Leave quest-marked resources untouched, including ordinary harvestables, while continuing to gather safe nearby resources.
- Add Gather rare plants, Off by default. Enable it to gather purple Epic and Unique plants; blue Master plants are gathered normally.
- Fix missed nearby plants in streamed areas, including Cave Fungus when Gather rare plants is enabled.
- Choose Off, Error, Warning, Info or Debug logging; Warning is the default.

## 1.3

- Added support for more wild plants, including Cave Fungus, Comfrey and Green-Gilled Mushroom.

## 1.2

- Apply gathering distance and controller button changes during play without loading a save.
- Require release of the newly selected button before starting another gather.

# Changes

## Version 1.1

- Added a Gather Button setting with 14 controller buttons to choose from.
- Changed the default shortcut to holding B (Xbox) / Circle (PlayStation) for 0.6 seconds.
- Mod Setting Menu is optional; the same settings can be changed in settings.ini.

## Version 1.0

- Add controller gathering by holding RB / R1 for 0.6 seconds, once per hold, with keyboard O as an optional shortcut.
- Add a Mod Settings distance control from 10 to 200 metres in 10-metre steps, with a 20-metre default.
- Support Framecore UE4SS Performance mode through native input polling and game-thread scheduling.
- Remove readiness and cinematic-state checks that could prevent gathering from activating.
- Add a Logging toggle, default Off, and retain the original harvestable eligibility rules.
