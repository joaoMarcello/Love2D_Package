local abs, mfloor, mceil, sqrt, min, max = math.abs, math.floor, math.ceil, math.sqrt, math.min, math.max

---@enum JM.Physics.BodyTypes
local BodyTypes = {
    dynamic = 1,
    static = 2,
    kinematic = 3
}

---@enum JM.Physics.BodyShapes
local BodyShapes = {
    rectangle = 1,
    ground_slope = 2,
    inverted_ground_slope = 3,
    ceil_slope = 4,
    inverted_ceil_slope = 5,
    circle = 8
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
        self.acc_y = 0 --world.gravity * (self.mass / world.default_mass)
        self.acc_y = (self.type ~= BodyTypes.dynamic and 0) or self.acc_y

        self.dacc_x = self.world.meter * 3.5
        self.dacc_y = nil

        -- used if body is static
        self.resistance_x = 1

        ---@type JM.Physics.Body
        self.ground = nil -- used if body is not static

        -- some properties
        self.bouncing = nil -- need to be a number between 0 and 1
        self.__remove = nil
        self.is_stucked = nil

        self.shape = BodyShapes.rectangle
    end

    function Body:check_collision(obj)
        return collision_rect(self.x, self.y, self.w, self.h,
            obj.x, obj.y, obj.w, obj.h)
    end

    -- function Body:reset_gravity()
    --     self.acc_y = self.world.gravity * (self.mass / self.world.default_mass)
    -- end

    function Body:set_mass(mass)
        self.mass = mass
        -- self:reset_gravity()
    end

    function Body:set_position(x, y)
        self:refresh(x, y)
    end

    function Body:set_y_pos(y)
        self:set_position(nil, y)
    end

    function Body:set_x_pos(x)
        self:set_position(x)
    end

    function Body:set_dimensions(w, h)
        self:refresh(nil, nil, w, h)
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

        local acc_y = self.world.gravity
            * (self.mass / self.world.default_mass)
            + self.acc_y

        self.speed_y = -sqrt(2 * abs(acc_y) * desired_height)
    end

    function Body:move(acc)
        self.acc_x = acc
    end

    function Body:on_ground_collision(action)
        self.on_ground_coll_action = action
    end

    function Body:on_wall_collision(action)
        self.on_wall_coll_action = action
    end

    function Body:refresh(x, y, w, h)
        x = x or self.x
        y = y or self.y
        w = w or self.w
        h = h or self.h

        if x ~= self.x or y ~= self.y or w ~= self.w or h ~= self.h then

            local world
            world = self.world

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

            world = nil
            self.x, self.y, self.w, self.h = x, y, w, h
        end
    end

    local default_filter = function(body, item)
        return true
    end

    ---@return table, number
    function Body:check(goal_x, goal_y, filter)
        goal_x = goal_x or self.x
        goal_y = goal_y or self.y
        filter = filter or default_filter

        local diff_x = goal_x - self.x
        local diff_y = goal_y - self.y

        local left, top, right, bottom
        top = min(self.y, goal_y)
        bottom = max(self.y + self.h, goal_y + self.h)
        left = min(self.x, goal_x)
        right = max(self.x + self.w, goal_x + self.w)

        local x, y, w, h = left, top, right - left, bottom - top

        local items = self.world:get_items_in_cell_obj(x, y, w, h)
        local collisions, n_collisions = {}, 0
        local most_left, most_right
        local most_up, most_bottom

        for item, _ in pairs(items) do
            if item ~= self and not item.__remove and not item.is_stucked

                and collision_rect(
                    x, y, w, h,
                    item.x, item.y, item.w, item.h
                )

                and filter(self, item)
            then
                table.insert(collisions, item)
                n_collisions = n_collisions + 1

                most_left = most_left or item
                most_left = (item.x < most_left.x and item) or most_left

                most_right = most_right or item
                most_right = ((item.x + item.w)
                    > (most_right.x + most_right.w) and item)
                    or most_left

                most_up = most_up or item
                most_up = (item.y < most_up.y and item) or most_up

                most_bottom = most_bottom or item
                most_bottom = ((item.y + item.h)
                    > (most_bottom.y + most_bottom.h) and item)
                    or most_bottom
            end
        end
        items = nil

        collisions.most_left = most_left
        collisions.most_right = most_right
        collisions.most_up = most_up
        collisions.most_bottom = most_bottom

        collisions.top = most_up and most_up.y
        collisions.bottom = most_bottom and (most_bottom.y + most_bottom.h)
        collisions.left = most_left and most_left.x
        collisions.right = most_right and most_right.x + most_right.w

        collisions.diff_x = diff_x
        collisions.diff_y = diff_y

        collisions.n = n_collisions

        return collisions, n_collisions
    end

    function Body:check2(goal_x, goal_y, filter, x, y, w, h)
        x = x or self.x
        y = y or self.y
        w = w or self.w
        h = h or self.h

        local bd = Body:new(x, y, w, h, self.type, self.world, self.id)

        local filter__ = function(obj, item)
            local r = filter and filter(obj, item)
            r = r and item ~= bd
            return r
        end

        return bd:check(goal_x, goal_y, filter__)
    end

    function Body:right()
        return self.x + self.w
    end

    function Body:bottom()
        return self.y + self.h
    end

    function Body:left()
        return self.x
    end

    function Body:top()
        return self.y
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
        self.max_speed_y = self.meter * 15
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

        local cell

        ---@type JM.Physics.Cell
        cell = row[cx]
        cell.items[obj] = nil
        cell.count = cell.count - 1

        if cell.count == 0 then
            cell.items = nil
            self.grid[cy][cx] = nil
        end

        row = nil
        cell = nil
        return true
    end

    ---@param x number
    ---@param y number
    ---@param w number
    ---@param h number
    function World:get_items_in_cell_obj(x, y, w, h)
        local cl, ct, cw, ch = self:rect_to_cell(x, y, w, h)
        local items = {}

        for cy = ct, (ct + ch - 1) do
            local row = self.grid[cy]

            if row then
                for cx = cl, (cl + cw - 1) do
                    local cell
                    ---@type JM.Physics.Cell
                    cell = row[cx]

                    if cell and cell.count > 0 then
                        for item, _ in pairs(cell.items) do
                            items[item] = true
                        end
                    end

                    cell = nil

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

        for cy = ct, (ct + ch - 1) do
            for cx = cl, (cl + cw - 1) do
                self:add_obj_to_cell(obj, cx, cy)
            end
        end

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

    local function dynamic_filter(obj, item)
        return is_dynamic(item)
    end

    local function colliders_filter(obj, item)
        return not is_dynamic(item)
    end

    local function kinematic_moves_dynamic(kbody, goalx, goaly)
        local col, n = kbody:check2(goalx, nil,
            dynamic_filter,
            nil, kbody.y - 1, nil, kbody.h + 2
        )

        if n > 0 then
            for i = 1, n do
                local bd

                ---@type JM.Physics.Body
                bd = col[i]

                bd:refresh(bd.x + col.diff_x)

                local col_bd, n_bd

                col_bd, n_bd = bd:check(nil, nil, colliders_filter)

                if n_bd > 0 then
                    if col.diff_x < 0 then
                        bd:refresh(col_bd.right + 0.1)
                    else
                        bd:refresh(col_bd.left - bd.w - 0.1)
                    end

                    local col_f, nn = bd:check(nil, nil, colliders_filter)

                    bd.is_stucked = nn > 0
                    -- bd.is_stucked = true
                end

                bd, col_bd = nil, nil
            end
        end

    end

    function World:update(dt)

        for i = self.n_bodies, 1, -1 do
            local obj

            ---@type JM.Physics.Body
            obj = self.bodies[i]

            if obj.__remove then
                self:remove(obj, i)
                obj = nil
            end

            if obj and obj.is_stucked then
                goto end_for_world_bodies
            end

            if obj and (is_dynamic(obj) or is_kinematic(obj)) then
                local goalx, goaly, acc_y

                acc_y = self.gravity * (obj.mass / self.default_mass)
                    + obj.acc_y

                -- falling
                if (acc_y ~= 0) or (obj.speed_y ~= 0) then

                    goaly = obj.y + (obj.speed_y * dt)
                        + (acc_y * dt * dt) / 2.0

                    if obj.speed_y == 0 then
                        obj.speed_y = sqrt(2 * acc_y * 1)
                    end

                    -- speed up with acceleration
                    obj.speed_y = obj.speed_y + acc_y * dt

                    if self.max_speed_y and obj.speed_y > self.max_speed_y then
                        obj.speed_y = self.max_speed_y
                    end

                    local col, n
                    col, n = obj:check(nil, goaly, colliders_filter)

                    if n > 0 then -- collision!

                        if obj.speed_y >= 0 then --falling
                            obj:refresh(nil, col.top - obj.h - 0.1)

                            if obj.bouncing then
                                obj.speed_y = -obj.speed_y * obj.bouncing
                                if abs(obj.speed_y) <= sqrt(2 * acc_y * 2) then
                                    obj.speed_y = 0
                                end
                            else
                                obj.speed_y = 0
                            end

                            local r = obj.on_ground_coll_action and
                                obj.on_ground_coll_action(obj)
                        else
                            obj:refresh(nil, col.bottom + 0.1) -- up
                            obj.speed_y = 0
                        end

                    else
                        obj:refresh(nil, goaly)
                    end

                    col = nil
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

                    goalx = obj.x + (obj.speed_x * dt)
                        + (obj.acc_x * dt * dt) / 2.0


                    local col, n
                    col, n = obj:check(goalx, nil, colliders_filter)

                    if n > 0 then
                        if obj.speed_x > 0 then
                            obj:refresh(col.left - obj.w - 0.1)
                        else
                            obj:refresh(col.right + 0.1)
                        end

                        local r = obj.on_wall_coll_action and obj.on_wall_coll_action()

                        obj.speed_x = 0
                    else

                        -- -- kinematic bodies moves dynamic objects
                        -- if is_kinematic(obj) then
                        --     local col, n = obj:check2(goalx, nil,

                        --         function(obj, item)
                        --             return is_dynamic(item)
                        --         end,

                        --         nil, obj.y - 1, nil, obj.h + 2
                        --     )

                        --     if n > 0 then
                        --         for i = 1, n do
                        --             local bd

                        --             ---@type JM.Physics.Body
                        --             bd = col[i]

                        --             bd:refresh(bd.x + col.diff_x)

                        --             local col_bd, n_bd

                        --             col_bd, n_bd = bd:check(nil, nil, function(obj, item)
                        --                 return not is_dynamic(item)
                        --             end)

                        --             if n_bd > 0 then
                        --                 if col.diff_x < 0 then
                        --                     bd:refresh(col_bd.right + 0.1)
                        --                 else
                        --                     bd:refresh(col_bd.left - bd.w - 0.1)
                        --                 end

                        --                 local col_f, nn = bd:check(nil, nil, function(obj, item)
                        --                     return not is_dynamic(item)
                        --                 end)

                        --                 bd.is_stucked = nn > 0
                        --                 -- bd.is_stucked = true
                        --             end

                        --             bd, col_bd = nil, nil
                        --         end
                        --     end
                        -- end

                        if is_kinematic(obj) then
                            kinematic_moves_dynamic(obj, goalx)
                        end

                        obj:refresh(goalx)
                    end

                    col = nil

                    if obj.speed_x ~= 0 then
                        local dacc = obj.dacc_x or abs(obj.acc_x)
                        obj:set_acc(dacc * -obj:direction_x())
                    end
                end -- end moving in x axis
            end --end if body is dynamic

            obj = nil

            ::end_for_world_bodies::
        end
    end

    ---@param obj JM.Physics.Body
    function World:check(obj)
        -- local cl, ct, cw, ch = self:rect_to_cell(obj:rect())
        local items = self:get_items_in_cell_obj(obj:rect())

        for item, _ in pairs(items) do
            if item ~= obj and not item.__remove and obj:check_collision(item) then
                return item
            end
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
---@param type_ "dynamic"|"kinematic"|"static"
---@return JM.Physics.Body
function Phys:newBody(world, x, y, w, h, type_)
    local bd_type = (type_ == "dynamic" and BodyTypes.dynamic)
        or (type_ == "kinematic" and BodyTypes.kinematic)
        or BodyTypes.static

    local b = Body:new(x, y, w, h, bd_type, world)

    world:add(b)
    return b
end

return Phys
