local anim8 = {}
anim8.__index = anim8

local _M = {}

-- Grid class
local Grid = {}
Grid.__index = Grid

function _M.newGrid(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border)
  left   = left   or 0
  top    = top    or 0
  border = border or 0
  local g = setmetatable({
    frameWidth   = frameWidth,
    frameHeight  = frameHeight,
    imageWidth   = imageWidth,
    imageHeight  = imageHeight,
    left         = left,
    top          = top,
    border       = border,
    _quads       = {},
    _width       = math.floor((imageWidth  - left) / (frameWidth  + border)),
    _height      = math.floor((imageHeight - top)  / (frameHeight + border)),
  }, Grid)
  return g
end

function Grid:_createQuad(x, y)
  local iw, ih = self.imageWidth, self.imageHeight
  local fw, fh = self.frameWidth, self.frameHeight
  local l, t, b = self.left, self.top, self.border
  return love.graphics.newQuad(
    l + (x-1)*(fw+b), t + (y-1)*(fh+b), fw, fh, iw, ih)
end

function Grid:getFrames(...)
  local frames = {}
  local args   = {...}
  local function parseInterval(str, max)
    local t = {}
    for part in str:gmatch('[^,]+') do
      local a, b2 = part:match('^(%d+)-(%d+)$')
      if a then
        local step = (tonumber(b2) >= tonumber(a)) and 1 or -1
        for i = tonumber(a), tonumber(b2), step do t[#t+1] = i end
      else
        t[#t+1] = tonumber(part)
      end
    end
    return t
  end
  for i = 1, #args, 2 do
    local xs = parseInterval(tostring(args[i]),   self._width)
    local ys = parseInterval(tostring(args[i+1]), self._height)
    for _, y in ipairs(ys) do
      for _, x in ipairs(xs) do
        local key = x .. '-' .. y
        if not self._quads[key] then
          self._quads[key] = self:_createQuad(x, y)
        end
        frames[#frames+1] = self._quads[key]
      end
    end
  end
  return frames
end

setmetatable(Grid, {__call = function(g, ...) return g:getFrames(...) end})

-- Animation class
local Animation = {}
Animation.__index = Animation

function _M.newAnimation(frames, durations, onLoop)
  local a = setmetatable({
    frames      = frames,
    durations   = {},
    totalDuration = 0,
    intervals   = {},
    timer       = 0,
    current     = 1,
    status      = 'playing',
    direction   = 1,
    onLoop      = onLoop or 'loop',
    _flippedH   = false,
    _flippedV   = false,
    _rotation   = 0,
  }, Animation)

  if type(durations) == 'number' then
    for i = 1, #frames do a.durations[i] = durations end
  else
    for i, d in ipairs(durations) do a.durations[i] = d end
  end

  a.totalDuration = 0
  for _, d in ipairs(a.durations) do a.totalDuration = a.totalDuration + d end

  -- Build cumulative intervals
  local t = 0
  for i, d in ipairs(a.durations) do
    t = t + d
    a.intervals[i] = t
  end

  return a
end

function Animation:update(dt)
  if self.status ~= 'playing' then return end
  self.timer = self.timer + dt
  while self.timer >= self.totalDuration do
    self.timer = self.timer - self.totalDuration
    if self.onLoop == 'pauseAtEnd' then
      self.timer  = self.totalDuration
      self.current = #self.frames
      self.status  = 'paused'
      return
    elseif type(self.onLoop) == 'function' then
      self.onLoop(self)
    end
  end
  -- Find current frame
  for i, t in ipairs(self.intervals) do
    if self.timer < t then
      self.current = i
      return
    end
  end
  self.current = #self.frames
end

function Animation:draw(image, x, y, r, sx, sy, ox, oy)
  r  = r  or 0
  sx = sx or 1
  sy = sy or 1
  ox = ox or 0
  oy = oy or 0
  if self._flippedH then sx = -sx end
  if self._flippedV then sy = -sy end
  love.graphics.draw(image, self.frames[self.current], x, y,
    r + self._rotation, sx, sy, ox, oy)
end

function Animation:gotoFrame(f)
  self.current = ((f - 1) % #self.frames) + 1
  -- Sync timer to start of that frame
  self.timer = (self.intervals[self.current - 1] or 0)
end

function Animation:pause()  self.status = 'paused'  end
function Animation:resume() self.status = 'playing' end

function Animation:clone()
  local c = _M.newAnimation(self.frames, self.durations, self.onLoop)
  c.timer   = self.timer
  c.current = self.current
  c.status  = self.status
  return c
end

function Animation:flipH() self._flippedH = not self._flippedH end
function Animation:flipV() self._flippedV = not self._flippedV end

return _M
