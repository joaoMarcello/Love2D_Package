local abs, mfloor, mceil, sqrt = math.abs, math.floor, math.ceil, math.sqrt

---@enum JM.Physics.BodyTypes
local BodyTypes = {
    dynamic = 1,
    static = 2,
    kinematic = 3
}

---@alias JM.Physics.Cell {count:number, x:number, y:number, items:table}

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

    function Body:refresh(x, y, w, h)
        x = x or self.x
        y = y or self.y
        w = w or self.w
        h = h or self.h

        if x ~= self.x or y ~= self.y or w ~= self.w or h ~= self.h then
            local cellsize = self.world.tile
            local world = self.world
            local cl1, ct1, cw1, ch1 = world:rect_to_cell(self:rect())
            local cl2, ct2, cw2, ch2 = world:rect_to_cell(x, y, w, h)

            if cl1 ~= cl2 or ct1 ~= ct2 or cw1 ~= cw2 or ch1 ~= ch2 then

                local cr1, cb1 = (cl1 + cw1 - 1), (ct1 + ch1 - 1)
                local cr2, cb2 = (cl2 + cw2 - 1), (ct2 + ch2 - 1)
                local cy_out

                for cy = ct1, cb1 do

                    cy_out = cy < ct2 or cy > cb2

                    for cx = cl1, cr1 do
                        if cy_out or cx < cl2 or cx > cr2 then
                            world:remove_obj_from_cell(self, cx, cy)
                        end
                    end
                end

                for cy = ct2, cb2 do

                    cy_out = cy < ct1 or cy > cb1

                    for cx = cl2, cr2 do
                        if cy_out or cx < cl1 or cx > cr1 then
                            world:add_obj_to_cell(self, cx, cy)
                        end
                    end
                end
            end -- End If

            self.x, self.y, self.w, self.h = x, y, w, h
        end
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
        self.max_speed_y = self.meter * 8
        self.default_mass = 65

        self.bodies = {}
        self.n_bodies = 0

        self.grid = {}
    end

    function World:to_cell(x, y)
        return mfloor(x / self.tile) + 1, mfloor(y / self.tile) + 1
    end

    function World:count_Cells()
        local count = 0
        for _, row in pairs(self.grid) do
            for _, _ in pairs(row) do
                count = count + 1
            end
        end
        return count
    end

    function World:rect_to_cell(x, y, w, h)
        local cleft, ctop = self:to_cell(x, y)
        local cright = mceil((x + w) / self.tile)
        local cbottom = mceil((y + h) / self.tile)

        return cleft, ctop, cright - cleft + 1, cbottom - ctop + 1
    end

    function World:add_obj_to_cell(obj, cx, cy)
        self.grid[cy] = self.grid[cy] or {}
        local row = self.grid[cy]

        row[cx] = row[cx] or { count = 0, x = cx, y = cy, items = {} }
        local cell = row[cx]

        if not cell.items[obj] then
            cell.items[obj] = true
            cell.count = cell.count + 1
        end
    end

    function World:remove_obj_from_cell(obj, cx, cy)
        local row = self.grid[cy]
        if not row or not row[cx] or not row[cx].items[obj] then return end

        ---@type JM.Physics.Cell
        local cell = row[cx]
        cell.items[obj] = nil
        cell.count = cell.count - 1
        return true
    end

    ---@param obj JM.Physics.Body
    function World:get_items_in_cell_obj(obj)
        local cl, ct, cw, ch = self:rect_to_cell(obj.x, obj.y, obj.w, obj.h)
        local items = {}

        for cy = ct, ct + ch - 1 do
            local row = self.grid[cy]

            if row then
                for cx = cl, cl + cw - 1 do

                    ---@type JM.Physics.Cell
                    local cell = row[cx]

                    if cell and cell.count > 0 then
                        for item, _ in pairs(cell.items) do
                            items[item] = true
                        end
                    end

                end -- End For Columns
            end
        end -- End for rows

        return items
    end

    ---@param obj JM.Physics.Body
    function World:add(obj)
        table.insert(self.bodies, obj)
        self.n_bodies = self.n_bodies + 1

        local cl, ct, cw, ch = self:rect_to_cell(obj:rect())

        for cy = ct, ct + ch - 1, 1 do
            for cx = cl, cl + cw - 1, 1 do
                self:add_obj_to_cell(obj, cx, cy)
            end
        end

        self.debug = {
            l = tostring(cl), t = tostring(ct), r = tostring(cw), b = tostring(ch)
        }

    end

    ---@param obj JM.Physics.Body
    function World:remove(obj, index)
        local r = table.remove(self.bodies, index)

        if r then
            self.n_bodies = self.n_bodies - 1

            local cl, ct, cw, ch = self:rect_to_cell(obj:rect())

            for cy = ct, (ct + ch - 1) do
                for cx = cl, (cl + cw - 1) do
                    self:remove_obj_from_cell(obj, cx, cy)
                end
            end
        end
        r = nil
    end

    function World:update(dt)
        for i = 1, self.n_bodies, 1 do
            ---@type JM.Physics.Body
            local obj = self.bodies[i]

            if is_dynamic(obj) or is_kinematic(obj) then
                local goalx, goaly

                -- falling
                if (obj.acc_y ~= 0) or (obj.speed_y ~= 0) then
                    -- speed up with acceleration
                    obj.speed_y = obj.speed_y + obj.acc_y * dt

                    if self.max_speed_y and obj.speed_y > self.max_speed_y then
                        obj.speed_y = self.max_speed_y
                    end

                    goaly = obj.y + (obj.speed_y * dt)
                        + (obj.acc_y * dt * dt) / 2.0

                    -- obj:set_y_pos(obj.y + (obj.speed_y * dt)
                    --     + (obj.acc_y * dt * dt) / 2.0
                    -- )

                    obj:refresh(nil, goaly)

                    local col = self:check(obj)
                    if col then
                        if obj.speed_y > 0 then
                            obj.y = col.y - obj.h
                        else
                            obj.y = col.y + col.h
                        end
                        obj.speed_y = 0
                    end

                    -- local cobj = self:check_collision(obj)
                    -- if cobj then
                    --     obj:set_y_pos(cobj.y - obj.h)

                    --     if obj.bouncing then
                    --         obj.speed_y = -obj.speed_y * obj.bouncing
                    --         if abs(obj.speed_y) <= 32 then
                    --             obj.speed_y = 0
                    --         end
                    --     else
                    --         obj.speed_y = sqrt(2 * obj.acc_y * 1)
                    --     end

                    --     local r = obj.on_ground_collision_action and obj.on_ground_collision_action(obj)

                    --     obj.ground = cobj

                    --     r = nil
                    -- end
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

                    -- obj:set_x_pos(obj.x + (obj.speed_x * dt)
                    --     + (obj.acc_x * dt * dt) / 2.0
                    -- )

                    goalx = obj.x + (obj.speed_x * dt)
                        + (obj.acc_x * dt * dt) / 2.0

                    obj:refresh(goalx)

                    local col = self:check(obj)
                    if col then
                        if obj.speed_x < 0 then
                            obj.x = col.x + col.w
                        else
                            obj.x = col.x - obj.w
                        end
                        obj.speed_x = 0
                    end
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
        local cl, ct, cw, ch = self:rect_to_cell(obj:rect())
        local items = self:get_items_in_cell_obj(obj)

        for item, _ in pairs(items) do
            if item ~= obj and collision_rect(
                obj.x, obj.y, obj.w, obj.h,
                item.x, item.y, item.w, item.h
            )
            then
                return item
            end
        end

        -- obj.collisions = nil
        -- obj.collisions = {}
        -- obj.n_collisions = 0

        -- for i = 1, self.n_bodies, 1 do
        --     local bd

        --     ---@type JM.Physics.Body
        --     bd = self.bodies[i]

        --     if bd ~= obj and collision_rect(
        --         bd.x, bd.y, bd.w, bd.h,
        --         obj.x, obj.y, obj.w, obj.h)
        --     then
        --         table.insert(obj.collisions, bd)
        --         obj.n_collisions = obj.n_collisions + 1
        --     end
        --     bd = nil
        -- end
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
