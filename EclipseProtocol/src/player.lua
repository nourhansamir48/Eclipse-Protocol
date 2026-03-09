local Player = {}
Player.__index = Player

local S = require("src.settings")
local P = S.PLAYER

function Player.new(x, y)
    local A    = Assets
    local self = setmetatable({}, Player)

    self.x, self.y  = x or 100, y or 100
    self.vx, self.vy = 0, 0
    self.w  = P.COLLISION_W
    self.h  = P.COLLISION_H

    self.health     = P.MAX_HEALTH
    self.maxHealth  = P.MAX_HEALTH
    self.energy     = P.MAX_ENERGY
    self.maxEnergy  = P.MAX_ENERGY
    self.score      = 0
    self.nodesFixed = 0

    self.dashing      = false
    self.dashTimer    = 0
    self.dashCooldown = 0
    self.dashDirX     = 0
    self.dashDirY     = 0

    self.invulnTimer  = 0
    self.flickerTimer = 0
    self.visible      = true

    self.kbVx, self.kbVy = 0, 0

    self.interacting   = false
    self.interactTimer = 0

    self.facing = "down"
    self.moving = false

    self.anims = {
        down  = A.anim.walkDown:clone(),
        left  = A.anim.walkLeft:clone(),
        right = A.anim.walkRight:clone(),
        up    = A.anim.walkUp:clone(),
        dash  = A.anim.dash:clone(),
        idle  = A.anim.idle:clone(),
    }
    self.currentAnim = self.anims.idle

    self.drawW = 40
    self.drawH = 60
    self.scaleX = self.drawW / A.robotFW
    self.scaleY = self.drawH / A.robotFH

    self.alive = true
    return self
end

function Player:bbox()
    return self.x, self.y, self.x + self.w, self.y + self.h
end
function Player:cx() return self.x + self.w / 2 end
function Player:cy() return self.y + self.h / 2 end

function Player:getInput()
    local dx, dy = 0, 0
    if love.keyboard.isDown("a","left")  then dx = dx - 1 end
    if love.keyboard.isDown("d","right") then dx = dx + 1 end
    if love.keyboard.isDown("w","up")    then dy = dy - 1 end
    if love.keyboard.isDown("s","down")  then dy = dy + 1 end
    if dx ~= 0 and dy ~= 0 then
        local l = math.sqrt(dx*dx + dy*dy)
        dx, dy = dx/l, dy/l
    end
    return dx, dy
end

function Player:update(dt, room)
    if not self.alive then return end

    if self.invulnTimer  > 0 then self.invulnTimer  = self.invulnTimer  - dt end
    if self.dashCooldown > 0 then self.dashCooldown = self.dashCooldown - dt end

    if self.invulnTimer > 0 then
        self.flickerTimer = self.flickerTimer + dt
        self.visible = math.floor(self.flickerTimer / 0.08) % 2 == 0
    else
        self.visible = true
        self.flickerTimer = 0
    end

    self.energy = math.min(self.maxEnergy, self.energy + P.ENERGY_REGEN * dt)

    if self.dashing then
        self.dashTimer = self.dashTimer - dt
        if self.dashTimer <= 0 then
            self.dashing = false
            self.vx, self.vy = 0, 0
        else
            self.vx = self.dashDirX * P.DASH_SPEED
            self.vy = self.dashDirY * P.DASH_SPEED
        end
    else
        local dx, dy = self:getInput()
        self.vx, self.vy = dx * P.SPEED, dy * P.SPEED
        self.moving = (dx ~= 0 or dy ~= 0)

        if     dx > 0  then self.facing = "right"
        elseif dx < 0  then self.facing = "left"
        elseif dy < 0  then self.facing = "up"
        elseif dy > 0  then self.facing = "down"
        end

        self.interacting = love.keyboard.isDown("e","f")
    end

    local decay = 8
    self.kbVx = self.kbVx * math.max(0, 1 - decay*dt)
    self.kbVy = self.kbVy * math.max(0, 1 - decay*dt)

    self.vx = self.vx + self.kbVx
    self.vy = self.vy + self.kbVy

    self:moveAndResolve(dt, room)

    if self.moving and not self.dashing then
        Assets.startFootsteps()
    else
        Assets.stopFootsteps()
    end

    self:updateAnim(dt)
end

