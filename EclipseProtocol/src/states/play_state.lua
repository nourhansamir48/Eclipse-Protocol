local Play = {}

local S      = require("src.settings")
local Player = require("src.player")
local Room   = require("src.room")
local HUD    = require("src.hud")

local player, currentRoom, roomIndex, timeSurvived
local message, msgTimer
local screenShake, globalTimer
local evacActive, evacTimer, EVAC_DURATION
local transFlash, lastHealth

EVAC_DURATION = 15

local function showMessage(msg, dur)
    message  = msg
    msgTimer = dur or 2.5
end

local function triggerShake(intensity, dur)
    screenShake = { ox=0, oy=0,
        duration = dur or 0.25,
        timer    = dur or 0.25,
        intensity= intensity or 4 }
end

function Play:enter(data)
    Assets.startMusic()
    roomIndex    = 1
    timeSurvived = 0
    globalTimer  = 0
    evacActive   = false
    evacTimer    = 0
    transFlash   = 0
    message      = nil
    msgTimer     = 0
    screenShake  = nil

    currentRoom  = Room.generate(roomIndex)
    player       = Player.new(currentRoom.playerSpawnX, currentRoom.playerSpawnY)
    lastHealth   = player.health

    showMessage("Station power critical - repair nodes to escape!", 3.5)
end

function Play:leave()
    Assets.stopMusic()
    Assets.stopFootsteps()
end

function Play:update(dt)
    globalTimer  = globalTimer  + dt
    timeSurvived = timeSurvived + dt

    if screenShake then
        screenShake.timer = screenShake.timer - dt
        if screenShake.timer <= 0 then
            screenShake = nil
        else
            local p = screenShake.timer / screenShake.duration
            local i = screenShake.intensity * p
            screenShake.ox = love.math.random(-i, i)
            screenShake.oy = love.math.random(-i, i)
        end
    end

    if msgTimer > 0 then msgTimer = msgTimer - dt end
    if transFlash > 0 then transFlash = math.max(0, transFlash - dt*3) end

    player:update(dt, currentRoom)

    if player.health < lastHealth then
        HUD.notifyDamage()
        triggerShake(6, 0.2)
    end
    lastHealth = player.health

    currentRoom:update(dt, player)
    currentRoom:tryCollectCells(player)

    if not evacActive and player.nodesFixed >= S.ROOM.NODES_NEEDED then
        evacActive = true
        evacTimer  = EVAC_DURATION
        showMessage("!! EVACUATION SEQUENCE INITIATED !! Survive 15 seconds!", 4)
        triggerShake(10, 0.4)
    end

    if evacActive then
        evacTimer = evacTimer - dt
        if evacTimer <= 0 then
            StateManager.shared.score        = player.score
            StateManager.shared.roomsCleared = roomIndex
            StateManager.shared.timeSurvived = timeSurvived
            StateManager.switch("victory")
            return
        end
    end

  
    if currentRoom:checkDoorTrigger(player) then
        self:loadNextRoom()
        return
    end

    if not player.alive then
        StateManager.shared.score        = player.score
        StateManager.shared.roomsCleared = roomIndex
        StateManager.shared.timeSurvived = timeSurvived
        Assets.play("gameover")
        StateManager.switch("gameover")
        return
    end
end

function Play:loadNextRoom()
    Assets.play("door")
    roomIndex    = roomIndex + 1
    transFlash   = 1.0
    currentRoom  = Room.generate(roomIndex)
    player.x     = currentRoom.playerSpawnX
    player.y     = currentRoom.playerSpawnY
    player.vx, player.vy = 0, 0
    player.score = player.score + 100
    triggerShake(8, 0.3)
    showMessage("Sector " .. roomIndex .. " - " ..
        (roomIndex % 3 == 0 and "Hostile zone detected" or
         roomIndex % 2 == 0 and "Power grid unstable"   or
         "Scanning for nodes..."), 2)
end

function Play:keypressed(key)
    if key == "escape" or key == "p" then
        StateManager.switch("pause", {
            player = player, room = currentRoom,
            timeSurvived = timeSurvived })
        return
    end
    if key == "lshift" or key == "space" or key == "x" then
        player:tryDash()
    end
end

function Play:draw()
    local A  = Assets
    local ox, oy = 0, 0
    if screenShake then ox, oy = screenShake.ox, screenShake.oy end

    love.graphics.push()
    love.graphics.translate(ox, oy)

    
    local bg   = A.img.background
    local bw, bh = bg:getDimensions()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bg, 0, 48, 0, S.WIDTH/bw, (S.HEIGHT-48)/bh)

   
    currentRoom:draw(globalTimer)

    
    player:draw()
    love.graphics.pop()
    HUD.draw(player, currentRoom, timeSurvived, message, msgTimer)
    if evacActive then
        local pulse = 0.5 + 0.5 * math.sin(globalTimer * 6)
        love.graphics.setColor(1, 0.1, 0.05, 0.10 * pulse)
        love.graphics.rectangle("fill", 0, 48, S.WIDTH, S.HEIGHT-48)

        love.graphics.setFont(A.fonts.medium)
        local evt  = math.ceil(evacTimer)
        local etxt = string.format("EVACUATION  T-%02d", evt)
        love.graphics.setColor(1, 0.4 + 0.6*pulse, 0.1, 0.95)
        love.graphics.print(etxt,
            S.WIDTH/2 - A.fonts.medium:getWidth(etxt)/2,
            S.HEIGHT - 36)
    end

    
    if transFlash > 0 then
        love.graphics.setColor(0.8, 0.95, 1.0, transFlash * 0.6)
        love.graphics.rectangle("fill", 0, 0, S.WIDTH, S.HEIGHT)
    end

    love.graphics.setColor(1, 1, 1)
end

return Play
