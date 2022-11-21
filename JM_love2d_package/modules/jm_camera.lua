local function round(value)
    local absolute = math.abs(value)
    local decimal = absolute - math.floor(absolute)

    if decimal >= 0.5 then
        return value > 0 and math.ceil(value) or math.floor(value)
    else
        return value > 0 and math.floor(value) or math.ceil(value)
    end
end

local love_translate = love.graphics.translate
local love_pop = love.graphics.pop
local love_push = love.graphics.push
local love_scale = love.graphics.scale
local sin, cos, atan2, sqrt, abs = math.sin, math.cos, math.atan2, math.sqrt, math.abs

---@enum JM.Camera.Type
local CAMERA_TYPES = {
    platform = 1,
    metroidvania = 2,
    top_view = 3
}

---@enum JM.Camera.TypeMovements
local MOVEMENTS_TYPES = {
    dynamic = 1, -- offset can change
    fixed = 2 -- fixed offset
}

---@class JM.Camera.Camera
local Camera = {}

---@return JM.Camera.Camera
function Camera:new(x, y, w, h, scale)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Camera.__constructor__(obj, x, y, w, h, scale)

    return obj
end

function Camera:__constructor__(x, y, w, h, scale)

    self.viewport_x = 0
    self.viewport_y = 0
    self.viewport_w = w or love.graphics.getWidth()
    self.viewport_h = h or love.graphics.getHeight()

    self.x = x or 0
    self.y = y or 0

    self.scale = 1
    self.angle = 0

    self.type = CAMERA_TYPES.top_view
    self.type_vertical_move = MOVEMENTS_TYPES.dynamic
    self.type_horizontal_move = MOVEMENTS_TYPES.fixed
    self:set_type("top view")

    ---@type {x:number, y:number, angle_x:number, angle_y:number, distance:number, range_x:number, range_y:number, last_x:number, last_y:number, direction_x:number, direction_y:number, last_direction_x:number, last_direction_y:number}|nil
    self.target = nil

    self.offset_x = 0
    self.offset_y = self.viewport_h * 0.5

    self.deadzone_w = 32 * 1.5
    self.deadzone_h = 32 * 1.5

    self.bounds_left = 0 ---32 * 6
    self.bounds_top = -32 * 8
    self.bounds_right = self.viewport_w + 32 * 10 --32 * 60
    self.bounds_bottom = self.viewport_h --+ 32 * 8
    self:set_bounds()

    self.follow_speed_x = (32 * 8)
    self.follow_acc = 32 * 3

    self.delay_x = 1
    self.delay_y = 0.2

    self.lock_x = false
    self.lock_y = false

    self.debug = true
end

function Camera:set_type(s)
    if s == "platform" then
        self.type = CAMERA_TYPES.platform
        self.type_horizontal_move = MOVEMENTS_TYPES.dynamic
        self.type_vertical_move = MOVEMENTS_TYPES.fixed
    elseif s == "top view" then
        self.type = CAMERA_TYPES.top_view
        self.type_horizontal_move = MOVEMENTS_TYPES.dynamic
        self.type_vertical_move = MOVEMENTS_TYPES.dynamic
    end
end

function Camera:set_viewport(x, y, w, h)
    self.viewport_x = x
    self.viewport_y = y
    self.viewport_w = w
    self.viewport_h = h
end

function Camera:to_camera(x, y)
    y = y or 0
    x = x or 0
    x = x / self.scale
    y = y / self.scale
    return x + self.x, y + self.y
end

function Camera:to_screen(x, y)
    y = y or 0
    x = x or 0
    x = x - self.x
    y = y - self.y

    return x * self.scale, y * self.scale
end

function Camera:__y_to_camera(y)
    local x
    x, y = self:to_camera(x, y)
    return y
end

function Camera:__x_to_camera(x)
    local y
    x, y = self:to_camera(x, y)
    return x
end

function Camera:__y_to_screen(y)
    local x
    x, y = self:to_screen(x, y)
    return y
end

function Camera:__x_to_screen(x)
    local y
    x, y = self:to_screen(x, y)
    return x
end

