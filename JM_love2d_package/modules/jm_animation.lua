--[[ Lua module for animation in LÖVE 2D.

    Copyright (c) 2022, Joao Moreira.
]]

local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")

local Affectable = require("/JM_love2d_package/modules/templates/Affectable")

local Utils = require("/JM_love2d_package/utils")

local Frame = require("/JM_love2d_package/modules/classes/Frame")

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

    self:set_img(args.img)

    self.__args = args

    self.__amount_frames = (args.frames_list and #args.frames_list) or (args.frames) or 1

    self.__frame_time = 0.
    self.__update_time = 0.
    self.__stopped_time = 0.
    self.__cycle_count = 0
    self.__is_visible = true
    self.__is_enabled = true
    self.__initial_direction = nil

    self:set_reverse_mode(args.is_reversed)

    self:set_color(args.color or { 1, 1, 1, 1 })

    self.__rotation = args.rotation or 0
    self.__speed = args.speed or 0.3
    self.__stop_at_the_end = args.stop_at_the_end or false
    self.__max_cycle = args.amount_cycle or nil
    if args.duration then self:set_duration(args.duration) end

    self.__current_frame = (self.__direction < 0 and self.__amount_frames) or 1


    self:set_state(args.state)

    self.__N__ = args.n or 0

    self.__flip = { x = 1, y = 1 }

    self:set_scale(args.scale)

    self.__effect_manager = EffectManager:new()

    self.__frames_list = {}

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
        self.__frames_list[i] = Frame:new(args.frames_list[i])
    end -- END FOR for generate frames objects


    if args.width or args.height then
        self:set_size(args.width, args.height, args.ref_width, args.ref_height)
    end

    self.__quad = love.graphics.newQuad(0, 0,
        args.frames_list[1][1],
        args.frames_list[1][2],
        self.__img:getDimensions()
    )

    self.__custom_action = nil
    self.__custom_action_args = nil

    self.__stop_action = nil
    self.__stop_action_args = nil

    Affectable.__checks_implementation__(self)
end

function Anima:copy()
    local obj = Anima.new(Anima, self.__args)
    return obj
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

        local desired_size_in_pxl = Utils:desired_size(
            width, height, tt.w, tt.h, true
        )

        if desired_size_in_pxl then
            self:set_scale(desired_size_in_pxl)
        end
    end
end

---@param value number
function Anima:set_speed(value)
    assert(value >= 0, "\nError: Value passed to 'set_speed' method is smaller than zero.")

    self.__speed = value
end

---@param duration number
function Anima:set_duration(duration)
    assert(duration > 0, "\nError: Value passed to 'set_duration' method is smaller than zero.")

    self.__speed = duration / self.__amount_frames
end

---@param value boolean
function Anima:set_reverse_mode(value)
    self.__direction = value and -1 or 1
end

---@param value boolean
---@param stop_action function
---@param stop_action_args any
function Anima:stop_at_the_end(value, stop_action, stop_action_args)
    self.__stop_at_the_end = value and true or false

    if value then
        self:set_stop_action(stop_action, stop_action_args)
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
    self.__flip.x = flip and -1 or 1
end

---
function Anima:set_flip_y(flip)
    self.__flip.y = flip and -1 or 1
end

function Anima:toggle_flip_x()
    self.__flip.x = self.__flip.x * (-1)
end

function Anima:toggle_flip_y()
    self.__flip.y = self.__flip.y * (-1)
end

--
--- Set scale. If no parameter is given, a default value is setted ( x=1, y=1 ).
--
---@param scale {x: number, y: number}
function Anima:set_scale(scale)
    self.__scale = {
        x = (scale and scale.x)
            or self.__scale and self.__scale.x
            or 1,
        y = (scale and scale.y)
            or self.__scale and self.__scale.y
            or 1
    }
end

function Anima:get_scale()
    return self.__scale
end

--- Sets Animation rotation in radians.
---@param value number
function Anima:set_rotation(value)
    self.__rotation = value
end

--- Gets Animation current rotation in radians.
---@return number
function Anima:get_rotation()
    return self.__rotation
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
---@param state JM.AnimaStates Possible values are "repeating", "random" or "come and back". If none of these is informed, then the state is setted as "repeating".
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
    self.__max_cycle = value
end

function Anima:set_visible(value)
    self.__is_visible = value and true or false
end

---
--- Resets Animation's fields to his default values.
---
function Anima:reset()
    self.__update_time = 0
    self.__frame_time = 0
    self.__current_frame = (self.__direction > 0 and 1)
        or self.__amount_frames
    self.__update_time = 0
    self.__stopped_time = 0
    self.__cycle_count = 0
    self.__initial_direction = nil
    self.__stopped = nil
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
---@param args any
function Anima:set_custom_action(custom_action, args)
    self.__custom_action = custom_action
    self.__custom_action_args = args
end

--- Enable a custom action to execute when Animation stops.
---@param action function
---@param args any
function Anima:set_stop_action(action, args)
    self.__stop_action = action
    self.__stop_action_args = args
end

function Anima:__execute_stop_action__()
    if self.__stop_action then
        self.__stop_action(self.__stop_action_args)
    end
end

--- Sets a custom method that executes on every frame change.
---@param action function
---@param args any
function Anima:set_on_frame_change_action(action, args)
    self.__on_frame_change_action = action
    self.__on_frame_change_args = args
end

function Anima:__execute_on_frame_change_action()
    if self.__on_frame_change_action then
        self.__on_frame_change_action(self, self.__on_frame_change_args)
    end
end

---
-- Execute the animation logic.
---@param dt number # The delta time.
function Anima:update(dt)
    if not self.__is_enabled then return end

    self.__update_time = (self.__update_time + dt)

    if not self.__initial_direction then
        self.__initial_direction = self.__direction
    end

    -- updating the Effects
    self.__effect_manager:update(dt)

    if self.__custom_action then
        self.__custom_action(self, self.__custom_action_args)
    end


    if self.__stopped or
        (self.__max_cycle and self.__cycle_count >= self.__max_cycle)
    then

        self.__stopped_time = (self.__stopped_time + dt) % 5000000
        return
    end


    self.__frame_time = self.__frame_time + dt

    if self.__frame_time >= self.__speed then

        self.__frame_time = self.__frame_time - self.__speed

        self:__execute_on_frame_change_action()

        if self:__is_in_random_state() then
            local last_frame = self.__current_frame
            local number = love.math.random(0, self.__amount_frames - 1)

            self.__current_frame = 1 + (number % self.__amount_frames)

            self.__cycle_count = (self.__cycle_count + 1) % 6000000

            if last_frame == self.__current_frame then
                self.__current_frame = 1 + (self.__current_frame
                    % self.__amount_frames)
            end

            return
        end -- END if animation is in random state

        self.__current_frame = self.__current_frame
            + (1 * self.__direction)

        if self:__is_in_normal_direction() then

            if self.__current_frame > self.__amount_frames then

                if self:__is_in_looping_state() then
                    self.__current_frame = 1
                    self.__cycle_count = (self.__cycle_count + 1) % 600000

                    if self:__is_stopping_at_the_end() then
                        self.__current_frame = self.__amount_frames
                        self:pause()
                    end

                elseif self:__is_in_repeating_last_n_state() then
                    self.__current_frame = self.__current_frame - self.__N__
                    self.__cycle_count = (self.__cycle_count + 1)

                else -- ELSE: animation is in "back and forth" state

                    self.__current_frame = self.__amount_frames
                    self.__frame_time = self.__frame_time + self.__speed
                    self.__direction = -self.__direction

                    if self.__direction == self.__initial_direction then
                        self.__cycle_count = (self.__cycle_count + 1) % 600000
                    end

                    if self:__is_stopping_at_the_end()
                        and self.__direction == self.__initial_direction then

                        self:pause()
                    end
                end -- END ELSE animation in "back and forth" state

            end -- END ELSE if animation is repeating

        else -- ELSE direction is negative

            if self.__current_frame < 1 then

                if self:__is_in_looping_state() then
                    self.__current_frame = self.__amount_frames
                    self.__cycle_count = (self.__cycle_count + 1) % 600000

                    if self:__is_stopping_at_the_end() then
                        self.__current_frame = 1
                        self:pause()
                    end

                elseif self:__is_in_repeating_last_n_state() then
                    self.__current_frame = self.__N__
                    self.__cycle_count = (self.__cycle_count + 1)

                else -- ELSE animation is not repeating
                    self.__current_frame = 1
                    self.__frame_time = self.__frame_time + self.__speed
                    self.__direction = self.__direction * -1

                    if self.__direction == self.__initial_direction then
                        self.__cycle_count = (self.__cycle_count + 1) % 600000
                    end

                    if self:__is_stopping_at_the_end()
                        and self.__direction == self.__initial_direction then

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
    self.__effect_manager:draw(x, y)
end

---@return JM.Anima.Frame
function Anima:__get_current_frame()
    return self.__frames_list[self.__current_frame]
end

---
--- Draw the animation using a rectangle.
---@param x number # Rectangle top-left position (x-axis).
---@param y number # Rectangle top-left position (y-axis).
---@param w number # Rectangle width in pixels.
---@param h number # Rectangle height in pixels.
function Anima:draw_rec(x, y, w, h)
    local current_frame = self:__get_current_frame()

    local effect_transform = self:__get_effect_transform()

    x = x + w / 2.0
    y = y + h
        - current_frame.h * self.__scale.y * (effect_transform and effect_transform.sy or 1)
        + current_frame.oy * self.__scale.y * (effect_transform and effect_transform.sy or 1)

    if self:__is_flipped_in_y() then
        y = y - h + (current_frame.h * self.__scale.y * (effect_transform and effect_transform.sy or 1))
    end

    self:draw(x, y)
end

function Anima:__draw__(x, y)
    return self:__draw_with_no_effects__(x, y)
end

-- Some local variables to store global modules.
local love_graphics = love.graphics
local love_graphics_draw = love_graphics.draw
local love_graphics_rectangle = love_graphics.rectangle
local love_graphics_set_color = love_graphics.setColor
local love_graphics_push = love_graphics.push
local love_graphics_pop = love_graphics.pop
local love_graphics_apply_transform = love_graphics.applyTransform
local love_math_new_transform = love.math.newTransform

---
--- Draws the animation without apply any effect.
---
---@param x number # The top-left position to draw (x-axis).
---@param y number # The top-left position to draw (y-axis).
function Anima:__draw_with_no_effects__(x, y)

    love_graphics_push()

    local effect_transform = self:__get_effect_transform()

    if effect_transform then
        local transform = love_math_new_transform()

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
    end -- END if exists a effect transform.

    local current_frame = self:__get_current_frame()

    current_frame:setViewport(self.__img, self.__quad)

    love_graphics_set_color(self.__color)

    if self.__is_visible then
        love_graphics_draw(self.__img, self.__quad,
            (x), (y),
            self.__rotation, self.__scale.x * self.__flip.x,
            self.__scale.y * self.__flip.y,
            current_frame.ox, current_frame.oy,
            self.__kx,
            self.__ky
        )
    end

    love_graphics_pop()

end

--- Aplica efeito na animacao.
---@param effect_type JM.Effect.id_string|JM.Effect.id_number
---@param effect_args any
---@return JM.Effect effect
function Anima:apply_effect(effect_type, effect_args)
    return self.__effect_manager:apply_effect(self, effect_type, effect_args)
end

---Stops a especific effect by his unique id.
---@param effect_id JM.Effect|number
---@return boolean
function Anima:stop_effect(effect_id)
    if type(effect_id) == "number" then
        return self.__effect_manager:stop_effect(effect_id)
    end
    return self.__effect_manager:stop_effect(effect_id:get_unique_id())
end

---Tells if animation is flipped in y-axis.
---@return boolean
function Anima:__is_flipped_in_y()
    return self.__flip.y < 0
end

---Tells if animation is flipped in x-axis.
---@return boolean
function Anima:__is_flipped_in_x()
    return self.__flip.x < 0
end

--- Flips the animation.
function Anima:flip()
    self.__direction = self.__direction * -1
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
    return self.__direction > 0
end

function Anima:pause()
    if not self.__stopped then
        self.__stopped = true
        self:__execute_stop_action__()
        return true
    end
    return false
end

function Anima:unpause()
    if self.__stopped then
        self.__stopped = false
        self:reset()
        return true
    end
    return false
end

function Anima:is_paused()
    return self.__stopped
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

--- Amount of time that animation is ruuning (in seconds).
---@return number
function Anima:time_updating()
    return self.__update_time
end

function Anima:zera_time_updating()
    self.__update_time = 0
end

return Anima
