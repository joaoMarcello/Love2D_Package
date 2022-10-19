--[[ Lua library for animation in LÖVE.

    Some of the main functions include:

    * :new -- Class constructor.
    * :update --
    * :draw --
    * :draw_rec --

    @author Joao Moreira, 2022.
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
    random = 3
}

---
--- Animation class constructor.
---
--- @param args {img: love.Image|string, frames: number, frame_size: JM.Point, speed: number, rotation: number, color: JM.Color, scale: table, origin: table, pos_in_texture: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, kx: number, ky: number} # A table containing the following fields:
-- * img (Required): The source image for animation (could be a Love.Image or a string containing the file path). All the frames in the source image should be in the horizontal.
-- * frames: The amount of frames in the animation.
-- * frame_size: A table with the animation's frame size. Should contain the index x (width) and y (height).
-- * speed: Time in seconds to update frame.
-- * pos_in_texture: Optional table parameter to indicate where the animation is localized in the image. Useful when there is a lot of animation in one single image (default value is {x=0, y=0}).
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
--- @param args {img: love.Image, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number}  # A table containing the follow fields:
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

    self.__color = args.color or { 1, 1, 1, 1 }
    self.__rotation = args.rotation or 0
    self.__speed = args.speed or 0.3
    self.__stop_at_the_end = args.stop_at_the_end or false
    self.__max_cycle = args.amount_cycle or nil
    if args.duration then self:set_duration(args.duration) end

    self.__current_frame = (self.__direction < 0 and self.__amount_frames) or 1


    self:set_state(args.state)

    self:set_flip({ x = args.flip_x, y = args.flip_y })

    self:set_scale(args.scale)

    self.__effect_manager = EffectManager:new()

    self.__frames_list = {}

    if not args.frames_list then
        args.frames_list = {}
        local w = self.__img:getWidth() / args.frames
        for i = 1, args.frames do
            table.insert(args.frames_list, { (i - 1) * w, 0, w, args.bottom or self.__img:getHeight() })
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

    -- self.__transform = self:__set_transform(nil)

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
    self.__stop_at_the_end = value

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
--- Set flip in x and y axis.
---@param flip {x: boolean, y:boolean}
function Anima:set_flip(flip)
    self.__flip = {
        x = (flip and flip.x and -1) or (self.__flip and self.__flip.x) or 1,
        y = (flip and flip.y and -1) or (self.__flip and self.__flip.y) or 1
    }
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

--- Sets Animation rotation to a number value.
---@param value number
function Anima:set_rotation(value)
    self.__rotation = value
end

--- Gets Animation current rotation.
---@return number
function Anima:get_rotation()
    return self.__rotation
end

--- Return the animation color field.
---@return table
function Anima:get_color()
    return self.__color
end

---
--- Set animation color.
---@overload fun(self: JM.Anima, value: {[1]: number, [2]: number, [3]: number, [4]: number})
---@param value {r: number, g: number, b: number, a: number}
function Anima:set_color(value)
    if not value then return end
    if not self.__color then self.__color = {} end

    if value.r or value.g or value.b or value.a then
        self.__color = {
            value.r or self.__color[1],
            value.g or self.__color[2],
            value.b or self.__color[3],
            value.a or self.__color[4]
        }

    else -- color is in index format
        self.__color = {
            value[1] or self.__color[1],
            value[2] or self.__color[2],
            value[3] or self.__color[3],
            value[4] or self.__color[4]
        }
    end
end

---@return {ox: number, oy: number}
function Anima:get_origin()
    local cf = self:__get_current_frame()
    return cf:get_origin()
end

function Anima:set_kx(value)
    self.__kx = value
end

function Anima:set_ky(value)
    self.__ky = value
end

---
--- Diferentes estados da animacao
---
---@alias JM.AnimaStates
---|"looping" # (default) when animation reaches the last frame, the current frame is set to beginning.
---|"random" # animation shows his frames in a aleatory order.
---|"back and forth" # when animation reaches the last frame, the direction of animation changes.

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
    else
        self.__current_state = ANIMA_STATES.looping
    end
end

function Anima:set_visible(value)
    self.__is_visible = value
end

---
--- Reset animation field to his default values.
---
function Anima:reset()
    self.__update_time = 0.
    self.__frame_time = 0.
    self.__current_frame = (self.__direction > 0 and 1)
        or self.__amount_frames
    self.__update_time = 0
    self.__stopped_time = 0
    self.__cycle_count = 0
    self.__initial_direction = nil
    self.__stopped = nil
    self.__is_visible = true
    self.__is_enabled = true
end

---@param arg {x: number, y: number, rot: number, sx: number, sy: number, ox: number, oy: number, kx: number, ky: number, color: JM.Color}
function Anima:__set_effect_transform(arg)
    if not arg then
        self.__effect_transform = nil
        return
    end

    if not self.__effect_transform then
        self.__effect_transform = {}
    end

    self.__effect_transform = {
        x = arg.x or self.__effect_transform.x or self:get_origin().ox,
        y = arg.y or self.__effect_transform.y or self:get_origin().oy,
        rot = arg.rot or self.__effect_transform.rot or 0,
        sx = arg.sx or self.__effect_transform.sx or 1,
        sy = arg.sy or self.__effect_transform.sy or 1,
        ox = arg.ox or self.__effect_transform.ox or 0,
        oy = arg.oy or self.__effect_transform.oy or 0,
        kx = arg.kx or self.__effect_transform.kx or 0,
        ky = arg.ky or self.__effect_transform.ky or 0
    }
end

--- Enabla a custom action to execute in animation update method.
---@param custom_action function
---@param args any
function Anima:set_custom_action(custom_action, args)
    self.__custom_action = custom_action
    self.__custom_action_args = args
end

---
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

---
-- Execute the animation logic.
---@param dt number # The delta time.
function Anima:update(dt)
    if not self.__is_enabled then return end

    self.__update_time = (self.__update_time + dt) % 500000.

    if not self.__initial_direction then
        self.__initial_direction = self.__direction
    end

    -- updating the Effects
    self.__effect_manager:update(dt)

    if self.__custom_action then
        self.__custom_action(self.__custom_action_args)
    end

    if self.__stopped or
        (self.__max_cycle and self.__cycle_count >= self.__max_cycle) then

        self.__stopped_time = (self.__stopped_time + dt) % 5000000
        return
    end

    self.__frame_time = self.__frame_time + dt

    if self.__frame_time >= self.__speed then
        self.__frame_time = self.__frame_time - self.__speed

        if self:__is_random() then
            local last_frame = self.__current_frame
            math.random()
            self.__current_frame = 1
                + (math.random(0, self.__amount_frames) % self.__amount_frames)

            self.__cycle_count = (self.__cycle_count + 1) % 6000000

            if last_frame == self.__current_frame then
                self.__current_frame = 1
                    + self.__current_frame
                    % self.__amount_frames
            end

            return
        end -- END if animation is in random state

        self.__current_frame = self.__current_frame
            + (1 * self.__direction)

        if self:__is_in_normal_direction() then

            if self.__current_frame > self.__amount_frames then

                if self:__is_repeating() then
                    self.__current_frame = 1
                    self.__cycle_count = (self.__cycle_count + 1) % 600000

                    if self:__is_stopping_in_the_end() then
                        self.__current_frame = self.__amount_frames
                        self:pause()
                    end

                else -- ELSE: animation is in "come and back" state

                    self.__current_frame = self.__amount_frames
                    self.__frame_time = self.__frame_time + self.__speed
                    self.__direction = -self.__direction

                    if self.__direction == self.__initial_direction then
                        self.__cycle_count = (self.__cycle_count + 1) % 600000
                    end

                    if self:__is_stopping_in_the_end()
                        and self.__direction == self.__initial_direction then

                        self:pause()
                    end
                end -- END ELSE animation in "come and back" state

            end -- END ELSE if animation is repeating

        else -- ELSE direction is negative

            if self.__current_frame < 1 then

                if self:__is_repeating() then
                    self.__current_frame = self.__amount_frames
                    self.__cycle_count = (self.__cycle_count + 1) % 600000

                    if self:__is_stopping_in_the_end() then
                        self.__current_frame = 1
                        self:pause()
                    end

                else -- ELSE animation is not repeating
                    self.__current_frame = 1
                    self.__frame_time = self.__frame_time + self.__speed
                    self.__direction = self.__direction * -1

                    if self.__direction == self.__initial_direction then
                        self.__cycle_count = (self.__cycle_count + 1) % 600000
                    end

                    if self:__is_stopping_in_the_end()
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

    x = x + w / 2.0
    y = y + h
        - current_frame.h * self.__scale.y * (self.__effect_transform and self.__effect_transform.sy or 1)
        + current_frame.oy * self.__scale.y * (self.__effect_transform and self.__effect_transform.sy or 1)

    if self:__is_flipped_in_y() then
        y = y - h + (current_frame.h * self.__scale.y * (self.__effect_transform and self.__effect_transform.sy or 1))
    end

    self:draw(x, y)
end

function Anima:__draw__(x, y)
    return self:__draw_with_no_effects__(x, y)
end

---
--- Draw the animation without apply any effect.
---
---@param x number # The top-left position to draw (x-axis).
---@param y number # The top-left position to draw (y-axis).
function Anima:__draw_with_no_effects__(x, y)

    love.graphics.push()

    if self.__effect_transform then
        local transform = love.math.newTransform()
        local current_frame = self:__get_current_frame()

        transform:setTransformation(
            x + self.__effect_transform.ox,
            y + self.__effect_transform.oy,
            self.__effect_transform.rot,
            self.__effect_transform.sx,
            self.__effect_transform.sy,
            x,
            y,
            self.__effect_transform.kx,
            self.__effect_transform.ky
        )

        love.graphics.applyTransform(transform)
    end -- END if exists a effect transform.

    local current_frame = self:__get_current_frame()

    current_frame:setViewport(self.__img, self.__quad)

    love.graphics.setColor(self.__color)

    if self.__is_visible then
        love.graphics.draw(self.__img, self.__quad,
            (x), (y),
            self.__rotation, self.__scale.x * self.__flip.x,
            self.__scale.y * self.__flip.y,
            current_frame.ox, current_frame.oy,
            self.__kx,
            self.__ky
        )
    end

    love.graphics.pop()

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
function Anima:__is_stopping_in_the_end()
    return self.__stop_at_the_end
end

---
--- Tells if animation is in repeating state.
---@return boolean result
function Anima:__is_repeating()
    return self.__current_state == ANIMA_STATES.looping
end

---
--- Tells if animation is in random state.
---
---@return boolean result
function Anima:__is_random()
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
