---@enum JM.Physics.BodyTypes
local BodyTypes = {
    dynamic = 1,
    static = 2,
    kinematic = 3
}

local function collision_rect(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end

---@param obj JM.Physics.Body
local function is_static(obj)
    return obj.type == BodyTypes.static
end

---@param obj JM.Physics.Body
local function is_dynamic(obj)
    return obj.type == BodyTypes.dynamic
end

---@param obj JM.Physics.Body
local function is_kinematic(obj)
    return obj.type == BodyTypes.kinematic
end

--=============================================================================
---@class JM.Physics.Body
local Body = {}
do
    ---@return JM.Physics.Body
    function Body:new(x, y, w, h, type_, world)
        local obj = {}
        setmetatable(obj, self)
        self.__index = self

        Body.__constructor__(obj, x, y, w, h, type_, world)
        return obj
    end

    ---@param world JM.Physics.World
    ---@param type_ JM.Physics.BodyTypes
    function Body:__constructor__(x, y, w, h, type_, world)
        self.x = x
        self.y = y
        self.w = w
        self.h = h

        self.mass = world.default_mass

        self.speed_x = 0
        self.speed_y = 0

        self.max_speed_x = nil
        self.max_speed_y = nil

        self.acc_x = world.meter * 1.5
        self.acc_y = world.gravity * (self.mass / world.default_mass)

        self.world = world

        -- used if body is static
        self.resistance_x = 1

        ---@type JM.Physics.Body
        self.ground = nil -- used if body is not static

        self.type = type_
    end

    function Body:set_position(x, y)
        x = x or self.x
        y = y or self.y
        self.x = x
        self.y = y
    end

    function Body:set_dimensions(w, h)
        w = w or self.w
        h = h or self.h
        self.w = w
        self.h = h
    end

    function Body:set_speed(sx, sy)
        sx = sx or self.speed_x
        sy = sy or self.speed_y
        self.speed_x = sx
        self.speed_y = sy
    end

    function Body:set_acc(ax, ay)
        ax = ax or self.acc_x
        ay = ay or self.acc_y
        self.acc_x = ax
        self.acc_y = ay
    end
end
--=============================================================================
---@class JM.Physics.World
local World = {}
do
    function World:new()
        local obj = {}
        setmetatable(obj, self)
        self.__index = self

        World.__constructor__(obj)
        return obj
    end

    function World:__constructor__()
        self.tile = 32
        self.meter = self.tile * 3.5
        self.gravity = 9.8 * self.meter
        self.max_speed_y = self.meter * 4
        self.default_mass = 50

        self.bodies = {}
        self.n_bodies = 0
    end

    function World:add(obj)
        table.insert(self.bodies, obj)
        self.n_bodies = self.n_bodies + 1
    end

    function World:remove(obj)
        local r = table.remove(self.bodies, obj)
        if r then self.n_bodies = self.n_bodies - 1 end
        r = nil
    end

    function World:update(dt)
        for i = 1, self.n_bodies, 1 do
            ---@type JM.Physics.Body
            local obj = self.bodies[i]

            if is_dynamic(obj) then
                -- falling
                if obj.acc_y ~= 0 then
                    -- speed up with acceleration
                    obj.speed_y = obj.speed_y + obj.acc_y * dt

                    obj.y = obj.y + (obj.speed_y * dt)
                        + (obj.acc_y * dt * dt) / 2.0
                end

                -- moving in x axis
                if obj.speed_x ~= 0 then
                    local last_sx = obj.speed_x

                    obj.speed_x = obj.speed_x + obj.acc_x * dt

                    -- if reach max speed
                    if obj.max_speed_x
                        and math.abs(obj.speed_x) > obj.max_speed_x
                    then
                        obj.speed_x = obj.max_speed_x
                            * math.abs(obj.speed_x) / obj.speed_x
                    end

                    -- dacc
                    if (obj.acc_x > 0 and last_sx < 0 and obj.speed_x >= 0)
                        or (obj.acc_x < 0 and last_sx > 0 and obj.speed_x <= 0)
                    then
                        obj.speed_x = 0
                    end

                    if obj.speed_x ~= 0 then
                        obj.x = obj.x + (obj.speed_x * dt)
                            + (obj.acc_x * dt * dt) / 2.0
                    end
                end


            end
        end
    end

    ---@param obj JM.Physics.Body
    function World:check_collision(obj)
        if is_static(obj) then return end
        for i = 1, self.n_bodies, 1 do

        end
    end
end
--=============================================================================
---@class JM.Physics
local Phys = {}

function Phys:newBody(world, x, y, w, h, type_)
    type_ = (type_ == "dynamic" and BodyTypes.dynamic) or (type_ == "static" and BodyTypes.static) or BodyTypes.kinematic

    return Body:new(x, y, w, h, type_, world)
end

return Phys