function Camera:lock_x_axis(value)
    self.lock_x = (value and true) or false
end

function Camera:lock_y_axis(value)
    self.lock_y = (value and true) or false
end

function Camera:lock_movements()
    self:lock_x_axis(true)
    self:lock_y_axis(true)
end

function Camera:unlock_movements()
    self:lock_x_axis(false)
    self:lock_y_axis(false)
end

function Camera:type_vertical()
    return self.type_vertical_move
end

function Camera:type_horizontal()
    return self.type_horizontal_move
end

function Camera:follow(x, y)
    if not self.target then self.target = {} end
    local target = self.target or {}

    x = x - self.offset_x / self.scale
    y = y - self.offset_y / self.scale

    target.last_x = target.x or x
    target.last_y = target.y or y

    target.x = x
    target.y = y

    target.range_x = (x - target.last_x)
    target.range_y = (y - target.last_y)

    target.last_direction_x = target.direction_x ~= 0 and target.direction_x
        or target.last_direction_x or 1
    target.last_direction_y = target.direction_y ~= 0 and target.direction_y
        or target.last_direction_y or 1

    target.direction_x = (target.range_x > 0 and 1)
        or (target.range_x < 0 and -1)
        or 0
    target.direction_y = (target.range_y > 0 and 1)
        or (target.range_y < 0 and -1)
        or 0

    -- local cx = self:to_camera(self.x)
    -- local bl = self:to_camera(self.bounds_left)
    -- local br = self:to_camera(self.bounds_right - self.viewport_w / self.scale)
    -- local can_move_left = (cx > bl and target.direction_x > 0)
    -- local can_move_right = not can_move_left and (cx < br and target.direction_x <= 0)

    local target_distance_x = target.x - self.x
    local target_distance_y = target.y - self.y

    target.distance = sqrt(
        target_distance_x ^ 2 + target_distance_y ^ 2
    )


    target.angle_x = atan2(
        self:type_horizontal() == 5 and 0
        or target_distance_y,
        target_distance_x
    )

    target.angle_y = atan2(
        target_distance_y,
        self:type_vertical() == 5 and 0
        or target_distance_x
    )
end

function Camera:set_offset_x(value)
    value = round(value)
    if self.offset_x ~= value then
        if self.target then self.target.x = nil end
        self.offset_x = value
    end
end

function Camera:set_offset_y(value)
    value = round(value)
    if self.offset_y ~= value then
        if self.target then self.target.y = nil end
        self.offset_y = value
    end
end

function Camera:set_position(x, y)
    self.x = (not self.lock_x and (x and x)) or self.x
    self.y = (not self.lock_y and (y and y)) or self.y
    self.x = round(self.x)
    self.y = round(self.y)
end

function Camera:look_at(x, y)
    self:set_position(
        x - self.offset_x / self.scale,
        y - self.offset_y / self.scale
    )
end

function Camera:move(dx, dy)
    self:set_position(
        dx and self.x + dx or self.x,
        dy and self.y + dy or self.y
    )
end

function Camera:set_bounds(left, right, top, bottom)
    self.bounds_left = (left and left) or self.bounds_left
    self.bounds_right = (right and right) or self.bounds_right
    self.bounds_top = (top and top) or self.bounds_top
    self.bounds_bottom = (bottom and bottom) or self.bounds_bottom

    if self.bounds_right - self.bounds_left < self.viewport_w then
        self.bounds_right = self.bounds_left + self.viewport_w
    end

    if self.bounds_bottom - self.bounds_top < self.viewport_h then
        self.bounds_bottom = self.bounds_top + self.viewport_h
    end
end

function Camera:rect_is_on_screen(left, right, top, bottom)
    local left, top = self:to_camera(left, top)
    local right, bottom = self:to_camera(right, bottom)

    local cLeft, ctop = self:to_camera(self.x, self.y)
    local cright, cbottom = self:to_camera(
        self.x + (self.viewport_w / self.scale),
        self.y + self.viewport_h / self.scale
    )

    return (right >= cLeft and left <= cright)
        and (bottom >= ctop and top <= cbottom)
end

function Camera:point_is_on_screen(x, y)
    return self:rect_is_on_screen(x, x, y, y)
