--[[ Lua library for animation in Love2D.

    Some of the main functions include:

    * :new -- Class constructor.
    * :config -- Configure animation fields.
    * :update --
    * :draw --
    * :draw_rec --

    @author Joao Moreira, 2022.
]]

local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")

local Affectable = require("/JM_love2d_package/modules/templates/Affectable")

local Utils = require("/JM_love2d_package/utils")

-- Class to animate.
--- @class JM_Anima: JM_Affectable
--- @field __configuration {scale: JM_Point, color: JM_Color, direction: -1|1, rotation: number, speed: number, flip: table, kx: number, ky: number, current_frame: number}
local Anima = {}

---@enum AnimaStates
local ANIMA_STATES = {
    repeating = 1,
    come_and_back = 2,
    random = 3
}

---
--- Animation class constructor.
---
--- @param args {img: love.Image|string, frames: number, frame_size: JM_Point, speed: number, rotation: number, color: JM_Color, scale: table, origin: table, pos_in_texture: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, kx: number, ky: number} # A table containing the following fields:
-- * img (Required): The source image for animation (could be a Love.Image or a string containing the file path). All the frames in the source image should be in the horizontal.
-- * frames: The amount of frames in the animation.
-- * frame_size: A table with the animation's frame size. Should contain the index x (width) and y (height).
-- * speed: Time in seconds to update frame.
-- * pos_in_texture: Optional table parameter to indicate where the animation is localized in the image. Useful when there is a lot of animation in one single image (default value is {x=0, y=0}).
--- @return JM_Anima animation # A instance of Anima class.
function Anima:new(args)
    if not args then return {} end

    local animation = {}
    setmetatable(animation, self)
    self.__index = self

    Anima.__constructor__(animation, args)

    return animation
end

---
--- Internal method for constructor.
---
--- @param args {img: love.Image, frames: number, frame_size: table, speed: number, rotation: number, color: JM_Color, scale: table, origin: table, pos_in_texture: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, max_rows: number, state: JM_AnimaStates, bottom: number, grid: table, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number}  # A table containing the follow fields:
---
function Anima:__constructor__(args)

    self:set_img(args.img)

    self.__amount_frames = args.frames or 1
    self.__frame_time = 0.
    self.__update_time = 0.
    self.__stopped_time = 0.
    self.__row_count = 0
    self.__is_visible = true
    self.__is_enabled = true
    self.__initial_direction = nil
    self.__direction = (args.is_reversed and -1) or 1
    self.__color = args.color or { 1, 1, 1, 1 }
    self.__rotation = args.rotation or 0
    self.__speed = args.speed or 0.3
    self.__current_frame = (self.__direction < 0 and self.__amount_frames) or 1
    self.__stop_at_the_end = args.stop_at_the_end or false
    self.__max_rows = args.max_rows or nil

    self:set_frame_size(args.frame_size)

    self.__bottom = args.bottom or self.__frame_size.y

    self:set_state(args.state)

    self.__grid = {
        x = args.grid and args.grid.x or self.__amount_frames,
        y = args.grid and args.grid.y or 1
    }

    self:set_flip({ x = args.flip_x, y = args.flip_y })

    self:set_origin(args.origin)

    self:set_pos_in_texture(args.pos_in_texture)

    self:set_scale(args.scale)

    if args.width or args.height then
        local tt = {
            x = args.ref_width or self.__frame_size.x,
            y = args.ref_height or self.__frame_size.y
        }

        local desired_size_in_pxl = Utils:desired_size(
            args.width, args.height, tt
        )

        if desired_size_in_pxl then
            self:set_scale(desired_size_in_pxl)
        end
    end

    if args.frame_size or not self.__quad then
        self.__quad = love.graphics.newQuad(0, 0,
            self.__frame_size.x,
            self.__frame_size.y,
            self.__img:getDimensions()
        )
    end

    self.__effect_manager = EffectManager:new()

    Affectable.checks_implementation(self)
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
--- Set frame size. If not given any parameter, a default value is setted based in image dimensions and amount frames.
--
---@param frame_size {x: number, y: number}
function Anima:set_frame_size(frame_size)
    self.__frame_size = {
        x = (frame_size and frame_size.x)
            or (self.__frame_size and self.__frame_size.x)
            or self.__img:getWidth() / self.__amount_frames,
        y = (frame_size and frame_size.y)
            or (self.__frame_size and self.__frame_size.y)
            or self.__img:getHeight()
    }
