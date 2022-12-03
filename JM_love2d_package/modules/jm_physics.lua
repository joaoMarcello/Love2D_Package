local abs, mfloor, mceil, sqrt = math.abs, math.floor, math.ceil, math.sqrt

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

local function round(value)
    local absolute = abs(value)
    local decimal = absolute - mfloor(absolute)

    if decimal >= 0.5 then
        return value > 0 and mceil(value) or mfloor(value)
    else
        return value > 0 and mfloor(value) or mceil(value)
    end
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
    function Body:new(x, y, w, h, type_, world, id)
        local obj = {}
        setmetatable(obj, self)
        self.__index = self

        Body.__constructor__(obj, x, y, w, h, type_, world, id)
        return obj
    end

    ---@param world JM.Physics.World
    ---@param type_ JM.Physics.BodyTypes
    function Body:__constructor__(x, y, w, h, type_, world, id)

        self.type = type_
        self.id = id or ""
        self.world = world

        self.x = x
        self.y = y
        self.w = w
        self.h = h

        self.mass = world.default_mass

        self.speed_x = 0
        self.speed_y = 0

        self.max_speed_x = nil
        self.max_speed_y = nil

        self.acc_x = 0 --world.meter * 1.5
        self.acc_y = world.gravity * (self.mass / world.default_mass)
        self.acc_y = (self.type ~= BodyTypes.dynamic and 0) or self.acc_y

        -- used if body is static
        self.resistance_x = 1

        ---@type JM.Physics.Body
        self.ground = nil -- used if body is not static

        self.bouncing = nil

    end

    function Body:reset_gravity()
        self.acc_y = self.world.gravity * (self.mass / self.world.default_mass)
    end

    function Body:set_mass(mass)
        self.mass = mass
        self:reset_gravity()
    end

    function Body:set_position(x, y)
        x = x or self.x
        y = y or self.y
        self.x = x
        self.y = y
    end

    function Body:set_y_pos(y)
        self:set_position(nil, y)
    end

    function Body:set_x_pos(x)
        self:set_position(x)
    end

    function Body:set_dimensions(w, h)
        w = w or self.w
        h = h or self.h
        self.w = w
        self.h = h
    end

    function Body:rect()
        return self.x, self.y, self.w, self.h
    end

    function Body:direction_x()
        return (self.speed_x < 0 and -1) or (self.speed_x > 0 and 1) or 0
    end

    function Body:direction_y()
        return (self.speed_y < 0 and -1) or (self.speed_y > 0 and 1) or 0
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

    function Body:jump(desired_height)
        self.ground = nil
        self:reset_gravity()
        self.speed_y = -sqrt(2 * self.acc_y * desired_height)
    end

    function Body:move(acc)
        self.acc_x = acc
    end

    function Body:on_ground_collision(action)
        self.on_ground_collision_action = action
    end
end
--=============================================================================
---@class JM.Physics.World
local World = {}
do
    function World:new(args)
        local obj = {}
        setmetatable(obj, self)
        self.__index = self

        World.__constructor__(obj, args)
        return obj
    end

    function World:__constructor__(args)
        self.tile = 32
        self.meter = self.tile * 3.5
        self.gravity = 9.8 * self.meter
        self.max_speed_y = self.meter * 7
        self.default_mass = 65

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

            if is_dynamic(obj) or is_kinematic(obj) then
                -- falling
                if (obj.acc_y ~= 0) or (obj.speed_y ~= 0) then
                    -- speed up with acceleration
                    obj.speed_y = obj.speed_y + obj.acc_y * dt

                    if self.max_speed_y and obj.speed_y > self.max_speed_y then
                        obj.speed_y = self.max_speed_y
                    end

                    obj:set_y_pos(obj.y + (obj.speed_y * dt)
                        + (obj.acc_y * dt * dt) / 2.0
                    )

                    local cobj = self:check_collision(obj)
                    if cobj then
                        obj:set_y_pos(cobj.y - obj.h)

                        if obj.bouncing then
                            obj.speed_y = -obj.speed_y * obj.bouncing
                            if abs(obj.speed_y) <= 32 then
                                obj.speed_y = 0
                            end
                        else
                            obj.speed_y = sqrt(2 * obj.acc_y * 1)
                        end

                        local r = obj.on_ground_collision_action and obj.on_ground_collision_action(obj)

                        obj.ground = cobj

                        r = nil
                    end
                end

                -- moving in x axis
                if (obj.acc_x ~= 0) or (obj.speed_x ~= 0) then
                    local last_sx = obj.speed_x

                    obj.speed_x = obj.speed_x + obj.acc_x * dt

                    -- if reach max speed
                    if obj.max_speed_x
                        and abs(obj.speed_x) > obj.max_speed_x
                    then
                        obj.speed_x = obj.max_speed_x
                            * obj:direction_x()
                    end

                    -- dacc
                    if (obj.acc_x > 0 and last_sx < 0 and obj.speed_x >= 0)
                        or (obj.acc_x < 0 and last_sx > 0 and obj.speed_x <= 0)
                    then
                        obj.speed_x = 0
                        obj.acc_x = 0
                    end

                    obj:set_x_pos(obj.x + (obj.speed_x * dt)
                        + (obj.acc_x * dt * dt) / 2.0
                    )
                end -- end moving in x axis
            end --end if body is dynamic
        end
    end

    ---@param obj JM.Physics.Body
    function World:check_collision(obj)
        for i = 1, self.n_bodies, 1 do
            ---@type JM.Physics.Body
            local bd = self.bodies[i]

            if bd ~= obj and collision_rect(
                bd.x, bd.y, bd.w, bd.h,
                obj.x, obj.y, obj.w, obj.h)
            then
                return bd
            end
        end
        return false
    end

    ---@param obj JM.Physics.Body
    function World:check(obj)
        obj.collisions = nil
        obj.collisions = {}
        obj.n_collisions = 0

        for i = 1, self.n_bodies, 1 do
            local bd

            ---@type JM.Physics.Body
            bd = self.bodies[i]

            if bd ~= obj and collision_rect(
                bd.x, bd.y, bd.w, bd.h,
                obj.x, obj.y, obj.w, obj.h)
            then
                table.insert(obj.collisions, bd)
                obj.n_collisions = obj.n_collisions + 1
            end
            bd = nil
        end
    end
end
--=============================================================================
---@class JM.Physics
local Phys = {}

---@return JM.Physics.World
function Phys:newWorld(args)
    return World:new(args)
end

---@param world JM.Physics.World
---@return JM.Physics.Body
function Phys:newBody(world, x, y, w, h, type_)
    type_ = (type_ == "dynamic" and BodyTypes.dynamic)
        or (type_ == "kinematic" and BodyTypes.kinematic)
        or BodyTypes.static

    local b = Body:new(x, y, w, h, type_, world)
    world:add(b)
    return b
end

return Phys
