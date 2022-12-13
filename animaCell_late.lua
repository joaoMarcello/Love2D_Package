local Anima = {}
local AnimaStates = { repeating = 1, comesAndGoes = 2, random = 3 }


function Anima:new(img, frames, frameSizeX, frameSizeY, speed, posTextX, posTextY)
    --[[ Create instance of Class Anima.

    ]]
    local a = {}
    setmetatable(a, self)
    self.__index = self

    if type(img) == "string" then a.img = love.graphics.newImage(img)
    else a.img = img end

    a.img:setFilter("linear", "nearest")

    a.frames = frames or 1
    a.frameSize = { x = frameSizeX or a.img:getWidth() / a.frames, y = frameSizeY or a.img:getHeight() }
    a.currentFrame = 1
    a.grid = { x = a.frames, y = 1 }
    a.scale = { x = 1., y = 1. }
    a.direction = 1
    a.time = 0.
    a.bottom = a.frameSize.y
    a.color = { 1, 1, 1, 1 }
    a.quad = love.graphics.newQuad(0, 0, a.frameSize.x, a.frameSize.y, a.img:getDimensions())
    a.angle = 0.
    a.speed = speed or 0.2
    a.origin = { x = a.frameSize.x / 2, y = a.frameSize.y / 2 }
    a.textPos = { x = 0, y = 0 }
    a.flip = { x = 1, y = 1 }
    a.timeUpdate = 0.
    a.timeStopped = 0.
    a.rowCount = 0
    a.state = AnimaStates.repeating
    a.visible = true
    a.enabled = true
    a.kx = 0.
    a.ky = 0.

    a.configTr = { x = 0, y = 0, angle = a.angle, sx = 1., sy = 1., ox = 0, oy = 0, kx = a.kx, ky = a.ky }

    return a
end

function Anima:configure(config)
    self.frames = config.frames or self.frames
    self.frameSize = { x = config.frameSizeX or self.frameSize.x, y = config.frameSizeY or self.frameSize.y }
    self.grid = { x = config.gridX or self.grid.x, y = config.gridY or self.grid.y }
    self.scale = { x = config.scaleX or self.scale.x, y = config.scaleY or self.scale.y }
    self.direction = config.changeDirection and -1 or 1
    self.currentFrame = self.direction < 0 and self.frames or self.currentFrame
    self.bottom = config.bottom or self.frameSize.y
    self.color = config.color or self.color
    self.angle = config.angle or self.angle
    self.speed = config.speed or self.speed
    self.textPos = { x = config.originX or self.textPos.x, y = config.originY or self.textPos.y }
    self.origin = { x = config.centerX or self.origin.x, y = config.centerY or self.origin.y }
    self.flip = { x = config.flipX and -1 or 1, y = config.flipY and -1 or 1 }
    self.stopAtTheEnd = config.stop
    self.state = config.state == "random" and AnimaStates.random or
        (config.state == "comesAndGoes" and AnimaStates.comesAndGoes or AnimaStates.repeating)
    self.initialDirection = nil
    self.maxRows = config.rows
    self.kx = config.kx or self.kx
    self.ky = config.ky or self.ky

    self.configTr = { x = 0, y = 0, angle = self.angle, sx = 1., sy = 1., ox = 0, oy = 0, kx = self.kx, ky = self.ky }
end

--

function Anima:catch()
    if not self.c then self.c = {} end
    self.c.scale = { x = self.scale.x, y = self.scale.y }
    self.c.color = self.color
    self.c.direction = self.direction
    self.c.angle = self.angle
    self.c.speed = self.speed
    self.c.flip = { x = self.flip.x, y = self.flip.y }
    self.c.kx = self.kx
    self.c.ky = self.ky
    self.c.currentFrame = self.currentFrame
end

--

function Anima:pop()
    if not self.c then return end
    self.scale = { x = self.c.scale.x, y = self.c.scale.y }
    self.color = { self.c.color[1], self.c.color[2], self.c.color[3], self.c.color[4] or 1 }
    self.direction = self.c.direction
    self.angle = self.c.angle
    self.speed = self.c.speed
    self.flip = { x = self.c.flip.x, y = self.c.flip.y }
    self.kx = self.c.kx
    self.ky = self.c.ky
    self.currentFrame = self.c.currentFrame
    self.c = nil
end

--