function Player:updateAnim(dt)
    local nextAnim
    if self.dashing then
        nextAnim = self.anims.dash
    elseif self.moving then
        if     self.facing == "down"  then nextAnim = self.anims.down
        elseif self.facing == "up"    then nextAnim = self.anims.up
        elseif self.facing == "left"  then nextAnim = self.anims.left
        elseif self.facing == "right" then nextAnim = self.anims.right
        end
    else
        nextAnim = self.anims.idle
    end
    if nextAnim ~= self.currentAnim then
        self.currentAnim = nextAnim
        nextAnim:gotoFrame(1)
    end
    self.currentAnim:update(dt)
end

function Player:moveAndResolve(dt, room)
    local nx = self.x + self.vx * dt
    local ny = self.y + self.vy * dt
    local W  = S.WIDTH
    local H  = S.HEIGHT

    nx = math.max(0, math.min(nx, W - self.w))
    ny = math.max(48, math.min(ny, H - self.h))

    if room and room.walls then
        nx, ny = self:resolveWalls(nx, self.y, ny, room.walls)
    end
    self.x, self.y = nx, ny
end

function Player:resolveWalls(nx, oy, ny, walls)
    for _, wall in ipairs(walls) do
        local cx1,cy1,cx2,cy2 = nx, oy, nx+self.w, oy+self.h
        if cx1<wall.x+wall.w and cx2>wall.x and cy1<wall.y+wall.h and cy2>wall.y then
            local oL = cx2 - wall.x
            local oR = wall.x + wall.w - cx1
            if oL < oR then nx = nx - oL else nx = nx + oR end
            self.vx = 0
        end
    end
    for _, wall in ipairs(walls) do
        local cx1,cy1,cx2,cy2 = nx, ny, nx+self.w, ny+self.h
        if cx1<wall.x+wall.w and cx2>wall.x and cy1<wall.y+wall.h and cy2>wall.y then
            local oT = cy2 - wall.y
            local oB = wall.y + wall.h - cy1
            if oT < oB then ny = ny - oT else ny = ny + oB end
            self.vy = 0
        end
    end
    return nx, ny
end

function Player:tryDash()
    if self.dashing or self.dashCooldown > 0 then return end
    if self.energy < P.DASH_COST then return end

    local dx, dy = self:getInput()
    if dx == 0 and dy == 0 then
        if     self.facing == "right" then dx =  1
        elseif self.facing == "left"  then dx = -1
        elseif self.facing == "up"    then dy = -1
        else                               dy =  1
        end
    end

    self.dashing      = true
    self.dashTimer    = P.DASH_DURATION
    self.dashCooldown = P.DASH_COOLDOWN
    self.dashDirX     = dx
    self.dashDirY     = dy
    self.energy       = self.energy - P.DASH_COST
    Assets.play("dash")
end

function Player:takeDamage(amount, srcX, srcY)
    if self.invulnTimer > 0 or self.dashing then return end
    self.health = math.max(0, self.health - amount)
    self.invulnTimer  = P.INVULN_TIME
    self.flickerTimer = 0
    if srcX and srcY then
        local dx = self.x - srcX
        local dy = self.y - srcY
        local l  = math.sqrt(dx*dx + dy*dy)
        if l > 0 then
            self.kbVx = (dx/l) * P.KNOCKBACK
            self.kbVy = (dy/l) * P.KNOCKBACK
        end
    end
    Assets.play("hurt")
    if self.health <= 0 then self.alive = false end
end

function Player:collectEnergy(amount)
    self.energy = math.min(self.maxEnergy, self.energy + amount)
    self.score  = self.score + 10
    Assets.play("collect")
end

function Player:draw()
    if not self.visible then return end
    local A  = Assets
    local sx = self.scaleX
    local sy = self.scaleY

    if self.dashing then
        love.graphics.setColor(0.7, 0.9, 1.0)
    elseif self.invulnTimer > 0 then
        love.graphics.setColor(1.0, 0.5, 0.5)
    else
        love.graphics.setColor(1, 1, 1)
    end

    local ox = self.x + self.w/2 - (A.robotFW * sx)/2
    local oy = self.y + self.h/2 - (A.robotFH * sy)/2
    self.currentAnim:draw(A.img.robot, ox, oy, 0, sx, sy)

    if self.dashCooldown > 0 then
        local pct = 1 - self.dashCooldown / P.DASH_COOLDOWN
        love.graphics.setColor(0.3, 0.8, 1.0, 0.7)
        love.graphics.arc("fill", self:cx(), self.y - 6, 4,
            -math.pi/2, -math.pi/2 + pct * math.pi*2)
    end

    love.graphics.setColor(1, 1, 1)
end


function aabbOverlap(ax1,ay1,ax2,ay2, bx1,by1,bx2,by2)
    return ax1<bx2 and ax2>bx1 and ay1<by2 and ay2>by1
end

return Player