local StateManager = {}
local stateModules = {
    menu     = "src.states.menu_state",
    playing  = "src.states.play_state",
    pause    = "src.states.pause_state",
    gameover = "src.states.gameover_state",
    victory  = "src.states.victory_state",
}

local loaded  = {} 
local current = nil 
local currentName = ""
StateManager.shared = { score = 0, roomsCleared = 0, timeSurvived = 0 }

local function getState(name)
    if not loaded[name] then
        loaded[name] = require(stateModules[name])
    end
    return loaded[name]
end

function StateManager.switch(name, data)
    assert(stateModules[name], "Unknown state: " .. tostring(name))

    if current and current.leave then
        current:leave()
    end

    current     = getState(name)
    currentName = name

    if current.enter then
        current:enter(data or {})
    end
end

function StateManager.current()
    return currentName
end

function StateManager.update(dt)
    if current and current.update then current:update(dt) end
end

function StateManager.draw()
    if current and current.draw then current:draw() end
end

function StateManager.keypressed(key, sc, rep)
    if current and current.keypressed then current:keypressed(key, sc, rep) end
end

function StateManager.keyreleased(key)
    if current and current.keyreleased then current:keyreleased(key) end
end

function StateManager.mousepressed(x, y, btn)
    if current and current.mousepressed then current:mousepressed(x, y, btn) end
end

function StateManager.mousereleased(x, y, btn)
    if current and current.mousereleased then current:mousereleased(x, y, btn) end
end

return StateManager