function Anima:setTransform(x, y, angle, sx, sy, ox, oy, kx, ky)
    if not self.transform then
        self.transform = love.math.newTransform()
    end

    self.transform:setTransformation(x or self.configTr.x, y or self.configTr.y, angle or self.configTr.angle,
        sx or self.configTr.sx, sy or self.configTr.sy, ox or self.configTr.ox, oy or self.configTr.oy,
        kx or self.configTr.kx, ky or self.configTr.ky)
end

--

function Anima:eraseTransform()
    self.transform = nil
end

function Anima:setCenter(x, y)
    self.origin.x = x or self.origin.x
    self.origin.y = y or self.origin.y
end

--

function Anima:reset()
    self.time = 0.
    self.timeUpdate = 0.
    self.currentFrame = self.direction > 0 and 1 or self.frames
    self.timeUpdate = 0.
    self.timeStopped = 0.
    self.rowCount = 0
    self.initialDirection = nil
    self.stopped = nil
    self.visible = true
    self.enabled = true
end

--

function Anima:update(dt)
    self.timeUpdate = (self.timeUpdate + dt) % 500000.
    if not self.enabled then return end

    -- getting the Animation's initial direction
    if not self.initialDirection then self.initialDirection = self.direction end

    -- updating the effects applied to this Animation, if the effect list isn't empty
    if self.effects then
        for i = #self.effects, 1, -1 do
            local r = self.effects[i].enabled and self.effects[i]:update(dt)

            if self.effects[i].remove then
                if self.effects[i].endAction then self.effects[i].endAction(self.effects[i].endActionArgs) end

                -- if after effect's end action the Animation's effect list is empty, then exit loop
                if self.effectsClear then self.effectsClear = nil; break end

                local r = self.effects[i].remove and table.remove(self.effects, i)
            end
        end

        -- if any effect was added in Aniamtion's effects list, then sort the effect list by prior order
        if self.sort then table.sort(self.effects, function(a, b) return a.prior > b.prior end); self.sort = nil end
    end


    if self.action then
        self.action(self.actionArgs)
    end

    -- increasing time stopped if Animation is stopped
    if self.stopped or (self.maxRows and self.rowCount >= self.maxRows) then
        self.timeStopped = (self.timeStopped + dt) % 5000000.
        return
    end

    self.time = self.time + dt

    -- if time is greater than the specified speed, it's time to update the current frame
    if self.time >= self.speed then
        self.time = self.time - self.speed

        if self.state == AnimaStates.random then
            local lastFrame = self.currentFrame
            math.random();
            math.random();
            math.random()
            self.currentFrame = 1 + (math.random(0, self.frames) % (self.frames));
            self.rowCount = (self.rowCount + 1) % (600000)
            if lastFrame == self.currentFrame then self.currentFrame = 1 + (self.currentFrame) % (self.frames) end
            return
        end

        self.currentFrame = self.currentFrame + 1 * self.direction

        if self.direction > 0 then
            if self.currentFrame > self.frames then
                if self.state == AnimaStates.repeating then
                    self.currentFrame = 1;
                    self.rowCount = (self.rowCount + 1) % (600000)
                    if self.stopAtTheEnd then self.stopped = true;
                        self.currentFrame = self.frames
                    end
                else
                    self.currentFrame = self.frames;
                    self.time = self.time + self.speed;
                    self.direction = -self.direction;

                    if self.direction == self.initialDirection then self.rowCount = (self.rowCount + 1) % (600000) end
                    if self.stopAtTheEnd and self.direction == self.initialDirection then self.stopped = true end
                end
            end
        else
            if self.currentFrame < 1 then
                if self.state == AnimaStates.repeating then
                    self.currentFrame = self.frames;
                    self.rowCount = (self.rowCount + 1) % (600000)

                    if self.stopAtTheEnd then self.stopped = true;
                        self.currentFrame = 1
                    end
                else
                    self.currentFrame = 1;
                    self.time = self.time + self.speed;
                    self.direction = -self.direction;

                    if self.direction == self.initialDirection then self.rowCount = (self.rowCount + 1) % (600000) end
                    if self.stopAtTheEnd and self.direction == self.initialDirection then self.stopped = true end
                end
            end
        end
    end

end

--

function Anima:draw(x, y)
    love.graphics.push()

    self.configTr.x, self.configTr.y = x, y
    self.configTr.ox, self.configTr.oy = x, y

    if self.transform then love.graphics.applyTransform(self.transform) end
    self:drawWithoutEff(x, y)

    love.graphics.pop()

    if self.effects then
        for i = #self.effects, 1, -1 do
            local r = self.effects[i].draw and self.effects[i]:draw(x, y)
        end
    end
end

--

