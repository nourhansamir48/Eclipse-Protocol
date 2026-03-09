local Enemy = {}
Enemy.__index = Enemy

local S = require("src.settings")

local ST = { IDLE="idle", PATROL="patrol", CHASE="chase", RETURN="return" }

function Enemy.new(kind, x, y, difficulty)
    local self = setmetatable({}, Enemy)

    self.kind  = kind
    self.x     = x
    self.y     = y
    self.alive = true
    self.hitCooldown = 0

    local diff = difficulty or 0

    if kind == "patrol" then
        local cfg      = S.PATROL
        self.w         = cfg.WIDTH
        self.h         = cfg.HEIGHT
        self.damage    = cfg.DAMAGE
        self.state     = ST.PATROL
        self.speed     = cfg.SPEED * (1 + diff * S.DIFF.SPEED_FACTOR)
        self.axis      = (love.math.random(2)==1) and "h" or "v"
        self.patrolDist= cfg.PATROL_DIST
        self.originX   = x
        self.originY   = y
        self.dir       = 1
        self.facing    = "right"   -- for sprite selection

    elseif kind == "hunter" then
        local cfg      = S.HUNTER
        self.w         = cfg.WIDTH
        self.h         = cfg.HEIGHT
        self.damage    = cfg.DAMAGE
        self.state     = ST.PATROL
        self.speed     = cfg.BASE_SPEED * (1 + diff * S.DIFF.SPEED_FACTOR)
        self.detectRange = cfg.DETECT_RANGE  + diff * S.DIFF.DETECT_FACTOR
        self.chaseRange  = cfg.CHASE_RANGE   + diff * S.DIFF.DETECT_FACTOR
        self.originX   = x
        self.originY   = y
        self.patrolAngle = love.math.random() * math.pi * 2
        self.patrolTimer = 0
        self.facing    = "down"
        self.vx, self.vy = 0, 0
    end
    if kind == "patrol" then
        self.drawSize = 48
    else
        self.drawSize = 72
    end
    self.pulseTimer = 0

    return self
end

function Enemy:bbox()
    return self.x, self.y, self.x+self.w, self.y+self.h
end
function Enemy:cx() return self.x + self.w/2 end
function Enemy:cy() return self.y + self.h/2 end

function Enemy:distToPlayer(player)
    local dx = player:cx() - self:cx()
    local dy = player:cy() - self:cy()
    return math.sqrt(dx*dx + dy*dy), dx, dy
end

function Enemy:update(dt, player, room)
    if not self.alive then return end
    if self.hitCooldown > 0 then self.hitCooldown = self.hitCooldown - dt end
    self.pulseTimer = self.pulseTimer + dt

    if self.kind == "patrol" then
        self:updatePatrol(dt, player, room)
    else
        self:updateHunter(dt, player, room)
    end
end

function Enemy:updatePatrol(dt, player, room)
    local spd = self.speed

    if self.axis == "h" then
        self.x = self.x + self.dir * spd * dt
        local dist = self.x - self.originX
        if     dist >  self.patrolDist then self.dir = -1
        elseif dist < -self.patrolDist then self.dir =  1
        end
        self.facing = (self.dir > 0) and "right" or "left"
    else
        self.y = self.y + self.dir * spd * dt
        local dist = self.y - self.originY
        if     dist >  self.patrolDist then self.dir = -1
        elseif dist < -self.patrolDist then self.dir =  1
        end
        self.facing = (self.dir > 0) and "down" or "up"
    end

    if room then self:clampToRoom(room) end
    self:checkContactDamage(player)
end

