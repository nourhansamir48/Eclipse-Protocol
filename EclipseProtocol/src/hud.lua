local HUD = {}

local S = require("src.settings")
local C = S.COLOR

local damageFlash = 0

function HUD.notifyDamage()
    damageFlash = 1.0
end

function HUD.draw(player, room, timeSurvived, message, msgTimer)
    local W = S.WIDTH
    local A = Assets

    love.graphics.setColor(C.HUD_BG)
    love.graphics.rectangle("fill", 0, 0, W, 48)

    love.graphics.setColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, 48, W, 48)

    love.graphics.setFont(A.fonts.hud)
    love.graphics.setColor(C.ACCENT)
    love.graphics.print("ECLIPSE PROTOCOL", W - 138, 6)
    love.graphics.setColor(0.55, 0.60, 0.70)
    love.graphics.print("ROOM " .. (room and room.index or "?"), W - 98, 22)

    local barX = 10
    local barY = 8

    love.graphics.setFont(A.fonts.hud)
    love.graphics.setColor(C.TEXT)
    love.graphics.print("HEALTH", barX, barY)

    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", barX, barY + 14, 110, 10, 2, 2)

    local hpct = player.health / player.maxHealth
    local hr, hg, hb
    if hpct > 0.5 then
        hr, hg, hb = 0.2, 0.85, 0.35
    elseif hpct > 0.25 then
        hr, hg, hb = 0.9, 0.65, 0.1
    else
        hr, hg, hb = 0.9, 0.15, 0.15
    end
    love.graphics.setColor(hr, hg, hb)
    love.graphics.rectangle("fill", barX, barY + 14, 110 * hpct, 10, 2, 2)

    love.graphics.setColor(0.40, 0.42, 0.50)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", barX, barY + 14, 110, 10, 2, 2)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(math.ceil(player.health), barX + 112, barY + 13)

    local ebarX = barX + 160

    love.graphics.setFont(A.fonts.hud)
    love.graphics.setColor(C.ACCENT)
    love.graphics.print("ENERGY", ebarX, barY)

    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", ebarX, barY + 14, 110, 10, 2, 2)

    local epct = player.energy / player.maxEnergy
    love.graphics.setColor(C.ENERGY_BAR)
    love.graphics.rectangle("fill", ebarX, barY + 14, 110 * epct, 10, 2, 2)

    love.graphics.setColor(0.40, 0.42, 0.50)
    love.graphics.rectangle("line", ebarX, barY + 14, 110, 10, 2, 2)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(math.ceil(player.energy), ebarX + 112, barY + 13)

    local dcoolX = ebarX + 160
    local dcoolPct = math.max(0, 1 - player.dashCooldown / S.PLAYER.DASH_COOLDOWN)
    love.graphics.setFont(A.fonts.hud)
    love.graphics.setColor(0.60, 0.65, 0.75)
    love.graphics.print("DASH", dcoolX, barY)

    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", dcoolX, barY + 14, 60, 10, 2, 2)

    if player.energy >= S.PLAYER.DASH_COST and dcoolPct >= 1 then
        love.graphics.setColor(0.20, 0.90, 1.00)
    else
        love.graphics.setColor(0.25, 0.40, 0.65)
    end
    love.graphics.rectangle("fill", dcoolX, barY + 14, 60 * dcoolPct, 10, 2, 2)
    love.graphics.setColor(0.40, 0.42, 0.50)
    love.graphics.rectangle("line", dcoolX, barY + 14, 60, 10, 2, 2)

    local scoreX = dcoolX + 80
    love.graphics.setFont(A.fonts.hud)
    love.graphics.setColor(C.TEXT)
    love.graphics.print(string.format("SCORE %05d", player.score), scoreX, barY)

    local mins = math.floor(timeSurvived / 60)
    local secs = math.floor(timeSurvived % 60)
    love.graphics.setColor(0.65, 0.70, 0.80)
    love.graphics.print(string.format("TIME  %02d:%02d", mins, secs), scoreX, barY + 14)

    local nX = scoreX + 100
    love.graphics.setColor(C.NODE)
    love.graphics.print(string.format("NODES %d/%d",
        player.nodesFixed, S.ROOM.NODES_NEEDED), nX, barY)

    if message and msgTimer and msgTimer > 0 then
        local alpha = math.min(1, msgTimer * 3)
        love.graphics.setFont(A.fonts.medium)
        love.graphics.setColor(1, 1, 0.6, alpha)
        local mw = A.fonts.medium:getWidth(message)
        love.graphics.print(message, W/2 - mw/2, 58)
    end

    if damageFlash > 0 then
        love.graphics.setColor(C.DAMAGE_FLASH[1],
                               C.DAMAGE_FLASH[2],
                               C.DAMAGE_FLASH[3],
                               C.DAMAGE_FLASH[4] * damageFlash)
        love.graphics.rectangle("fill", 0, 48,
                                 S.WIDTH, S.HEIGHT - 48)
        damageFlash = math.max(0, damageFlash - love.timer.getDelta() * 3)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

return HUD