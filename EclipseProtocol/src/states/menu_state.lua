local Menu = {}

local S  = require("src.settings")
local SM = StateManager

local selected = 1
local items    = { "START", "OPTIONS" }
local timer    = 0
local function getButtons(W, H)
    local by = math.floor(H * 0.73)
    local bh = math.floor(H * 0.09)
    local bw = math.floor(W * 0.18)
    return {
        { label="START",   x=math.floor(W*0.36)-bw/2, y=by, w=bw, h=bh },
        { label="OPTIONS", x=math.floor(W*0.62)-bw/2, y=by, w=bw, h=bh },
    }
end

function Menu:enter(data)
    Assets.startMusic()
    selected = 1
    timer    = 0
end

function Menu:leave() end

function Menu:update(dt)
    timer = timer + dt
end

function Menu:keypressed(key)
    if key == "left"  or key == "a" then selected = 1 end
    if key == "right" or key == "d" then selected = 2 end
    if key == "up"    or key == "w" then selected = 1 end
    if key == "down"  or key == "s" then selected = 2 end
    if key == "return" or key == "space" then self:activate(selected) end
    if key == "escape" then love.event.quit() end
end

function Menu:mousepressed(x, y, btn)
    if btn ~= 1 then return end
    local btns = getButtons(S.WIDTH, S.HEIGHT)
    for i, b in ipairs(btns) do
        if x >= b.x and x <= b.x+b.w and y >= b.y and y <= b.y+b.h then
            self:activate(i)
            return
        end
    end
end

function Menu:activate(idx)
    if idx == 1 then
        SM.switch("playing")
    else
        
        SM.switch("playing")
    end
end

function Menu:draw()
    local W, H  = S.WIDTH, S.HEIGHT
    local A     = Assets
    local img   = A.img.startMenu
    local iw, ih = img:getDimensions()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(img, 0, 0, 0, W/iw, H/ih)
    local btns   = getButtons(W, H)
    local pulse  = 0.5 + 0.5 * math.sin(timer * 4)

    for i, b in ipairs(btns) do
        if i == selected then
            love.graphics.setColor(1, 1, 0.4, 0.25 * pulse)
            love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 6, 6)
            love.graphics.setColor(1, 1, 0.6, 0.7 * pulse)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 6, 6)
        end
    end
    love.graphics.setFont(A.fonts.small)
    love.graphics.setColor(0.8, 0.85, 0.95, 0.8)
    local hint = "← → Navigate   Enter/Click Select   F11 Fullscreen"
    love.graphics.print(hint, W/2 - A.fonts.small:getWidth(hint)/2, H - 22)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Menu