function Enemy:updateHunter(dt, player, room)
    local dist, dx, dy = self:distToPlayer(player)

    if self.state == ST.IDLE or self.state == ST.PATROL then
        if dist < self.detectRange then
            self.state = ST.CHASE
        else
            self:doWander(dt, room)
        end

    elseif self.state == ST.CHASE then
        if dist > self.chaseRange then
            self.state = ST.RETURN
        else
            if dist > 2 then
                self.vx = (dx/dist) * self.speed
                self.vy = (dy/dist) * self.speed
                
                if math.abs(dx) > math.abs(dy) then
                    self.facing = (dx > 0) and "right" or "left"
                else
                    self.facing = (dy > 0) and "down" or "up"
                end
            else
                self.vx, self.vy = 0, 0
            end
            self.x = self.x + self.vx * dt
            self.y = self.y + self.vy * dt
            if room then self:clampToRoom(room) end
            self:checkContactDamage(player)
        end

    elseif self.state == ST.RETURN then
        local rdx = self.originX - self.x
        local rdy = self.originY - self.y
        local rlen = math.sqrt(rdx*rdx + rdy*rdy)
        if rlen < 4 then
            self.state = ST.PATROL
            self.x, self.y = self.originX, self.originY
        else
            local spd = self.speed * 0.6
            self.x = self.x + (rdx/rlen) * spd * dt
            self.y = self.y + (rdy/rlen) * spd * dt
        end
        if dist < self.detectRange then self.state = ST.CHASE end
    end
end

function Enemy:doWander(dt, room)
    self.patrolTimer = self.patrolTimer + dt
    if self.patrolTimer > love.math.random() * 2 + 1 then
        self.patrolTimer  = 0
        self.patrolAngle  = love.math.random() * math.pi * 2
    end
    local spd = self.speed * 0.35
    self.x = self.x + math.cos(self.patrolAngle) * spd * dt
    self.y = self.y + math.sin(self.patrolAngle) * spd * dt

    local odx = self.x - self.originX
    local ody = self.y - self.originY
    if math.sqrt(odx*odx + ody*ody) > 80 then
        self.patrolAngle = math.atan2(-ody, -odx)
    end
    if room then self:clampToRoom(room) end
end

function Enemy:checkContactDamage(player)
    if self.hitCooldown > 0 then return end
    local ax1,ay1,ax2,ay2 = self:bbox()
    local bx1,by1,bx2,by2 = player:bbox()
    if ax1<bx2 and ax2>bx1 and ay1<by2 and ay2>by1 then
        player:takeDamage(self.damage, self:cx(), self:cy())
        self.hitCooldown = 0.8
    end
end

function Enemy:clampToRoom(room)
    local T  = S.ROOM.TILE
    local x1 = T*2
    local y1 = T*2 + 48
    local x2 = S.WIDTH  - T*2 - self.w
    local y2 = S.HEIGHT - T*2 - self.h
    self.x = math.max(x1, math.min(self.x, x2))
    self.y = math.max(y1, math.min(self.y, y2))
end

function Enemy:draw()
    if not self.alive then return end
    local A = Assets

    
    local img
    if self.kind == "patrol" then
        if     self.facing == "down"  then img = A.img.enemyDown
        elseif self.facing == "up"    then img = A.img.enemyUp
        elseif self.facing == "left"  then img = A.img.enemyLeft
        else                               img = A.img.enemyRight
        end
    else
        
        img = A.img.hunterBoss
    end

    
    local iw, ih = img:getDimensions()
    local sx = self.drawSize / iw
    local sy = self.drawSize / ih

    
    if self.kind == "hunter" and self.state == ST.CHASE then
        local p = 0.8 + 0.2 * math.sin(self.pulseTimer * 8)
        love.graphics.setColor(1.0, p*0.6, p*0.6)
    else
        love.graphics.setColor(1, 1, 1)
    end

    
    local ox = self.x + self.w/2 - (iw*sx)/2
    local oy = self.y + self.h/2 - (ih*sy)/2
    love.graphics.draw(img, ox, oy, 0, sx, sy)

    
    if self.kind == "hunter" and self.state ~= ST.CHASE then
        love.graphics.setColor(1, 0.2, 0.2, 0.06)
        love.graphics.circle("fill", self:cx(), self:cy(), self.detectRange)
        love.graphics.setColor(1, 0.2, 0.2, 0.20)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", self:cx(), self:cy(), self.detectRange)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Enemy
