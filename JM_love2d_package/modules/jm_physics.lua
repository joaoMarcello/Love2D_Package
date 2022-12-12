local abs, mfloor, mceil, sqrt, min, max = math.abs, math.floor, math.ceil, math.sqrt, math.min, math.max

local table_insert, table_remove, table_sort = table.insert, table.remove, table.sort

---@enum JM.Physics.BodyTypes
local BodyTypes = {
    dynamic = 1,
    static = 2,
    kinematic = 3,
    ghost = 4
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

---@alias JM.Physics.Collisions {items: table,n:number, top:number, left:number, right:number, bottom:number, most_left:JM.Physics.Body, most_right:JM.Physics.Body, most_up:JM.Physics.Body, most_bottom:JM.Physics.Body, diff_x:number, diff_y:number, end_x: number, end_y: number}

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

local function dynamic_filter(obj, item)
    return is_dynamic(item)
end

local function colliders_filter(obj, item)
    return not is_dynamic(item)
end

local default_filter = function(body, item)
    return true
end

---@param kbody JM.Physics.Body
local function kinematic_moves_dynamic_x(kbody, goalx)

    local col = kbody:check2(goalx, nil,
        dynamic_filter,
        nil, kbody.y - 1, nil, kbody.h + 2
    )

    if col.n > 0 then
        for i = 1, col.n do
            local bd

            ---@type JM.Physics.Body
            bd = col.items[i]

            bd:refresh(bd.x + col.diff_x)

            local col_bd

            col_bd = bd:check(nil, nil, colliders_filter)

            if col_bd.n > 0 then
                if col.diff_x < 0 then
                    bd:refresh(col_bd.right + 0.1)
                else
                    bd:refresh(col_bd.left - bd.w - 0.1)
                end

                local col_f = bd:check(nil, nil, colliders_filter)

                -- bd.is_stucked = nn > 0
                -- bd.is_stucked = true
            end

            bd, col_bd = nil, nil
        end
    end

end

---@param kbody JM.Physics.Body
local function kinematic_moves_dynamic_y(kbody, goaly)
    local col = kbody:check2(nil, goaly - 1,
        dynamic_filter,
        nil, kbody.y - 1, nil, kbody.h + 2
    )

    if col.n > 0 then
        for i = 1, col.n do
            local bd

            ---@type JM.Physics.Body
            bd = col.items[i]

            bd:refresh(nil, bd.y + col.diff_y)

            local col_bd
            col_bd = bd:check(nil, nil, function(obj, item)
                return item ~= kbody and colliders_filter(obj, item)
            end)

            if col_bd.n > 0 then
                if col.diff_y > 0 then
                    bd:refresh(nil, col_bd.top - bd.h - 0.1)
                end
            end

            bd = nil
            col_bd = nil
        end
    end

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

        self.acc_x = 0
        self.acc_y = 0
        self.acc_y = (self.type ~= BodyTypes.dynamic and 0) or self.acc_y

        self.dacc_x = self.world.meter * 3.5
        self.dacc_y = nil
        self.over_speed_dacc_x = self.dacc_x
        self.over_speed_dacc_y = self.dacc_x

        self.force_x = 0
        self.force_y = 0

        -- used if body is static or kinematic
        self.resistance_x = 1

        ---@type JM.Physics.Body
        self.ground = nil -- used if body is not static

        -- some properties
        self.bouncing_y = nil -- need to be a number between 0 and 1
        self.bouncing_x = nil
        self.__remove = nil
        self.is_stucked = nil

        self.allowed_air_dacc = false

        self.shape = BodyShapes.rectangle

        -- TODO
        self.hit_box = nil

        self:extra_collisor_filter(default_filter)
    end

    function Body:remove_extra_filter()
        self:extra_collisor_filter(default_filter)
    end

    function Body:check_collision(obj)
        return collision_rect(self.x, self.y, self.w, self.h,
            obj.x, obj.y, obj.w, obj.h)
    end

    function Body:set_mass(mass)
        self.mass = mass
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

    function Body:extra_collisor_filter(filter)
        self.extra_filter = filter
    end

    function Body:jump(desired_height)
        if self.speed_y ~= 0 then return end

        self.ground = nil

        local acc_y = self:weight() + self.acc_y

        self.speed_y = -sqrt(2 * acc_y * desired_height)
    end

    function Body:weight()
        return self.world.gravity * (self.mass / self.world.default_mass)
    end

    function Body:on_ground_collision(action)
        self.on_ground_coll_action = action
    end

    function Body:on_wall_collision(action)
        self.on_wall_coll_action = action
    end

    function Body:on_ceil_collision(action)
        self.on_ceil_coll_action = action
    end

    function Body:on_starting_falling(action)
        self.start_falling_action = action
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

    ---@param body JM.Physics.Body
    ---@param item JM.Physics.Body
    local function collider_condition(body, item, diff_x, diff_y)
        diff_x = diff_x or 0
        diff_y = diff_y or 0

        local cond_y = (diff_y ~= 0
            and (body:right() > item.x and body.x < item:right()))

        local cond_x = (diff_x ~= 0
            and (body:bottom() > item.y and body.y < item:bottom()))

        return (cond_x or cond_y) or (diff_x == 0 and diff_y == 0)
    end

    ---@return JM.Physics.Collisions collisions
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

        ---@type JM.Physics.Collisions
        local collisions = {}

        local col_items = {}
        local n_collisions = 0
        local most_left, most_right
        local most_up, most_bottom

        for item, _ in pairs(items) do
            ---@type JM.Physics.Body
            local item = item

            -- local cond_y = (diff_y ~= 0
            --     and (self:right() > item.x and self.x < item:right()))

            -- local cond_x = (diff_x ~= 0
            --     and (bottom >= item.y and top <= item:bottom()))

            if item ~= self and not item.__remove and not item.is_stucked

                and item.type ~= BodyTypes.ghost

                -- and (cond_y or cond_x or (diff_x == 0 and diff_y == 0))

                and collision_rect(
                    x, y, w, h,
                    item.x, item.y, item.w, item.h
                )

                and filter(self, item)

                and self.extra_filter(self, item)
            then
                table_insert(col_items, item)

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

        collisions.items = col_items

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

        collisions.end_x = (diff_x >= 0 and most_left and most_left.x - self.w)
            or (diff_x < 0 and most_right and most_right:right()) or goal_x

        collisions.end_y = (diff_y >= 0 and most_up and most_up.y - self.h - 0.1)
            or (diff_y < 0 and most_bottom and most_bottom:bottom() + 0.1) or goal_y

        collisions.n = n_collisions

        return collisions
    end

    ---@return JM.Physics.Collisions
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

    ---@param acc_x number|nil
    ---@param acc_y number|nil
    ---@param body JM.Physics.Body|nil
    function Body:apply_force(acc_x, acc_y, body)
        self.force_x = self.force_x + ((acc_x or 0) * self.mass)
        self.force_y = self.force_y + ((acc_y or 0) * self.mass)

        self.acc_x = acc_x and (self.force_x / self.mass) or self.acc_x
        self.acc_y = acc_y and (self.force_y / self.mass) or self.acc_y
    end

    function Body:resolve_collisions_y(col)
        if col.n > 0 then -- collision!

            self:refresh(nil, col.end_y)

            if col.diff_y >= 0 then -- body hit the floor/ground

                local r = self.on_ground_coll_action and not self.ground
                    and self.on_ground_coll_action(col)

                self.ground = col.most_up

                if self.bouncing_y then
                    self.speed_y = -self.speed_y * self.bouncing_y
                    if abs(self.speed_y) <= sqrt(2 * self.acc_y * 2) then
                        self.speed_y = 0
                    end
                else
                    self.speed_y = 0
                end

            else -- body hit the ceil

                local r = self.on_ceil_coll_action and not self.ceil
                    and self.on_ceil_coll_action(col)

                self.ceil = col.most_bottom

                self.speed_y = 0
            end
        end
    end

    function Body:update(dt)
        local obj
        obj = self

        if is_dynamic(obj) or is_kinematic(obj) then
            local goalx, goaly

            -- applying the gravity
            obj:apply_force(nil, obj:weight())

            -- falling
            if (obj.acc_y ~= 0) or (obj.speed_y ~= 0) then
                local last_sy = obj.speed_y

                goaly = obj.y + (obj.speed_y * dt)
                    + (obj.acc_y * dt * dt) / 2

                if obj.speed_y == 0 then
                    obj.speed_y = sqrt(2 * obj.acc_y * 1)
                end

                -- speed up with acceleration
                obj.speed_y = obj.speed_y + obj.acc_y * dt

                if self.max_speed_y and obj.speed_y > self.max_speed_y then
                    obj.speed_y = self.max_speed_y
                end

                ---@type JM.Physics.Collisions
                local col = obj:check(nil, goaly, colliders_filter)

                if col.n > 0 then -- collision!

                    obj:resolve_collisions_y(col)

                else
                    obj.ground = nil
                    obj.ceil = nil

                    if is_kinematic(obj) then
                        kinematic_moves_dynamic_y(obj, goaly)
                    end

                    obj:refresh(nil, goaly)
                end

                if last_sy <= 0 and obj.speed_y > 0 then
                    local r = obj.start_falling_action
                        and obj.start_falling_action()
                end
            end

            -- moving in x axis
            if (obj.acc_x ~= 0) or (obj.speed_x ~= 0) then
                local last_sx = obj.speed_x

                goalx = obj.x + (obj.speed_x * dt)
                    + (obj.acc_x * dt * dt) / 2

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

                --- will store the body collisions with other bodies
                local col

                ---@type JM.Physics.Collisions
                col = obj:check(goalx, nil, colliders_filter)

                if col.n > 0 then -- had collision!

                    self:refresh(col.end_x)

                    local r = self.on_wall_coll_action
                        and self.on_wall_coll_action(col)

                    if self.bouncing_x then
                        self.speed_x = -self.speed_x * self.bouncing_x
                    else
                        self.speed_x = 0
                    end

                else -- no collisions

                    if is_kinematic(obj) then
                        kinematic_moves_dynamic_x(obj, goalx)
                    end

                    obj:refresh(goalx)
                end

                col = nil

                -- simulating the ground resistence (friction)
                if obj.speed_x ~= 0
                    and (obj.ground or obj.allowed_air_dacc)
                then
                    local dacc = obj.dacc_x
                    obj:apply_force(dacc * -obj:direction_x())
                end

            end -- end moving in x axis

            obj.force_x = 0
            obj.force_y = 0

        end --end if body is dynamic

        obj = nil
    end

    -- -- Update 2
    -- do
    --     function Body:update2(dt)
    --         local obj
    --         obj = self

    --         if is_dynamic(obj) or is_kinematic(obj) then
    --             local goalx, goaly = obj.x, obj.y

    --             -- applying the gravity
    --             obj:apply_force(nil, obj:weight())

    --             if (obj.acc_x ~= 0) or (obj.speed_x ~= 0) then
    --                 local last_sx = obj.speed_x

    --                 obj.speed_x = obj.speed_x + obj.acc_x * dt

    --                 -- if obj.speed_x == 0 then
    --                 --     obj.speed_x = 0.0001
    --                 -- end

    --                 -- if reach max speed
    --                 if obj.max_speed_x
    --                     and abs(obj.speed_x) > obj.max_speed_x
    --                 then
    --                     obj.speed_x = obj.max_speed_x
    --                         * obj:direction_x()
    --                 end

    --                 -- dacc
    --                 if (obj.acc_x > 0 and last_sx < 0 and obj.speed_x >= 0)
    --                     or (obj.acc_x < 0 and last_sx > 0 and obj.speed_x <= 0)
    --                 then
    --                     obj.speed_x = 0
    --                     obj.acc_x = 0
    --                 end

    --                 goalx = obj.x + (obj.speed_x * dt)
    --                     + (obj.acc_x * dt * dt) / 2
    --             end

    --             if (obj.acc_y ~= 0) or (obj.speed_y ~= 0) then
    --                 goaly = obj.y + (obj.speed_y * dt)
    --                     + (obj.acc_y * dt * dt) / 2

    --                 if obj.speed_y == 0 then
    --                     obj.speed_y = sqrt(2 * obj.acc_y * 1)
    --                 end

    --                 -- speed up with acceleration
    --                 obj.speed_y = obj.speed_y + obj.acc_y * dt

    --                 if self.max_speed_y and obj.speed_y > self.max_speed_y then
    --                     obj.speed_y = self.max_speed_y
    --                 end
    --             end

    --             ---@type JM.Physics.Collisions
    --             local col = obj:check(goalx, nil, colliders_filter)

    --             if col.n > 0 then
    --                 obj:refresh(col.end_x, col.end_y)

    --                 --
    --                 if col.diff_y > 0 and obj:bottom() == col.top then
    --                     obj.ground = col.most_up

    --                     local r = obj.on_ground_coll_action
    --                         and obj.on_ground_coll_action(obj)

    --                     if self.bouncing_y then
    --                         self.speed_y = -self.speed_y * self.bouncing_y
    --                         if abs(self.speed_y) <= sqrt(2 * self.acc_y * 2) then
    --                             self.speed_y = 0
    --                         end
    --                     else
    --                         self.speed_y = 0
    --                     end
    --                 else
    --                     obj.ground = nil
    --                 end

    --                 --
    --                 if col.diff_y < 0 and obj:top() == col.bottom then
    --                     obj.ceil = col.most_bottom

    --                     local r = self.on_ceil_coll_action
    --                         and self.on_ceil_coll_action()

    --                     obj.speed_y = 0
    --                 else
    --                     obj.ceil = nil
    --                 end

    --                 if col.diff_x > 0 and obj:right() == col.left
    --                     or col.diff_x < 0 and obj:left() == col.right
    --                 then
    --                     obj.speed_x = 0
    --                 end
    --             else
    --                 obj:refresh(goalx, goaly)
    --             end

    --             -- simulating the ground resistence (friction)
    --             if obj.speed_x ~= 0
    --                 and (obj.ground or obj.allowed_air_dacc)
    --             then
    --                 local dacc = obj.dacc_x
    --                 obj:apply_force(dacc * -obj:direction_x())
    --             end

    --             obj.force_x = 0
    --             obj.force_y = 0
    --         end
    --         obj = nil
    --     end
    -- end
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
        table_insert(self.bodies, obj)
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
        local r = table_remove(self.bodies, index)

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

            if obj then
                obj:update(dt)
            end

            obj = nil

            ::end_for_world_bodies::
        end
    end

    -- ---@param obj JM.Physics.Body
    -- function World:check(obj)
    --     -- local cl, ct, cw, ch = self:rect_to_cell(obj:rect())
    --     local items = self:get_items_in_cell_obj(obj:rect())

    --     for item, _ in pairs(items) do
    --         if item ~= obj and not item.__remove and obj:check_collision(item) then
    --             return item
    --         end
    --     end
    -- end

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
    -- local bd_type = (type_ == "dynamic" and BodyTypes.dynamic)
    --     or (type_ == "kinematic" and BodyTypes.kinematic)
    --     or BodyTypes.static

    local bd_type = BodyTypes[type_] or BodyTypes.static

    local b = Body:new(x, y, w, h, bd_type, world)

    world:add(b)

    return b
end

return Phys
