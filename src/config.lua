return {
    -- Harvestable resources within this distance; maximum 100 metres.
    GatherRadiusMeters = 100,

    -- Native Unreal button name: RB on Xbox, R1 on PlayStation.
    GatherKey = "Gamepad_RightShoulder",
    GatherHoldSeconds = 0.6,

    -- Optional keyboard shortcut. Set to false to disable it.
    KeyboardGatherKey = "O",

    -- Detailed events and gather counts in ue4ss/UE4SS.log.
    debugLogging = false,
}