function Anima:drawRec(x, y, w, h)
    x = x + w / 2.0
    y = y + h - self.bottom * self.scale.y + self.origin.y * self.scale.y
    if self.flip.y < 0 then
        y = y - h + self.bottom * self.scale.y
    end

    self:draw(x, y)
end

--

function Anima:drawWithoutEff(x, y)
    self.quad:setViewport(
        self.textPos.x + self.frameSize.x * ((self.currentFrame - 1) % self.grid.x),
        self.textPos.y + self.frameSize.y * math.floor((self.currentFrame - 1) / self.grid.x),
        self.frameSize.x,
        self.frameSize.y)

    love.graphics.setColor(self.color)
    if not self.visible then return end

    love.graphics.draw(self.img, self.quad, math.floor(x), math.floor(y), self.angle, self.scale.x * self.flip.x,
        self.scale.y * self.flip.y, self.origin.x, self.origin.y, self.kx, self.ky)
end

--

function Anima:setScale(x, y)
    self.scale.x = x or self.scale.x
    self.scale.y = y or self.scale.y

    if self.effects then
        for i = 1, #self.effects do self.effects[i].c.scale.x = self.scale.x;
            self.effects[i].c.scale.y = self.scale.y
        end
    end
end

--

function Anima:stopAllEffects()
    if self.effects then
        if #self.effects > 0 then
            self.c = self.effects[1].c
            self.c.flip = self.flip
            self.c.direction = self.direction
            self:pop()
        end
        self.effects = {}
        self.effectsClear = true
        collectgarbage("collect")
        return true
    end
end

--

function Anima:pauseAllEffects()
    if self.effects then
        for i = 1, #self.effects do self.effects[i].enabled = false end
    end
end

--

function Anima:resumeAllEffects()
    if self.effects then
        for i = 1, #self.effects do self.effects[i].enabled = true end
    end
end

--

function Anima:pause() if not self.stopped then self.stopped = true;
        self.timeStopped = 0.;
        return true
    end
end

--
function Anima:unpause() if self.stopped then self.stopped = false; return true end end

--
function Anima:isPaused() return self.stopped end

--
function Anima:stop(time) if self.enabled then self.enabled = false; return true end end

--
function Anima:resume() if not self.enabled then self.enabled = true; return true end end

--
function Anima:isEnabled() return self.enable end

function Anima:setAction(func, args)
    self.action = func
    self.actionArgs = args
end

--

--[[
+----------------------------------------------------------------------------------------------------------+
|                                                                                                          |
|                                    SOME COOL EFFECTS                                                     |
|                                                                                                          |
+----------------------------------------------------------------------------------------------------------+]]

--- Effect
local Effect = {}

function Effect:new(anima)
    local e = {}
    setmetatable(e, self)
    self.__index = self

    e.color = { 1, 1., 1., 1. }
    e.max = 1.1
    e.min = 0.6

    e.range = e.max - e.min
    e.speed = 0.5
    e.state = 1
    e.scale = { x = 1., y = 1. }
    e.rad = 0.0
    e.row = 0
    e.prior = 0
    e.anima = anima
    e.enabled = true

    if anima then
        anima:catch()
        e.c = anima.c
        anima:pop()
    end

    return e
end

--
function Effect:setEndAction(func, args)
    self.endAction = func
    self.endActionArgs = args
end

--

function Effect:reset()
    self.remove = false
    self.row = 0
    self.rad = 0.
    self.c.scale.x = self.anima.scale.x
    self.c.scale.y = self.anima.scale.y

    if self.resetExtend then self:resetExtend() end
end

--

function Effect:inLoop()
    self:setEndAction(function(args) local eff = args:applyEffect(self.id, self.speed, self.range); eff:inLoop(); end,
        self.anima)
end

--

function Effect:stopLoop()
    self.endAction = nil
    self.endActionArgs = nil
end

--

--------------- FLASH -----------------------
local Flash = Effect:new()
function Flash:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "flash"
    e.prior = 1
    e.range = 0.5
    e.alpha = 1.
    e.speed = 1.
    e.color = { 1, 1, 1, 1 }
    return e
end

--
function Flash:update(dt)
    self.rad = (self.rad + math.pi * 2. / self.speed * dt) % (math.pi * 2.)
    self.alpha = 0.5 + (math.math_sin(self.rad) * self.range)
end

