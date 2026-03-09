local GameOver = {}
local S  = require("src.settings")
local SM = StateManager

local timer    = 0
local selected = 1
local items    = { "YES", "NO" }
local glitchX = 0

function GameOver:enter(data)
    timer    = 0
    selected = 1
    Assets.play("gameover")
end

function GameOver:leave() end

function GameOver:keypressed(key)
    if key == "left"  or key == "a" then selected = 1 end
    if key == "right" or key == "d" then selected = 2 end
    if key == "return" or key == "space" then
        if selected == 1 then SM.switch("playing")
        else                  SM.switch("menu") end
    end
    if key == "escape" then SM.switch("menu") end
end

function GameOver:mousepressed(x, y, btn)
    if btn ~= 1 then return end
    local W, H = S.WIDTH, S.HEIGHT
    local by = math.floor(H * 0.70)
    local bh = 28
    local bw = 60
    if y >= by and y <= by+bh then
        if x >= W/2 - 90 and x <= W/2 - 30 then
            SM.switch("playing"); return
        end
        if x >= W/2 + 10 and x <= W/2 + 70 then
            SM.switch("menu"); return
        end
    end
end

function GameOver:update(dt)
    timer   = timer + dt
    glitchX = love.math.random(-2, 2)
end

function GameOver:draw()
    local W, H = S.WIDTH, S.HEIGHT
    local A    = Assets
    local img  = A.img.gameOver
    local iw, ih = img:getDimensions()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(img, 0, 0, 0, W/iw, H/ih)
    if math.floor(timer * 8) % 7 == 0 then
        love.graphics.setColor(0, 0.5, 1.0, 0.08)
        love.graphics.rectangle("fill", 0, H*0.45, W, H*0.12)
    end
    local pulse = 0.5 + 0.5 * math.sin(timer * 5)
    local by    = math.floor(H * 0.70)
    local bh    = 28
    if selected == 1 then
        love.graphics.setColor(0.3, 0.7, 1.0, 0.3 * pulse)
        love.graphics.rectangle("fill", W/2-90, by, 60, bh, 4, 4)
        love.graphics.setColor(0.5, 0.9, 1.0, 0.8 * pulse)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", W/2-90, by, 60, bh, 4, 4)
    else
        love.graphics.setColor(0.2, 0.4, 0.7, 0.15)
        love.graphics.rectangle("fill", W/2-90, by, 60, bh, 4, 4)
    end
    if selected == 2 then
        love.graphics.setColor(0.3, 0.7, 1.0, 0.3 * pulse)
        love.graphics.rectangle("fill", W/2+10, by, 60, bh, 4, 4)
        love.graphics.setColor(0.5, 0.9, 1.0, 0.8 * pulse)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", W/2+10, by, 60, bh, 4, 4)
    else
        love.graphics.setColor(0.2, 0.4, 0.7, 0.15)
        love.graphics.rectangle("fill", W/2+10, by, 60, bh, 4, 4)
    end
    local alpha = math.min(1, timer * 1.2)
    love.graphics.setFont(A.fonts.small)
    local shd   = SM.shared
    local lines = {
        string.format("Score:  %d", shd.score or 0),
        string.format("Rooms:  %d", shd.roomsCleared or 0),
        string.format("Time:   %02d:%02d",
            math.floor((shd.timeSurvived or 0)/60),
            math.floor((shd.timeSurvived or 0)%60)),
    }
    love.graphics.setColor(0.6, 0.85, 1.0, alpha * 0.9)
    for i, ln in ipairs(lines) do
        love.graphics.print(ln, W/2 - A.fonts.small:getWidth(ln)/2,
            H * 0.78 + (i-1)*16)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

return GameOver