end

---
--- Set origin. If given parameter is nil, a default value is setted based in the frame size field.
--
---@param origin {x: number, y: number}
function Anima:set_origin(origin)
    self.__origin = {
        x = (origin and origin.x)
            or (self.__origin and self.__origin.x)
            or self.__frame_size.x / 2,
        y = (origin and origin.y)
            or (self.__origin and self.__origin.y)
            or self.__frame_size.y / 2
    }
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

--
--- Set position texture.
--
---@param position {x: number, y: number}
function Anima:set_pos_in_texture(position)
    self.__pos_in_texture = {
        x = (position and position.x)
            or (self.__pos_in_texture and self.__pos_in_texture.x)
            or 0,
        y = (position and position.y)
            or (self.__pos_in_texture and self.__pos_in_texture.y)
            or 0
    }
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
---@overload fun(self: JM_Anima, value: {[1]: number, [2]: number, [3]: number, [4]: number})
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

---
--- Diferentes estados da animacao
---
---@alias JM_AnimaStates
---|"repeating" # (default) when animation reaches the last frame, the current frame is set to beginning.
---|"random" # animation shows his frames in a aleatory order.
---|"come and back" # when animation reaches the last frame, the direction of animation changes.

--
--- Set state.
---@param state JM_AnimaStates Possible values are "repeating", "random" or "come and back". If none of these is informed, then the state is setted as "repeating".
function Anima:set_state(state)
    if state then
        state = string.lower(state)
    end

    if state == "random" then
        self.__current_state = ANIMA_STATES.random

    elseif state == "come_and_back"
        or state == "come and back" then

        self.__current_state = ANIMA_STATES.come_and_back
    else
        self.__current_state = ANIMA_STATES.repeating
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
    self.__row_count = 0
    self.__initial_direction = nil
    self.__stopped = nil
    self.__is_visible = true
    self.__is_enabled = true
end

--
--- Save the current animation configuration.
---
function Anima:__push()
    if not self.__configuration then
        self.__configuration = {}
    end

    self.__configuration.scale = { x = self.__scale.x, y = self.__scale.y }
    self.__configuration.color = self.__color
    self.__configuration.direction = self.__direction
    self.__configuration.rotation = self.__rotation
    self.__configuration.speed = self.__speed
    self.__configuration.flip = { x = self.__flip.x, y = self.__flip.y }
    self.__configuration.kx = self.__kx
    self.__configuration.ky = self.__ky
    self.__configuration.current_frame = self.__current_frame
end

--
---Configure the animation with the last configuration. Should be used after "__push" method.
---
function Anima:__pop()
    if not self.__configuration then
        return
    end

    self.__scale = {
        x = self.__configuration.scale.x,
        y = self.__configuration.scale.y
    }

    self.__color = {
        self.__configuration.color[1], self.__configuration.color[2],
        self.__configuration.color[3], self.__configuration.color[4] or 1
    }
    self.__direction = self.__configuration.direction
    self.__rotation = self.__configuration.rotation
    self.__speed = self.__configuration.speed

    self.__flip = {
        x = self.__configuration.flip.x,
        y = self.__configuration.flip.y
    }

    self.__kx = self.__configuration.kx
    self.__ky = self.__configuration.ky

    -- self.__current_frame = self.__configuration.current_frame

    self.__configuration = nil
end

function Anima:__get_configuration()
    return self.__configuration
end

function Anima:__set_configuration(config)
    self.__configuration = config
end