--
function Flash:draw(x, y)
    if self.alpha and (self.color[1] == 1 and self.color[2] == 1 and self.color[2] == 1) then
        love.graphics.setBlendMode('add', 'alphamultiply') --'premultiplied'  'alphamultiply'
        self.anima.color = { self.color[1], self.color[2], self.color[3], self.alpha * (self.anima.color[4] or 1.) }
        self.anima:drawWithoutEff(x, y)
        self.anima.color = self.c.color
        love.graphics.setBlendMode("alpha")
    else
        self.anima.color = self.color
        self.anima.color[4] = self.alpha
        self.anima:drawWithoutEff(x, y)
        self.anima.color = self.c.color
    end
end

----------------- PULSE ----------------------------------------------------
local Pulse = Effect:new()

function Pulse:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "pulse"
    e.prior = 1
    e.range = 0.2

    e.speed = 0.5
    e.acc = 0.
    e.adjust = math.pi

    e.row = 0
    return e
end

function Pulse:update(dt)
    if self.maxrow and self.row >= self.maxrow then self.anima.scale.x = self.c.scale.x;
        self.anima.scale.y = self.c.scale.y;
        self.remove = true
        return
    end

    self.speed = self.speed + self.acc / 1.0 * dt

    self.rad = (self.rad + math.pi * 2. / self.speed * dt)

    if self.rad >= (math.pi * 2.) then self.rad = self.rad % (math.pi * 2.);
        self.row = self.row + 1
    end

    if self.difX ~= 0 then
        self.anima.scale.x = self.c.scale.x + (math.math_sin(self.rad) * (self.difX or self.range) * self.c.scale.x)
    end
    if self.difY ~= 0 then
        self.anima.scale.y = self.c.scale.y +
            (math.math_sin(self.rad + self.adjust) * (self.difY or self.range) * self.c.scale.y)
    end
end

--
---------------- POPIN --------------------------------------------------------
local Popin = Effect:new()

function Popin:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "popin"
    e.prior = 3
    e.scale.x = e.anima.scale.x * 0.3
    e.speed = 0.2

    e.min = e.anima.scale.x

    e.range = 0.2
    return e
end

--
function Popin:update(dt)
    if self.state == 1 then
        self.scale.x = self.scale.x + (1 + self.range * 2) / self.speed * dt

        if self.scale.x >= (self.c.scale.x * (1 + self.range)) then self.scale.x = (self.c.scale.x * (1 + self.range));
            self.state = 0
        end
    end

    if self.state == 0 then
        self.scale.x = self.scale.x - (1 + self.range * 2) / self.speed * dt

        if self.scale.x <= self.c.scale.x then
            self.scale.x = 1;
            self.state = -1;
            self.anima.scale.x = self.c.scale.x
            self.anima.scale.y = self.c.scale.y
            self.remove = true
            return
        end
    end

    if self.state >= 0 then
        self.anima.scale.x = self.scale.x
        self.anima.scale.y = self.scale.x

    end
end

---------------------- POPOUT -------------------------------------------
local Popout = Effect:new()

function Popout:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "popout"
    e.anima.visible = true
    e.prior = 3
    e.scale.x = e.anima.scale.x
    e.speed = 0.2

    e.min = e.anima.scale.x * 0.3

    e.range = 0.3
    return e
end

--
function Popout:update(dt)
    if self.state == 1 then
        self.scale.x = self.scale.x + (1 + self.range) / self.speed * dt

        if self.scale.x >= (self.c.scale.x * (1 + self.range)) then self.scale.x = (self.c.scale.x * (1 + self.range));
            self.state = 0
        end
    end

    if self.state == 0 then
        self.scale.x = self.scale.x - (1 + self.range) / self.speed * dt
        if self.scale.x <= self.min then
            self.state = -1;
            self.anima.visible = false

            self.anima.scale.x = self.c.scale.x
            self.anima.scale.y = self.c.scale.y
            self.remove = true
            return
        end
    end

    if self.state >= 0 then
        self.anima.scale.x = self.scale.x
        self.anima.scale.y = self.scale.x

    end
end

------------------- FADEIN ----------------------------------------------
local Fadein = Effect:new()
function Fadein:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "fadein"
    e.min = 0.1
    e.color[4] = e.min
    e.dif = 1.
    e.speed = 0.5
    e.anima.color[4] = 0.0
    return e
end

--
function Fadein:update(dt)
    if self.color[4] < 1 then
        self.color[4] = self.color[4] + self.dif / self.speed * dt
        self.anima.color[4] = self.color[4]
    else
        self.remove = true
        self.anima.color = self.c.color
    end
end

