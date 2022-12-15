--[[ Lua module for animation in LÖVE 2D.

    Copyright (c) 2022, Joao Moreira.
]]
local path = (...)

local Affectable = require("/JM_love2d_package/modules/templates/Affectable")

-- Some local variables to store global modules.
local love_graphics = love.graphics
local love_graphics_draw = love_graphics.draw
local love_graphics_rectangle = love_graphics.rectangle
local love_graphics_set_color = love_graphics.setColor
local love_graphics_push = love_graphics.push
local love_graphics_pop = love_graphics.pop
local love_graphics_apply_transform = love_graphics.applyTransform
local love_math_new_transform = love.math.newTransform


---@param width number|nil
---@param height number|nil
---@param ref_width number|nil
---@param ref_height number|nil
---@return JM.Point
local function desired_size(width, height, ref_width, ref_height, keep_proportions)
    local dw, dh

    dw = width and width / ref_width or nil
    dh = height and height / ref_height or nil

    if keep_proportions then
        if not dw then
            dw = dh
        elseif not dh then
            dh = dw
        end
    end

    return { x = dw, y = dh }
end

--===========================================================================

---@class JM.Anima.Frame
--- Internal class Frame.
local Frame = {}
do
    ---@param args {left: number, right:number, top:number, bottom:number, speed:number}
    function Frame:new(args)
        local obj = {}
        setmetatable(obj, self)
        self.__index = self

        Frame.__constructor__(obj, args)

        return obj
    end

    --- Constructor.
    function Frame:__constructor__(args)
        local left = args.left or args[1]
        local top = args.top or args[3]
        local right = args.right or args[2]
        local bottom = args.bottom or args[4]

        self.x = left
        self.y = top
        self.w = right - left
        self.h = bottom - top
        self.ox = self.w / 2
        self.oy = self.h / 2

        self.speed = args.speed or nil

        self.bottom = self.y + self.h
    end

    function Frame:get_offset()
        return self.ox, self.oy
    end

    function Frame:set_offset(ox, oy)
        self.ox = ox or self.ox
        self.oy = oy or self.oy
    end

    --- Sets the Quad Viewport.
    ---@param img love.Image
    ---@param quad love.Quad
    function Frame:setViewport(img, quad)
        quad:setViewport(
            self.x, self.y,
            self.w, self.h,
            img:getWidth(), img:getHeight()
        )
    end

end
--===========================================================================


-- Class to animate.
--- @class JM.Anima: JM.Affectable
--- @field __configuration {scale: JM.Point, color: JM.Color, direction: -1|1, rotation: number, speed: number, flip: table, kx: number, ky: number, current_frame: number}
local Anima = {}

---@enum AnimaStates
local ANIMA_STATES = {
    looping = 1,
    back_and_forth = 2,
    random = 3,
    repeating_last_n_frames = 4
}

---
--- Animation class constructor.
---
--- @param args {img: love.Image|string, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number, n: number}  # A table containing the following fields:
-- * img (Required): The source image for animation (could be a Love.Image or a string containing the file path). All the frames in the source image should be in the horizontal.
-- * frames: The amount of frames in the animation.
-- * speed: Time in seconds to update frame.
--- @return JM.Anima animation # A instance of Anima class.
function Anima:new(args)
    assert(args, "\nError: Trying to instance a Animation without inform any parameter.")

    ---@type JM.Anima
    local animation = {}
    setmetatable(animation, self)
    self.__index = self

    Anima.__constructor__(animation, args)

    return animation
end

