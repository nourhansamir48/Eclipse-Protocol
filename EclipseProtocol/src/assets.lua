local Assets = {}

local S     = require("src.settings")
local anim8 = require("anim8")

function Assets.load()

    Assets.fonts = {
        small  = love.graphics.newFont(11),
        medium = love.graphics.newFont(14),
        large  = love.graphics.newFont(22),
        title  = love.graphics.newFont(38),
        hud    = love.graphics.newFont(12),
    }

    Assets.img = {}
    Assets.img.background = love.graphics.newImage("assets/ui/background.png")
    Assets.img.startMenu  = love.graphics.newImage("assets/ui/start menu.png")
    Assets.img.gameOver   = love.graphics.newImage("assets/ui/Game Over.png")
    Assets.img.cell       = love.graphics.newImage("assets/ui/Cell.png")

    Assets.img.robot      = love.graphics.newImage("assets/sprites/player/robot.png")
    local rw, rh          = Assets.img.robot:getDimensions()
    local rFW, rFH        = rw / 4, rh / 4

    local rGrid = anim8.newGrid(rFW, rFH, rw, rh)
    Assets.anim = {}
    Assets.anim.walkDown  = anim8.newAnimation(rGrid:getFrames("1-4", 1), 0.12)
    Assets.anim.walkLeft  = anim8.newAnimation(rGrid:getFrames("1-4", 2), 0.12)
    Assets.anim.walkRight = anim8.newAnimation(rGrid:getFrames("1-4", 3), 0.12)
    Assets.anim.walkUp    = anim8.newAnimation(rGrid:getFrames("1-4", 2), 0.12)
    Assets.anim.dash      = anim8.newAnimation(rGrid:getFrames("1-4", 4), 0.06)
    Assets.anim.idle      = anim8.newAnimation(rGrid:getFrames("1-1", 1), 0.2)

    Assets.robotFW = rFW
    Assets.robotFH = rFH

    Assets.img.enemyDown  = love.graphics.newImage("assets/sprites/enemy/enemy down.png")
    Assets.img.enemyLeft  = love.graphics.newImage("assets/sprites/enemy/enemy left.png")
    Assets.img.enemyRight = love.graphics.newImage("assets/sprites/enemy/enemy right.png")
    Assets.img.enemyUp    = love.graphics.newImage("assets/sprites/enemy/enemy up.png")

    Assets.img.hunterBoss = love.graphics.newImage("assets/sprites/player/Rosh Leh.png")

    Assets.sounds = {}

    local function trySource(path, sourceType)
        local ok, src = pcall(love.audio.newSource, path, sourceType)
        if ok then return src end
        print(("Audio load failed: %s (%s)"):format(path, tostring(src)))
        return nil
    end

    Assets.sounds.footsteps = trySource("assets/sounds/Effects/Footsteps.wav", "static")
    if Assets.sounds.footsteps then
        Assets.sounds.footsteps:setLooping(true)
        Assets.sounds.footsteps:setVolume(0.35)
    end

    Assets.sounds.gameover = trySource("assets/sounds/Effects/Gameover.wav", "static")
    if Assets.sounds.gameover then
        Assets.sounds.gameover:setVolume(0.85)
    end

    Assets.music = trySource("assets/sounds/music/Startgame.mp3", "stream")
    if Assets.music then
        Assets.music:setLooping(true)
        Assets.music:setVolume(0.45)
    end

    local function tone(freq, dur, vol, wave)
        local rate = 44100
        local n    = math.floor(rate * dur)
        local sd   = love.sound.newSoundData(n, rate, 16, 1)
        for i = 0, n-1 do
            local t   = i / rate
            local env = math.max(0, 1 - t/dur)
            local s
            if wave == "sq" then
                s = (math.sin(2*math.pi*freq*t) >= 0) and 1 or -1
            else
                s = math.sin(2*math.pi*freq*t)
            end
            sd:setSample(i, s * (vol or 0.5) * env)
        end
        return love.audio.newSource(sd)
    end

    Assets.sounds.dash    = tone(600,  0.12, 0.4, "sq")
    Assets.sounds.hurt    = tone(150,  0.25, 0.6, "sq")
    Assets.sounds.collect = tone(880,  0.15, 0.4, "sin")
    Assets.sounds.repair  = tone(440,  0.40, 0.5, "sin")
    Assets.sounds.door    = tone(220,  0.30, 0.5, "sin")
    Assets.sounds.victory = tone(660,  1.00, 0.5, "sin")
end

function Assets.startMusic()
    if Assets.music and not Assets.music:isPlaying() then
        Assets.music:play()
    end
end

function Assets.stopMusic()
    if Assets.music then Assets.music:stop() end
end

function Assets.play(name)
    local s = Assets.sounds[name]
    if not s then return end
    if s:isPlaying() then s:stop() end
    s:play()
end

function Assets.startFootsteps()
    local s = Assets.sounds.footsteps
    if s and not s:isPlaying() then s:play() end
end

function Assets.stopFootsteps()
    local s = Assets.sounds.footsteps
    if s and s:isPlaying() then s:stop() end
end

return Assets