------------------ FADEOUT -----------------------------------------------------
local Fadeout = Effect:new()
function Fadeout:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "fadeout"
    e.min = 0.0
    e.color[4] = 1.
    e.dif = 1.
    e.speed = 0.2
    e.anima.color[4] = 1.
    return e
end

--
function Fadeout:update(dt)
    if self.color[4] > self.min then
        self.color[4] = self.color[4] - self.dif / self.speed * dt
        self.anima.color[4] = self.color[4]
    else
        self.remove = true
        self.anima.c = self.c
        self.anima:pop()
        self.anima.visible = false
    end
end

--
--------------- GHOST --------------------------------
local Ghost = Effect:new()
function Ghost:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "ghost"
    e.range = 1.
    e.speed = 1.5
    e.color = { 1, 1, 1 }
    return e
end

--
function Ghost:update(dt)
    self.rad = (self.rad + math.pi * 2. / self.speed * dt) % (math.pi * 2)
    self.anima.color = self.color
    self.anima.color[4] = 1. + math.math_sin(self.rad) * self.range
end

--
----------------- Twinkle --------------------------------------------------
local Twinkle = Effect:new()
function Twinkle:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "twinkle"
    e.speed = 0.2
    e.time = 0.0
    e.color = { 1., 0., 0., 1. }
    return e
end

--
function Twinkle:update(dt)
    self.time = self.time + dt
    if self.time >= self.speed then
        self.state = -self.state
        self.time = self.time - self.speed
    end

    if self.state == 1 then
        self.anima.color = self.color
    elseif self.state == -1 then
        self.anima.color = self.c.color
    end
    self.anima.color[4] = self.anima.color[4] or 1.
end

------------ SPIN -------------------------------------------
local Spin = Effect:new()
function Spin:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "spin"
    --e.prior = 1
    e.speed = 2.
    e.cc = 1.
    e.direction = 1

    e.anima.color = { 0.5, 0.5, 0.5 }

    return e
end

--
function Spin:update(dt)
    if self.rad <= math.pi then
        if self.rad <= math.pi / 2. * 0.5 or self.rad >= math.pi * 0.7 then
            self.direction = -1
        else
            self.direction = 1
        end
    else
        if self.rad <= math.pi + math.pi / 2. * 0.5 or self.rad <= math.pi * 2 * 0.8 then
            self.direction = 1
        else
            self.direction = -1
        end
    end

    self.cc = self.cc + self.speed * 0.8 * dt * self.direction
    if self.direction < 0 and self.cc < 0.5 then self.cc = 0.5 end
    if self.direction > 0 and self.cc > 1 then self.cc = 1. end

    self.anima.color = { self.cc, self.cc, self.cc, 1 }

    self.rad = self.rad % (math.pi * 2.)

    self.rad = (self.rad + (math.pi * 2.) / self.speed * dt)
    self.scale.x = (math.math_sin(self.rad) * (self.c.scale.x))


    --self.anima.scale.x = self.scale.x * (self.rad <= math.pi and 1 or 1)
    --self.anima.scale.y = self.c.scale.y
end

--
function Spin:draw(x, y)

    self.anima.configTr.sx = math.math_sin(self.rad)
    self.anima:setTransform(nil)

    --[[
    love.graphics.push( )
    
    local t = love.math.newTransform( x, y, self.anima.angle, math.sin(self.rad), 1., x, y )
    love.graphics.replaceTransform(t)
    
    self.anima.color = {self.cc, self.cc, self.cc, 1}
    self.anima:drawWithoutEff(x,y)
    self.anima.color[4] = 0
    love.graphics.pop( ) --]]

end

---------------- POP ----------------------------------------------------
local Pop = Effect:new()
function Pop:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "pop"
    e.scale.y = 0.

    e.speed = 0.2
    e.time = 0
    e.range = 0.2

    return e
end

--
function Pop:update(dt)
    local dif = self.c.scale.y * (1. + self.range) + self.range

    self.time = self.time + dt
    if self.state == 1 then
        self.scale.y = self.scale.y + (dif / self.speed) * dt
        if self.scale.y >= (self.c.scale.y * (1. + self.range)) then self.scale.y = (self.c.scale.y * (1. + self.range));
            self.state = 2;
        end
    end
    if self.state == 2 then
        self.scale.y = self.scale.y - (dif) / self.speed * dt
        if self.scale.y <= self.c.scale.y then self.state = -1; end
    end
    if self.state == -1 then
        self.time = self.time - dt
        self.anima.scale.y = self.c.scale.y

        if not self.maxrow or self.row >= self.maxrow - 1 then
            self.remove = true
        else
            self:resetExtend()
            self.row = self.row + 1
        end
        return
    end

    self.anima.scale.y = self.scale.y