---
--- Internal method for constructor.
---
--- @param args {img: love.Image|string, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number, n: number}  # A table containing the follow fields:
---
function Anima:__constructor__(args)
    local success, result = pcall(function(...)
        --- trying load the EffectManager Module
        return require("/JM_love2d_package/modules/classes/EffectManager")
    end)

    local EffectManager = success and result or nil

    self.args = args

    self:set_img(args.img)

    self.__amount_frames = (args.frames_list and #args.frames_list) or (args.frames) or 1

    self.time_frame = 0
    self.time_update = 0
    self.time_paused = 0
    self.cycle_count = 0
    self.__is_visible = true
    self.__is_enabled = true
    self.initial_direction = nil

    self:set_reverse_mode(args.is_reversed)

    self:set_color(args.color or { 1, 1, 1, 1 })

    self.rotation = args.rotation or 0
    self.speed = args.speed or 0.3
    self.__stop_at_the_end = args.stop_at_the_end or false
    self.max_cycle = args.amount_cycle or nil
    if args.duration then self:set_duration(args.duration) end

    self.current_frame = (self.direction < 0 and self.__amount_frames) or 1

    self:set_state(args.state)

    self.__N__ = args.n or 0

    self.flip_x = 1
    self.flip_y = 1

    self.scale_x = 1
    self.scale_y = 1
    self:set_scale(args.scale and args.scale.x, args.scale and args.scale.y)

    self.__effect_manager = EffectManager and EffectManager:new() or nil

    self.frames_list = {}

    if not args.frames_list then
        args.frames_list = {}
        local w = self.__img:getWidth() / self.__amount_frames
        for i = 1, self.__amount_frames do
            table.insert(args.frames_list, {
                (i - 1) * w,
                (i - 1) * w + w,
                0,
                args.bottom or self.__img:getHeight()
            })
        end
    end


    -- Generating the Frame objects and inserting them into the frames_list
    for i = 1, #args.frames_list do
        self.frames_list[i] = Frame:new(args.frames_list[i])
    end -- END FOR for generate frames objects


    if args.width or args.height then
        self:set_size(args.width, args.height, args.ref_width, args.ref_height)
    end

    self.quad = love.graphics.newQuad(0, 0,
        args.frames_list[1][1],
        args.frames_list[1][2],
        self.__img:getDimensions()
    )

    -- Affectable.__checks_implementation__(self)
end

function Anima:copy()
    return Anima:new(self.args)
end

--- Sets the size in pixels to draw the frame.
---@param width number|nil
---@param height number|nil
---@param ref_width number|nil
---@param ref_height number|nil
function Anima:set_size(width, height, ref_width, ref_height)
    if width or height then
        local current_frame = self:__get_current_frame()
        local tt = {
            w = ref_width or current_frame.w,
            h = ref_height or current_frame.h
        }

        local desired_size_in_pxl = desired_size(
            width, height, tt.w, tt.h, true
        )

        if desired_size_in_pxl then
            self:set_scale(desired_size_in_pxl.x, desired_size_in_pxl.y)
        end
    end
end

---@param value number
function Anima:set_speed(value)
    assert(value >= 0, "\nError: Value passed to 'set_speed' method is smaller than zero.")

    self.speed = value
end

---@param duration number
function Anima:set_duration(duration)
    assert(duration > 0, "\nError: Value passed to 'set_duration' method is smaller than zero.")

    self.speed = duration / self.__amount_frames
end

---@param value boolean
function Anima:set_reverse_mode(value)
    self.direction = value and -1 or 1
end

---@param value boolean
---@param stop_action function
function Anima:stop_at_the_end(value, stop_action)
    self.__stop_at_the_end = value and true or false

    if value then
        self:set_stop_action(stop_action)
    end
end

---
--- Set the source image for animation.
--
---@overload fun(self: table, image: love.Image)
---@param file_name string # The file path for source image.
function Anima:set_img(file_name)
    if type(file_name) == "string" then
        self.__img = love.graphics.newImage(file_name)
    else
        self.__img = file_name
    end
    self.__img:setFilter("linear", "nearest")
    return self.__img
end

---
function Anima:set_flip_x(flip)
    self.flip_x = flip and -1 or 1
end

---
function Anima:set_flip_y(flip)
    self.flip_y = flip and -1 or 1
end

function Anima:toggle_flip_x()
    self.flip_x = self.flip_x * (-1)
end

function Anima:toggle_flip_y()
    self.flip_y = self.flip_y * (-1)
end

---@param x number|nil
---@param y number|nil
function Anima:set_scale(x, y)
    if not x and not y then return end

    self.scale_x = x or self.scale_x
    self.scale_y = y or self.scale_y
end

function Anima:get_scale()
    return self.scale_x, self.scale_y
end

--- Sets Animation rotation in radians.
---@param value number
function Anima:set_rotation(value)
    self.rotation = value
end

--- Gets Animation current rotation in radians.
---@return number
function Anima:get_rotation()
    return self.rotation
end

--- Gets the animation color field.
---@return table
function Anima:get_color()
    return self.__color
end

---
--- Set animation color.
---@overload fun(self: JM.Anima, value: {[1]: number, [2]: number, [3]: number, [4]: number})
---@param value {r: number, g: number, b: number, a: number}
function Anima:set_color(value)
    self.__color = Affectable.set_color(self, value)
end

function Anima:get_offset()
    local cf = self:__get_current_frame()
    return cf:get_offset()
end

function Anima:set_kx(value)
    self.__kx = value
end

function Anima:set_ky(value)
    self.__ky = value
end

---
--- Different animation states.
---
---@alias JM.AnimaStates
---|"looping" # (default) when animation reaches the last frame, the current frame is set to beginning.
---|"random" # animation shows his frames in a aleatory order.
---|"back and forth" # when animation reaches the last frame, the direction of animation changes.
---|"repeat last n" # When animation reaches the last frame, it backs to the last N frames

--
--- Set state.
---@param state JM.AnimaStates Possible values are "repeating", "random" or "come and back". If none of these is informed, the state is setted as "repeating".
function Anima:set_state(state)
    if state then
        state = string.lower(state)
    end

    if state == "random" then
        self.__current_state = ANIMA_STATES.random

    elseif state == "back and forth"
        or state == "back_and_forth" then

        self.__current_state = ANIMA_STATES.back_and_forth
    elseif state == "repeat last n" then
        self.__current_state = ANIMA_STATES.repeating_last_n_frames
    else
        self.__current_state = ANIMA_STATES.looping
    end
end

function Anima:set_max_cycle(value)
    self.max_cycle = value
end

function Anima:set_visible(value)
    self.__is_visible = value and true or false
end

---
--- Resets Animation's fields to his default values.
---
function Anima:reset()
    self.time_update = 0
    self.time_frame = 0
    self.time_paused = 0
    self.current_frame = (self.direction > 0 and 1)
        or self.__amount_frames
    self.cycle_count = 0
    self.initial_direction = nil
    self.__is_paused = nil
    self.__is_visible = true
    self.__is_enabled = true
    -- self.__effect_manager:stop_all()
end

---@param arg {x: number, y: number, rot: number, sx: number, sy: number, ox: number, oy: number, kx: number, ky: number}
function Anima:__set_effect_transform(arg)

    Affectable.__set_effect_transform(self, arg)

end

function Anima:__get_effect_transform()
    return Affectable.__get_effect_transform(self)
end

--- Enable a custom action to execute in Animation update method.
---@param custom_action function
function Anima:set_custom_action(custom_action)
    self.__custom_action = custom_action
end

--- Enable a custom action to execute when Animation stops.
---@param action function
function Anima:set_stop_action(action)
    self.__stop_action = action
end

--- Sets a custom method that executes one time on every frame change.
---@param action function
---@param cancel_action function|nil
function Anima:set_on_frame_change_action(action, cancel_action)
    self.__on_frame_change_action = action
    self.__on_frame_change_cancel_action = cancel_action
end

---@param animation JM.Anima
local function execute_on_frame_change_action(animation)
    if animation.__on_frame_change_action then
        animation:__on_frame_change_action(animation.current_frame)
    end
end

---@param animation JM.Anima
local function execute_stop_action(animation)
    if animation.__stop_action then
        animation.__stop_action()
    end
end

---
-- Execute the animation logic.
---@param self JM.Anima
---@param dt number # The delta time.
function Anima:update(dt)
    if not self.__is_enabled then return end

    self.time_update = (self.time_update + dt)

    if not self.initial_direction then
        self.initial_direction = self.direction
    end

    -- updating the Effects
    if self.__effect_manager then self.__effect_manager:update(dt) end

    do
        -- Executing the custom update action
        local r = self.__custom_action and self.__custom_action(self)
    end

    if self.__is_paused or
        (self.max_cycle and self.cycle_count >= self.max_cycle)
    then

        self.time_paused = (self.time_paused + dt) % 5000000
        return
    end


    self.time_frame = self.time_frame + dt

    if self.time_frame >= self.speed then

        self.time_frame = self.time_frame - self.speed

        execute_on_frame_change_action(self)

        if self:__is_in_random_state() then
            local last_frame = self.current_frame
            local number = love.math.random(0, self.__amount_frames - 1)

            self.current_frame = 1 + (number % self.__amount_frames)

            self.cycle_count = (self.cycle_count + 1) % 6000000

            if last_frame == self.current_frame then
                self.current_frame = 1 + (self.current_frame
                    % self.__amount_frames)
            end

            return
        end -- END if animation is in random state

        self.current_frame = self.current_frame
            + (1 * self.direction)

        if self:__is_in_normal_direction() then

            if self.current_frame > self.__amount_frames then

                if self:__is_in_looping_state() then
                    self.current_frame = 1
                    self.cycle_count = (self.cycle_count + 1) % 600000

                    if self:__is_stopping_at_the_end() then
                        self.current_frame = self.__amount_frames
                        self:pause()
                    end

                elseif self:__is_in_repeating_last_n_state() then
                    self.current_frame = self.current_frame - self.__N__
                    self.cycle_count = (self.cycle_count + 1)

                else -- ELSE: animation is in "back and forth" state

                    self.current_frame = self.__amount_frames
                    self.time_frame = self.time_frame + self.speed
                    self.direction = -self.direction

                    if self.direction == self.initial_direction then
                        self.cycle_count = (self.cycle_count + 1) % 600000
                    end

                    if self:__is_stopping_at_the_end()
                        and self.direction == self.initial_direction then

                        self:pause()
                    end
                end -- END ELSE animation in "back and forth" state

            end -- END ELSE if animation is repeating

        else -- ELSE direction is negative

            if self.current_frame < 1 then

                if self:__is_in_looping_state() then
                    self.current_frame = self.__amount_frames
                    self.cycle_count = (self.cycle_count + 1) % 600000

                    if self:__is_stopping_at_the_end() then
                        self.current_frame = 1
                        self:pause()
                    end

                elseif self:__is_in_repeating_last_n_state() then
                    self.current_frame = self.__N__
                    self.cycle_count = (self.cycle_count + 1)

                else -- ELSE animation is not repeating
                    self.current_frame = 1
                    self.time_frame = self.time_frame + self.speed
                    self.direction = self.direction * -1

                    if self.direction == self.initial_direction then
                        self.cycle_count = (self.cycle_count + 1) % 600000
                    end

                    if self:__is_stopping_at_the_end()
                        and self.direction == self.initial_direction then

                        self:pause()
                    end
                end -- END ELSE animation is not repeating
            end
        end -- END if in normal direction (positive direction)

    end -- END IF time update bigger than speed

end -- END update function

---
--- Draw the animation. Apply effects if exists.
---
---@param x number # The top-left position to draw (x-axis).
---@param y number # The top-left position to draw (y-axis).
function Anima:draw(x, y)

    self:__draw_with_no_effects__(x, y)

    -- Drawing the effects, if some exists.
    if self.__effect_manager then self.__effect_manager:draw(x, y) end
end

---@return JM.Anima.Frame
function Anima:__get_current_frame()
    return self.frames_list[self.current_frame]
end

---
--- Draw the animation using a rectangle.
---@param x number # Rectangle top-left position (x-axis).
---@param y number # Rectangle top-left position (y-axis).
---@param w number # Rectangle width in pixels.
---@param h number # Rectangle height in pixels.
function Anima:draw_rec(x, y, w, h)
    local current_frame, effect_transform
    current_frame = self:__get_current_frame()

    effect_transform = self:__get_effect_transform()

    x = x + w / 2.0
    y = y + h
        - current_frame.h * self.scale_y * (effect_transform and effect_transform.sy or 1)
        + current_frame.oy * self.scale_y * (effect_transform and effect_transform.sy or 1)

    if self:__is_flipped_in_y() then
        y = y - h + (current_frame.h * self.scale_y * (effect_transform and effect_transform.sy or 1))
    end

    self:draw(x, y)

    current_frame, effect_transform = nil, nil
end

function Anima:__draw__(x, y)
    return self:__draw_with_no_effects__(x, y)
end

---
--- Draws the animation without apply any effect.
---
---@param x number # The top-left position to draw (x-axis).
---@param y number # The top-left position to draw (y-axis).
function Anima:__draw_with_no_effects__(x, y)

    love_graphics_push()

    local effect_transform = self:__get_effect_transform()

    if effect_transform then
        local transform
        transform = love_math_new_transform()

        transform:setTransformation(
            x + effect_transform.ox,
            y + effect_transform.oy,
            effect_transform.rot,
            effect_transform.sx,
            effect_transform.sy,
            x,
            y,
            effect_transform.kx,
            effect_transform.ky
        )

        love_graphics_apply_transform(transform)
        transform = nil
    end -- END if exists a effect transform.

    local current_frame
    current_frame = self:__get_current_frame()

    current_frame:setViewport(self.__img, self.quad)

    love_graphics_set_color(self.__color)

    if self.__is_visible then
        love_graphics_draw(self.__img, self.quad,
            (x), (y),
            self.rotation, self.scale_x * self.flip_x,
            self.scale_y * self.flip_y,
            current_frame.ox, current_frame.oy,
            self.__kx,
            self.__ky
        )
    end

    love_graphics_pop()
    current_frame = nil
end

--- Aplica efeito na animacao.
---@param effect_type JM.Effect.id_string|JM.Effect.id_number
---@param effect_args any
---@return JM.Effect|nil effect
function Anima:apply_effect(effect_type, effect_args)
    if not self.__effect_manager then return end
    return self.__effect_manager:apply_effect(self, effect_type, effect_args)
end

---Stops a especific effect by his unique id.
---@param effect_id JM.Effect|number
---@return boolean
function Anima:stop_effect(effect_id)
    if not self.__effect_manager then return false end
    if type(effect_id) == "number" then
        return self.__effect_manager:stop_effect(effect_id)
    end
    return self.__effect_manager:stop_effect(effect_id:get_unique_id())
end

---Tells if animation is flipped in y-axis.
---@return boolean
function Anima:__is_flipped_in_y()
    return self.flip_y < 0
end

---Tells if animation is flipped in x-axis.
---@return boolean
function Anima:__is_flipped_in_x()
    return self.flip_x < 0
end

--- Flips the animation.
function Anima:flip()
    self.direction = self.direction * -1
end

---
--- Tells if animation should stop in the last frame.
---
---@return boolean result
function Anima:__is_stopping_at_the_end()
    return self.__stop_at_the_end
end

---
--- Tells if animation is in repeating state.
---@return boolean result
function Anima:__is_in_looping_state()
    return self.__current_state == ANIMA_STATES.looping
end

function Anima:__is_in_repeating_last_n_state()
    return self.__current_state == ANIMA_STATES.repeating_last_n_frames
end

---
--- Tells if animation is in random state.
---
---@return boolean result
function Anima:__is_in_random_state()
    return self.__current_state == ANIMA_STATES.random
end

---
--- Tells if the animation is normal mode.
---@return boolean result
function Anima:__is_in_normal_direction()
    return self.direction > 0
end

function Anima:pause()
    if not self.__is_paused then
        self.__is_paused = true
        execute_stop_action(self)
        return true
    end
    return false
end

---@param restart boolean|nil
---@return boolean
function Anima:unpause(restart)
    if self.__is_paused then
        self.__is_paused = false
        local r = restart and self:reset()
        return true
    end
    return false
end

function Anima:is_paused()
    return self.__is_paused
end

function Anima:stop()
    if self.__is_enabled then
        self.__is_enabled = false
        return true
    end
    return false
end

function Anima:resume()
    if not self.__is_enabled then
        self.__is_enabled = true
        return true
    end
    return false
end

function Anima:is_enabled()
    return self.__is_enabled
end

--- Amount of time that animation is running (in seconds).
---@return number
function Anima:time_updating()
    return self.time_update
end

function Anima:zera_time_updating()
    self.time_update = 0
end

return Anima