--- Enabla a custom action to execute in animation update method.
---@param custom_action function
---@param args any
function Anima:set_custom_action(custom_action, args)
    self.__custom_action = custom_action
    self.__custom_action_args = args
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
        (self.__max_rows and self.__row_count >= self.__max_rows) then

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

            self.__row_count = (self.__row_count + 1) % 6000000

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
                    self.__row_count = (self.__row_count + 1) % 600000

                    if self:__is_stopping_in_the_end() then
                        self.__stopped = true
                        self.__current_frame = self.__amount_frames
                    end

                else -- ELSE: animation is in "come and back" state

                    self.__current_frame = self.__amount_frames
                    self.__frame_time = self.__frame_time + self.__speed
                    self.__direction = -self.__direction

                    if self.__direction == self.__initial_direction then
                        self.__row_count = (self.__row_count + 1) % 600000
                    end

                    if self:__is_stopping_in_the_end()
                        and self.__direction == self.__initial_direction then

                        self.__stopped = true
                    end
                end -- END ELSE animation in "come and back" state

            end -- END ELSE if animation is repeating

        else -- ELSE direction is negative

            if self.__current_frame < 1 then

                if self:__is_repeating() then
                    self.__current_frame = self.__amount_frames
                    self.__row_count = (self.__row_count + 1) % 600000

                    if self:__is_stopping_in_the_end() then
                        self.__stopped = true
                        self.__current_frame = 1
                    end

                else -- ELSE animation is not repeating
                    self.__current_frame = 1
                    self.__frame_time = self.__frame_time + self.__speed
                    self.__direction = self.__direction * -1

                    if self.__direction == self.__initial_direction then
                        self.__row_count = (self.__row_count + 1) % 600000
                    end

                    if self:__is_stopping_in_the_end()
                        and self.__direction == self.__initial_direction then

                        self.__stopped = true
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
    if not self.__is_visible then return end

    love.graphics.push()

    self:__draw_with_no_effects__(x, y)

    love.graphics.pop()

    -- Drawing the effects, if some exists.
    self.__effect_manager:draw(x, y)
end

---
--- Draw the animation using a rectangle.
---@param x number # Rectangle top-left position (x-axis).
---@param y number # Rectangle top-left position (y-axis).
---@param w number # Rectangle width in pixels.
---@param h number # Rectangle height in pixels.
function Anima:draw_rec(x, y, w, h)
    x = x + w / 2.0
    y = y + h
        - self.__bottom * self.__scale.y
        + self.__origin.y * self.__scale.y

    if self:__is_flipped_in_y() then
        y = y - h + (self.__bottom * self.__scale.y)
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

    self.__quad:setViewport(
        self.__pos_in_texture.x + self.__frame_size.x
        * math.floor((self.__current_frame - 1) % self.__grid.x),

        self.__pos_in_texture.y + self.__frame_size.y
        * math.floor((self.__current_frame - 1) / self.__grid.x),

        self.__frame_size.x,
        self.__frame_size.y,
        self.__img:getWidth(), self.__img:getHeight()
    )

    love.graphics.setColor(self.__color)

    love.graphics.draw(self.__img, self.__quad,
        math.floor(x), math.floor(y),
        self.__rotation, self.__scale.x * self.__flip.x,
        self.__scale.y * self.__flip.y,
        self.__origin.x, self.__origin.y,
        self.__kx,
        self.__ky
    )
end

--- Aplica efeito na animacao.
---@param effect_type JM_effect_id_string|JM_effect_id_number
---@param effect_args any
---@return JM_Effect effect
function Anima:apply_effect(effect_type, effect_args)
    return self.__effect_manager:apply_effect(self, effect_type, effect_args)
end

---Stops a especific effect by his unique id.
---@param effect_id number
---@return boolean
function Anima:stop_effect(effect_id)
    return self.__effect_manager:stop_effect(effect_id)
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
    return self.__current_state == ANIMA_STATES.repeating
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
        return true
    end
    return false
end

function Anima:unpause()
    if self.__stopped then
        self.__stopped = false
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