end

--
function Pop:resetExtend()
    self.scale.y = 0
    self.state = 1

end

------------------ ROTATE ----------------------------------
local Rotate = Effect:new()
function Rotate:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.speed = 2.
    e.direction = 1
    return e
end

function Rotate:update(dt)
    self.rad = self.rad + (math.pi * 2.) / self.speed * dt * self.direction
    if self.rad >= math.pi * 2. then self.row = self.row + 1 end
    self.rad = self.rad % (math.pi * 2.)
    if self.maxrow and self.row >= self.maxrow then self.anima.angle = self.c.angle;
        self.remove = true;
        return
    end
    self.anima.angle = self.rad
end

---------------- BALANCE --------------------------------------------------
local Balance = Effect:new()
function Balance:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "balance"
    e.range = 0.1
    e.speed = 4.
    e.direction = 1
    e.row = 0
    return e
end

function Balance:update(dt)
    if self.maxrow and self.row >= self.maxrow then self.remove = true;
        self.anima.angle = self.c.angle
        return
    end

    self.rad = self.rad + math.pi * 2 / self.speed * dt * self.direction

    if self.rad >= math.pi * 2. then self.row = self.row + 1 end

    self.rad = self.rad % (math.pi * 2.)
    self.anima.angle = math.math_sin(self.rad) * (math.pi * 2. * self.range)
end

------------------ GROWTH -----------------------------------------------------
local Growth = Effect:new()

function Growth:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "growth"
    e.prior = -1
    e.range = 1.
    e.speed = 1.

    e.initial = { x = e.anima.scale.x, y = e.anima.scale.y }
    e.scale.x = e.anima.scale.x
    e.scale.y = e.anima.scale.y

    return e
end

--
function Growth:update(dt)
    self.scale.x = self.scale.x + self.range / self.speed * dt
    self.scale.y = self.scale.y + self.range / self.speed * dt

    if self.scale.x <= self.initial.x + self.range or self.scale.y <= self.initial.y + self.range then
        local sx, sy = self.scale.x <= self.initial.x + self.range and self.scale.x or self.initial.x + self.range,
            self.scale.y <= self.initial.y + self.range and self.scale.y or self.initial.y + self.range
        self.anima:setScale(sx, sy)
    else
        self.anima:setScale(self.initial.x + self.range, self.initial.y + self.range)
        self.remove = true
    end
end

--
function Growth:resetExtend()
    self.scale.x = self.initial.x
    self.scale.y = self.initial.y
end

----------------- SHRINK -------------------------------------------------
local Shrink = Effect:new()

function Shrink:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "shrink"
    e.prior = -1
    e.range = 1.
    e.speed = 1.

    e.initial = { x = e.anima.scale.x, y = e.anima.scale.y }
    e.scale.x = e.anima.scale.x
    e.scale.y = e.anima.scale.y

end

--
function Shrink:update(dt)
    self.scale.x = self.scale.x + self.range / self.speed * dt
    self.scale.y = self.scale.y + self.range / self.speed * dt
end

--
--------------- Disc ---------------------------------------------------
local Disc = Effect:new()

function Disc:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "disc"
    e.range = 0.8
    e.speed = 4.
    e.direction = 1
    e.cc = 0
    return e
end

--
function Disc:update(dt)

    self.rad = self.rad + (math.pi * 2) / self.speed * dt

    if self.rad >= math.pi * 2. then self.row = self.row + 1 end

    self.rad = self.rad % (math.pi * 2.)
    self.anima.kx = math.math_sin(self.rad) * self.range
    self.anima.ky = -math.math_sin(self.rad + math.pi * 1.5) * self.range

end

--
-------------- IDDLE--------------------------------
local Iddle = Effect:new()

function Iddle:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "iddle"
    e.speed = 1.
    e.time = 0
    return e
end

--
function Iddle:update(dt)
    self.time = self.time + dt
    if self.time >= self.speed * (self.maxrow or 1.) then self.remove = true end
end

--
function Iddle:resetExtend()
    self.time = 0.
end

---------------- FLOAT ---------------------------------
local Float = Effect:new()

function Float:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "float"
    e.speed = 1.
    e.range = 20
    --e.anima.color[4] = 0.

    e.floatX = false
    e.floatY = true
    e.adjust = math.pi / 2.
    e.adjustTime = 1.
    return e