end

--- Moves the camera position until reaches the target position.
---@param camera JM.Camera.Camera
local function chase_target(camera, dt, chase_x_axis, chase_y_axis)
    local self = camera
    local obj_x, obj_y = not chase_x_axis, not chase_y_axis

    if self.target then
        local target = self.target or {}

        if chase_x_axis and self.x ~= target.x then
            local cos_r = cos(target.angle_x)

            if self.y <= self.bounds_top
                or self.y >= self.bounds_bottom - self.viewport_h / self.scale
            then
                cos_r = cos_r / abs(cos_r)
            end

            self:move(self.follow_speed_x * dt * cos_r)

            self:move(abs(target.range_x) * cos_r * self.delay_x)

            if (cos_r > 0 and self.x > target.x)
                or (cos_r < 0 and self.x < target.x)
            then
                self:set_position(target.x)
            end

            obj_x = self.x == target.x
        end

        if chase_y_axis and self.y ~= target.y then
            local sin_r = sin(target.angle_y)

            if self.x <= self.bounds_left
                or self.x >= self.bounds_right - self.viewport_w / self.scale
            then
                sin_r = sin_r / abs(sin_r)
            end

            self:move(nil, self.follow_speed_x * dt * sin_r)

            self:move(nil, abs(target.range_y) * sin_r * self.delay_y)

            if (sin_r > 0 and self.y > target.y)
                or (sin_r < 0 and self.y < target.y)
            then
                self:set_position(nil, target.y)
            end

            obj_y = self.y == target.y
        end

    end

    return obj_x and obj_y
    -- local px = self:to_camera(32 * 20)
    -- if self:to_camera(self.x + self.offset_x) > px then
    --     self:set_position(self:to_screen(px - self.offset_x))
    --     self:lock_movements()
    -- end
end

function Camera:is_locked_in_x()
    return self.lock_x
end

function Camera:is_locked_in_y()
    return self.lock_y
end

---@param self JM.Camera.Camera
local function dynamic_x_axis_logic(self, dt)
    if not self.target then return end

    local target = self.target or {}
    local deadzone_w = self.deadzone_w / self.scale
    local left_focus = self.viewport_w * 0.7
    local right_focus = self.viewport_w * 0.3

    local move_left_offset = left_focus > right_focus and left_focus or right_focus
    local move_right_offset = move_left_offset == right_focus and left_focus or right_focus

    if not self:is_locked_in_x() then
        local objective = chase_target(self, dt, true)

        self:lock_x_axis(objective
            and target.direction_x ~= target.last_direction_x
        )
    else
        if self.target.direction_x > 0 then
            local right = self.x + deadzone_w / 2
            right = self:to_camera(right)

            if self:to_camera(self.target.x) > right then
                self:lock_x_axis(false)
            end
        elseif self.target.direction_x < 0 then
            local left = self.x - deadzone_w / 2
            left = self:to_camera(left)

            if self:to_camera(self.target.x) < left then
                self:lock_x_axis(false)
            end
        end
    end

    if self.target.direction_x < 0 and not self.lock_x then
        self:set_offset_x(move_left_offset)
    elseif self.target.direction_x > 0 and not self.lock_x then
        self:set_offset_x(move_right_offset)
    end
end

---@param self JM.Camera.Camera
local function dynamic_y_axis_logic(self, dt)
    if not self.target then return end

    local target = self.target or {}
    local deadzone_h = self.deadzone_h / self.scale
    local top_focus = self.viewport_h * 0.3
    local bottom_focus = self.viewport_h * 0.2

    local move_up = top_focus > bottom_focus and top_focus or bottom_focus
    local move_down = move_up == top_focus and bottom_focus or top_focus

    if not self:is_locked_in_y() then
        local objective = chase_target(self, dt, false, true)

        self:lock_y_axis(objective
            and target.direction_y ~= target.last_direction_y
        )
    else
        -- target is going down
        if self.target.direction_y > 0 then
            local bottom = self.y + deadzone_h / 2
            bottom = self:__y_to_camera(bottom)

            local cy = self:__y_to_camera(self.target.y)
            if cy > bottom then
                self:lock_y_axis(false)
            end

        elseif self.target.direction_y < 0 then
            local top = self.y - deadzone_h / 2
            top = self:__y_to_camera(top)

            if self:__y_to_camera(self.target.y) < top then
                self:lock_y_axis(false)
            end
        end
    end

    if self.target.direction_y < 0 and not self.lock_y then
        self:set_offset_y(move_up)
    elseif self.target.direction_y > 0 and not self.lock_y then
        self:set_offset_y(move_down)
    end
