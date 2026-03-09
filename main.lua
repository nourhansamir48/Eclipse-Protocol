StateManager = require("src.state_manager")
Assets       = require("src.assets")
Settings     = require("src.settings")

math.randomseed(os.time())

function love.load()
    love.window.setTitle("Eclipse Protocol")
    love.window.setMode(Settings.WIDTH, Settings.HEIGHT, {
        resizable = false,
        vsync     = true,
    })
    love.graphics.setDefaultFilter("linear", "linear")

    Assets.load()
    StateManager.switch("menu")
end

function love.update(dt)
    dt = math.min(dt, 0.05)
    StateManager.update(dt)
end

function love.draw()
    StateManager.draw()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
        return
    end
    StateManager.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key)
    StateManager.keyreleased(key)
end

function love.mousepressed(x, y, button)
    StateManager.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    StateManager.mousereleased(x, y, button)
end

function love.quit()
    return false
end