end

--
function Float:update(dt)
    if self.maxrow and self.row >= self.maxrow then self.remove = true end

    self.rad = self.rad + math.pi * 2. / self.speed * dt
    if self.rad >= math.pi * 2. then self.row = self.row + 1 end
    self.rad = self.rad % (math.pi * 2)
end

--
function Float:draw(x, y)
    if self.floatX then
        self.anima.configTr.ox = x + (math.math_sin(self.rad + self.adjust) * self.range)
    end
    if self.floatY then
        self.anima.configTr.oy = y + (math.math_sin(self.rad) * self.range)
    end

    self.anima:setTransform(nil)

    --[[
    self.anima.color[4] = 1.
    self.anima:drawWithoutEff(x, y + (math.sin(self.rad) * self.range))
    self.anima.color[4] = .0--]]
end

--
---------------- ECHO --------------------------------
local Echo = Effect:new()

function Echo:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "echo"
    e.speed = 1.
    e.range = 2.
    --e.anima.color[4] = 0.

    e.alpha = 1.

    return e
end

--
function Echo:update(dt)
    if not self.maxrow then self.maxrow = 1 end

    if self.maxrow and self.row >= self.maxrow then
        self.remove = true;
        --self.anima.scale.x = self.c.scale.x
        --self.anima.scale.y = self.c.scale.y
        --self.anima.color[4] = self.c.color[4] or 1.;
        return
    end

    self.rad = self.rad + self.range / self.speed * dt
    self.alpha = self.alpha - 1. / self.speed * dt

    if self.rad <= self.range then
        self.scale.x = self.c.scale.x + self.rad
        self.scale.y = self.c.scale.y + self.rad
    else
        self.rad = 0
        self.scale.x = self.c.scale.x
        self.scale.y = self.c.scale.y
        self.alpha = 1.
        self.row = self.row + 1
    end
end

--
function Echo:resetExtend()
    self.maxrow = self.maxrow or 1
    self.alpha = 1
end

function Echo:draw(x, y)
    if self.remove then return end
    local sx, sy = self.anima.scale.x, self.anima.scale.y

    self.anima.scale.x = self.c.scale.x + self.rad
    self.anima.scale.y = self.c.scale.y + self.rad
    self.anima.color[4] = self.alpha
    self.anima:drawWithoutEff(x, y)

    self.anima.scale.x = sx
    self.anima.scale.y = sy
    self.anima.color[4] = self.c.color[4] or 1.

    self.anima:drawWithoutEff(x, y)
end

--
---------- DARKEN --- BRIGHTEN ----------------
local Darken = Effect:new()

function Darken:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "darken"
    e.speed = 1.

    e.color = { 1, 1, 1 }
    e.factor = 255.
    e.direction = -1.

    e.anima.color = e.color
    e.time = 0
    return e
end

--
function Darken:update(dt)
    self.time = self.time + dt

    self.factor = self.factor + 255. / self.speed * dt * self.direction

    self.anima.color = { 1. * self.color[1] * self.factor / 255., 1. * self.color[2] * self.factor / 255.,
        1. * self.color[3] * self.factor / 255. }

    if self.direction < 0 and self.factor <= 0. or
        self.direction > 0 and self.factor >= 255. then
        self.row = self.row + 1
        if self.maxrow and self.row >= self.maxrow or not self.maxrow then self.remove = true; return end
        self:resetExtend()
    end
end

--
function Darken:resetExtend()
    self.anima.color = self.color
    self.factor = self.direction < 0 and 255. or 0.
end

--
------- SHADOW ---------------------------
local Shadow = Effect:new()

function Shadow:new(anima)
    local e = Effect:new(anima)
    setmetatable(e, self)
    self.__index = self

    e.id = "shadow"

    e.range = 0.9
    e.color = { 0, 0, 0, 0.4 }
    e.adjustX = 15.
    e.adjustY = 15.
    return e
end

--
function Shadow:update(dt)

end

--
function Shadow:draw(x, y)
    local sx, sy, color = self.anima.scale.x, self.anima.scale.y, self.anima.color
    local temp = self.id == "shadow" and 10. * self.c.scale.y or 0

    self.anima.color = self.color
    self.anima.scale.x = sx * self.range
    self.anima.scale.y = sy * self.range
    self.anima:drawWithoutEff(x + self.adjustX + temp, y + self.adjustY + temp)

    self.anima.scale.x = sx
    self.anima.scale.y = sy
    self.anima.color = color
    self.anima:drawWithoutEff(x, y)
