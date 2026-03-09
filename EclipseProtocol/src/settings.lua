local S = {}

S.WIDTH  = 800
S.HEIGHT = 600
S.TITLE  = "Eclipse Protocol"

S.PLAYER = {
    SPEED         = 180,
    DASH_SPEED    = 480,
    DASH_DURATION = 0.18,
    DASH_COOLDOWN = 1.2,
    MAX_HEALTH    = 100,
    MAX_ENERGY    = 100,
    ENERGY_REGEN  = 8,
    DASH_COST     = 25,
    INVULN_TIME   = 1.2,
    KNOCKBACK     = 120,
    WIDTH         = 24,
    HEIGHT        = 28,
    COLLISION_W   = 24,
    COLLISION_H   = 30,
}

S.PATROL = {
    SPEED       = 70,
    WIDTH       = 40,
    HEIGHT      = 40,
    DAMAGE      = 10,
    PATROL_DIST = 96,
}

S.HUNTER = {
    BASE_SPEED   = 90,
    WIDTH        = 60,
    HEIGHT       = 60,
    DAMAGE       = 15,
    DETECT_RANGE = 180,
    CHASE_RANGE  = 220,
}

S.ENERGY_CELL = {
    WIDTH  = 28,
    HEIGHT = 28,
    VALUE  = 30,
}

S.POWER_NODE = {
    WIDTH       = 20,
    HEIGHT      = 20,
    REPAIR_TIME = 2.5,
}

S.ROOM = {
    TILE           = 32,
    COLS           = 25,
    ROWS           = 18,
    WALL_THICK     = 1,
    MIN_ROOMS      = 5,
    MAX_ROOMS      = 10,
    NODES_PER_ROOM = {1, 2},
    CELLS_PER_ROOM = {2, 4},
    NODES_NEEDED   = 5,
}

S.DIFF = {
    SPEED_FACTOR  = 0.05,
    DETECT_FACTOR = 10,
    SPAWN_BASE    = 2,
    SPAWN_PER_ROOM= 1,
}

S.COLOR = {
    BG         = {0.06, 0.07, 0.10},
    WALL       = {0.18, 0.20, 0.26},
    FLOOR      = {0.10, 0.11, 0.14},
    ACCENT     = {0.20, 0.70, 1.00},
    HEALTH_BAR = {0.85, 0.20, 0.20},
    ENERGY_BAR = {0.20, 0.70, 1.00},
    HUD_BG     = {0.05, 0.05, 0.08, 0.85},
    TEXT       = {0.90, 0.92, 0.95},
    DAMAGE_FLASH={1.00, 0.10, 0.10, 0.45},
    DOOR       = {0.20, 0.90, 0.50},
    NODE       = {1.00, 0.70, 0.10},
    CELL       = {0.30, 0.90, 1.00},
    WHITE      = {1, 1, 1},
}

return S