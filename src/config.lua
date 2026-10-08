return {
    -- First-run default only. Use Mod Settings > Gather Distance thereafter.
    -- Allowed distance: 10-200 metres in steps of 10.
    GatherRadiusMeters = 20,

    -- First-run controller default: B on Xbox, Circle on PlayStation.
    -- Use Mod Settings > Gather Button or settings.ini thereafter.
    GatherKey = "Gamepad_FaceButton_Right",
    GatherHoldSeconds = 0.6,

    -- Optional keyboard shortcut. Set to false to disable it.
    KeyboardGatherKey = "O",

    -- First-run default; Epic (purple) and Unique verified plants are opt-in.
    -- Use Mod Settings > Gather rare plants thereafter.
    GatherRarePlants = false,

    -- Legacy fallback; use the Logging selector in Mod Settings thereafter.
    debugLogging = false,
}