end

--
---------------------------------------------------------------------------
local function isInEffectList(eff, animation)
    if not animation.effects then return end

    for i = 1, #animation.effects do if eff == animation.effects[i] then return true end end
end

--

-------------------------------------------------------------------------------
function Anima:applyEffect(effectType, speed, range, maxrow, getOnly)
    if not self.effects then self.effects = {} end
    local eff

    if type(effectType) ~= "string" then
        effectType.speed = speed or effectType.speed
        effectType.range = range or effectType.range
        effectType.maxrow = maxrow or effectType.maxrow

        if not getOnly and not isInEffectList(effectType, self) then
            table.insert(self.effects, effectType)
            self.sort = true
        end
        return effectType
    end

    if effectType == "pulse" then
        eff = Pulse:new(self)
    elseif effectType == "flash" then
        eff = Flash:new(self)
    elseif effectType == "popin" then
        eff = Popin:new(self)
    elseif effectType == "popout" then
        eff = Popout:new(self)
    elseif effectType == "fadein" then
        eff = Fadein:new(self)
    elseif effectType == "fadeout" then
        eff = Fadeout:new(self)
    elseif effectType == "ghost" then
        eff = Ghost:new(self)
    elseif effectType == "twinkle" then
        eff = Twinkle:new(self)
    elseif effectType == "spin" then
        eff = Spin:new(self)
    elseif effectType == "clockWise" then
        eff = Rotate:new(self)
        eff.id = "clockWise"
    elseif effectType == "counterClockWise" then
        eff = Rotate:new(self)
        eff.direction = -1
        eff.id = "counterClockWise"
    elseif effectType == "balance" then
        eff = Balance:new(self)
    elseif effectType == "pop" then
        eff = Pop:new(self)
    elseif effectType == "growth" then
        eff = Growth:new(self)
    elseif effectType == "disc" then
        eff = Disc:new(self)
    elseif effectType == "iddle" then
        eff = Iddle:new(self)
    elseif effectType == "echo" then
        eff = Echo:new(self)
    elseif effectType == "float" or effectType == "floatY" then
        eff = Float:new(self)
    elseif effectType == "floatX" then
        eff = Float:new(self)
        eff.state = 2
    elseif effectType == "darken" then
        eff = Darken:new(self)
    elseif effectType == "brighten" then
        eff = Darken:new(self)
        eff.direction = 1.
        eff.anima.color = { 0, 0, 0 }
        eff.factor = 0.
        eff.id = "brighten"
    elseif effectType == "shadow" then
        eff = Shadow:new(self)
    elseif effectType == "line" then
        eff = Shadow:new(self)
        eff.id = "line"
        eff.adjustX = 0
        eff.adjustY = 0
        eff.color = { 0, 0, 0, 1 }
        eff.range = 1.1
    elseif effectType == "flick" then
        eff = Twinkle:new(self)
        eff.color = { 0, 0, 0, 0 }
        eff.speed = 0.08
        eff.id = "flick"
    elseif effectType == "distorcion" then
        eff = Pulse:new(self)
        eff.adjust = math.pi * 0.7
        eff.id = "distorcion"
    elseif effectType == "zoomInOut" then
        eff = Pulse:new(self)
        eff.adjust = 0.
        eff.id = "zoomInOut"
    elseif effectType == "stretchX" then
        eff = Pulse:new(self)
        eff.difY = 0.
    elseif effectType == "circle" then
        eff = Float:new(self)
        eff.floatX = true
    elseif effectType == "eight" then
        eff = Float:new(self)
        eff.floatX = true
        eff.adjust = math.pi
    elseif effectType == "stretchY" then
        eff = Pulse:new(self)
        eff.difX = 0.
        eff.id = "stretchY"
    elseif effectType == "bounce" then
        eff = Pulse:new(self)
        eff.acc = 0.5
        eff.speed = 0.05
        eff.maxrow = 6
        eff.difX = 0.1
        eff.difY = self.scale.y * 0.25
        eff.id = "stretchX"
    end

    if eff then
        eff.speed = speed or eff.speed
        eff.range = range or eff.range
        eff.maxrow = maxrow or eff.maxrow
        if not getOnly then
            table.insert(self.effects, eff)
            self.sort = true
        end
    end

    return eff
end

--

function Anima:getEffect(effectType, speed, range, maxrow)
    local eff = self:applyEffect(effectType, speed, range, maxrow, true)
    --if eff then table.remove(self.effects, #self.effects)  end
    return eff
end

return Anima
