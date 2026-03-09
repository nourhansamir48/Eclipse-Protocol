local Room = {}
Room.__index = Room

local S      = require("src.settings")
local Enemy  = require("src.enemy")

local T   = S.ROOM.TILE
local HUD = 48

local function tileToPixel(col, row)
    return col * T, row * T + HUD
end

local function overlap(ax1,ay1,ax2,ay2, bx1,by1,bx2,by2)
    return ax1<bx2 and ax2>bx1 and ay1<by2 and ay2>by1
end

function Room.generate(roomIndex)
    math.randomseed(os.time() + roomIndex * 9973)
    local r = setmetatable({}, Room)

    r.index      = roomIndex
    r.difficulty = roomIndex - 1
    r.cleared    = false

    local COLS, ROWS = S.ROOM.COLS, S.ROOM.ROWS
    r.cols, r.rows   = COLS, ROWS

    local grid = {}
    for row = 0, ROWS-1 do
        grid[row] = {}
        for col = 0, COLS-1 do
            if row==0 or row==ROWS-1 or col==0 or col==COLS-1 then
                grid[row][col] = 1
            else
                grid[row][col] = 0
            end
        end
    end

    for _ = 1, love.math.random(4, 10) do
        local pc = love.math.random(2, COLS-4)
        local pr = love.math.random(2, ROWS-4)
        if not (pc <= 4 and pr <= 4) then
            grid[pr][pc]   = 2; grid[pr][pc+1]   = 2
            grid[pr+1][pc] = 2; grid[pr+1][pc+1] = 2
        end
    end
    r.grid = grid

    local doorRow = love.math.random(ROWS/3, 2*ROWS/3)
    grid[doorRow][COLS-1] = 0

    r.walls = {}
    for row = 0, ROWS-1 do
        for col = 0, COLS-1 do
            if grid[row][col] >= 1 then
                local px, py = tileToPixel(col, row)
                r.walls[#r.walls+1] = { x=px, y=py, w=T, h=T,
                    kind=(grid[row][col]==1) and "wall" or "obstacle" }
            end
        end
    end

    local dx, dy = tileToPixel(COLS-1, doorRow)
    r.door = { x=dx, y=dy, w=T, h=T, locked=true, col=COLS-1, row=doorRow }

    r.nodes = {}
    for _ = 1, love.math.random(S.ROOM.NODES_PER_ROOM[1], S.ROOM.NODES_PER_ROOM[2]) do
        local nc, nr = Room._freeCell(grid, COLS, ROWS)
        local npx, npy = tileToPixel(nc, nr)
        r.nodes[#r.nodes+1] = {
            x=npx+T/2-S.POWER_NODE.WIDTH/2,
            y=npy+T/2-S.POWER_NODE.HEIGHT/2,
            w=S.POWER_NODE.WIDTH, h=S.POWER_NODE.HEIGHT,
            repaired=false, repairProgress=0, pulseTimer=0
        }
    end

    r.cells = {}
    for _ = 1, love.math.random(S.ROOM.CELLS_PER_ROOM[1], S.ROOM.CELLS_PER_ROOM[2]) do
        local cc, cr = Room._freeCell(grid, COLS, ROWS)
        local cpx, cpy = tileToPixel(cc, cr)
        local cellW, cellH = 28, 28
        r.cells[#r.cells+1] = {
            x=cpx+T/2-cellW/2, y=cpy+T/2-cellH/2,
            w=cellW, h=cellH,
            collected=false,
            bobTimer=love.math.random()*math.pi*2
        }
    end

    r.enemies = {}
    local diff  = r.difficulty
    local total = math.min(S.DIFF.SPAWN_BASE + diff, 8)
    local nP    = math.ceil(total * 0.5)
    local nH    = total - nP

    for _ = 1, nP do
        local ec, er = Room._freeCell(grid, COLS, ROWS)
        local epx, epy = tileToPixel(ec, er)
        r.enemies[#r.enemies+1] = Enemy.new("patrol", epx, epy+HUD, diff)
    end
    for _ = 1, nH do
        local ec, er = Room._freeCell(grid, COLS, ROWS)
        local epx, epy = tileToPixel(ec, er)
        r.enemies[#r.enemies+1] = Enemy.new("hunter", epx, epy+HUD, diff)
    end

    r.playerSpawnX = T*2
    r.playerSpawnY = T*2 + HUD
    return r
end

function Room._freeCell(grid, COLS, ROWS)
    for _ = 1, 200 do
        local c = love.math.random(2, COLS-3)
        local r = love.math.random(2, ROWS-3)
        if grid[r] and grid[r][c] == 0 then return c, r end
    end
    return 3, 3
end

function Room:update(dt, player)
    for _, cell in ipairs(self.cells) do
        if not cell.collected then
            cell.bobTimer = cell.bobTimer + dt * 3
        end
    end

    for _, node in ipairs(self.nodes) do
        if not node.repaired then
            node.pulseTimer = node.pulseTimer + dt
            local px1,py1 = player.x, player.y
            local px2,py2 = px1+player.w, py1+player.h
            local nx1,ny1 = node.x, node.y
            local nx2,ny2 = nx1+node.w, ny1+node.h
            local touching = overlap(px1,py1,px2,py2, nx1,ny1,nx2,ny2)
            if touching and player.interacting then
                node.repairProgress = node.repairProgress + dt/S.POWER_NODE.REPAIR_TIME
                if node.repairProgress >= 1 then
                    node.repaired = true
                    player.nodesFixed = player.nodesFixed + 1
                    player.score      = player.score + 50
                    Assets.play("repair")
                end
            else
                node.repairProgress = math.max(0, node.repairProgress - dt*0.5)
            end
        end
    end

    if self.door.locked then
        local all = true
        for _, n in ipairs(self.nodes) do
            if not n.repaired then all=false; break end
        end
        if all then self.door.locked = false end
    end

    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt, player, self)
    end
end

function Room:tryCollectCells(player)
    for _, cell in ipairs(self.cells) do
        if not cell.collected then
            if overlap(player.x, player.y, player.x+player.w, player.y+player.h,
                       cell.x,   cell.y,   cell.x+cell.w,     cell.y+cell.h) then
                cell.collected = true
                player:collectEnergy(S.ENERGY_CELL.VALUE)
            end
        end
    end
end

function Room:checkDoorTrigger(player)
    if self.door.locked then return false end
    local d = self.door
    return overlap(player.x, player.y, player.x+player.w, player.y+player.h,
                   d.x, d.y, d.x+d.w, d.y+d.h)
end

function Room:draw(globalTimer)
    local C   = S.COLOR
    local A   = Assets

    love.graphics.setColor(0.08, 0.09, 0.12, 0.85)
    love.graphics.rectangle("fill", T, T+HUD, (self.cols-2)*T, (self.rows-2)*T)

    for row = 0, self.rows-1 do
        for col = 0, self.cols-1 do
            local tile = self.grid[row][col]
            local px, py = col*T, row*T+HUD
            if tile == 1 then
                love.graphics.setColor(0.18, 0.22, 0.30)
                love.graphics.rectangle("fill", px, py, T, T)
                love.graphics.setColor(0.30, 0.34, 0.44)
                love.graphics.setLineWidth(0.5)
                love.graphics.rectangle("line", px, py, T, T)
            elseif tile == 2 then
                love.graphics.setColor(0.14, 0.17, 0.24)
                love.graphics.rectangle("fill", px, py, T, T)
                love.graphics.setColor(0.28, 0.30, 0.40)
                love.graphics.setLineWidth(0.5)
                love.graphics.rectangle("line", px, py, T, T)
            end
        end
    end

    local d = self.door
    local dp = 0.7 + 0.3*math.sin(globalTimer*4)
    if d.locked then
        love.graphics.setColor(0.65, 0.25, 0.10, 0.9)
    else
        love.graphics.setColor(0.20*dp, 0.90*dp, 0.50*dp, 0.95)
    end
    love.graphics.rectangle("fill", d.x, d.y, d.w, d.h)
    love.graphics.setColor(1,1,1,0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", d.x, d.y, d.w, d.h)
    love.graphics.setFont(A.fonts.small)
    local lbl = d.locked and "LOCK" or "EXIT"
    local lw  = A.fonts.small:getWidth(lbl)
    love.graphics.setColor(1,1,1,0.9)
    love.graphics.print(lbl, d.x+d.w/2-lw/2, d.y+d.h/2-6)

    for _, node in ipairs(self.nodes) do
        if not node.repaired then
            local p = 0.6 + 0.4*math.sin(node.pulseTimer*3)
            love.graphics.setColor(C.NODE[1]*p, C.NODE[2]*p, C.NODE[3]*p)
            love.graphics.rectangle("fill", node.x, node.y, node.w, node.h, 3,3)
            if node.repairProgress > 0 then
                love.graphics.setColor(0.2, 0.9, 0.3)
                love.graphics.rectangle("fill",
                    node.x, node.y+node.h+2,
                    node.w*node.repairProgress, 4)
            end
            love.graphics.setColor(1,1,0,0.75)
            love.graphics.setFont(A.fonts.small)
            love.graphics.print("[E]", node.x-2, node.y-14)
        else
            love.graphics.setColor(0.3, 1.0, 0.5, 0.6)
            love.graphics.rectangle("fill", node.x, node.y, node.w, node.h, 3,3)
        end
    end

    local cellImg = A.img.cell
    local ciw, cih = cellImg:getDimensions()
    for _, cell in ipairs(self.cells) do
        if not cell.collected then
            local bob   = math.sin(cell.bobTimer) * 2
            local pulse = 0.8 + 0.2*math.sin(cell.bobTimer*2)
            local sx    = cell.w / ciw
            local sy    = cell.h / cih
            love.graphics.setColor(1, pulse, pulse)
            love.graphics.draw(cellImg, cell.x, cell.y+bob, 0, sx, sy)
        end
    end

    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Room