end

-- dynamic_y_axis_logic({})


---@param self JM.Camera.Camera
local function platformer_update(self, dt)
    if not self.target then return end

    self.follow_speed_x = 32 * 6
    self.delay_x = 1
    self.delay_y = 1

    -- dynamic_y_axis_logic(self, dt)
    dynamic_x_axis_logic(self, dt)

    if self.target.direction_y == 0 then
        chase_target(self, dt, nil, true)
    end
end

---@param self JM.Camera.Camera
local function metroidvania_update(self, dt)
    if self.target then
        self.offset_x = self.viewport_w * 0.5
        self:set_position(self.target.x)
    end
end

function Camera:update(dt)
    platformer_update(self, dt)

    local left, top = self:to_camera(self.bounds_left, self.bounds_top)
    local right, bottom = self:to_camera(
        self.bounds_right - self.viewport_w / self.scale,
        self.bounds_bottom - self.viewport_h / self.scale
    )
    local px, py = self:to_camera(self.x, self.y)

    local lock = self.lock_x
    if px < left then
        local x = self:to_screen(left)
        self:lock_x_axis(false)
        self:set_position(x)
        self:lock_x_axis(lock)
    elseif px > right then
        local x = self:to_screen(right)
        self:lock_x_axis(false)
        self:set_position(x)
        self:lock_x_axis(lock)
    end

    lock = self.lock_y
    if py < top then
        local y = self:__y_to_screen(top)
        self:lock_y_axis(false)
        self:set_position(nil, y)
        self:lock_y_axis(lock)
    elseif py > bottom then
        local y = self:__y_to_screen(bottom)
        self:lock_y_axis(false)
        self:set_position(nil, y)
        self:lock_y_axis(lock)
    end
end

function Camera:attach()
    love_push()
    love_scale(self.scale, self.scale)
    love_translate(-self.x, -self.y)
end

local function rad2degr(value)
    return value * 180 / math.pi
end

local function deg2rad(value)
    return value * math.pi / 180
end

function Camera:detach()
    love_pop()

    if not self.debug then return end

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Scale: " .. tostring(self.scale), self.viewport_w - 100)
    love.graphics.print("Cam_X: " .. tostring(self.x), self.viewport_w - 100, 25)
    do
        if self.target then
            love.graphics.print(tostring(math.cos(self.target.angle_y)), 100, 200)
            love.graphics.print("distance: " .. tostring(self.target.distance), 10, 75)
            love.graphics.print("angle: " .. tostring(self.target.angle_y), 10, 95)
            love.graphics.print("angle deg: " .. tostring(rad2degr(self.target.angle_y)), 10, 110)
            love.graphics.print("t_speed_x: " .. tostring(self.target.range_x), 10, 125)
            love.graphics.print("target_dir: " .. tostring(self.target.direction_y), self.viewport_w - 100, 50)
            love.graphics.print("last_dir: " .. tostring(self.target.last_direction_y), self.viewport_w - 100, 75)
        end
    end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", self.offset_x, 0, 2, self.viewport_h)
    love.graphics.rectangle("fill", 0, self.offset_y, self.viewport_w, 2)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", self.offset_x + self.deadzone_w / 2, 0, 2, self.viewport_h)
    love.graphics.rectangle("fill", self.offset_x - self.deadzone_w / 2, 0, 2, self.viewport_h)
    love.graphics.rectangle("fill", 0, self.offset_y - self.deadzone_h / 2, self.viewport_w, 2)
    love.graphics.rectangle("fill", 0, self.offset_y + self.deadzone_h / 2, self.viewport_w, 2)
end

return Camera
