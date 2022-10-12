--[[ Lua library for animation in Love2D.

    Some of the main functions include:

    * :new -- Class constructor.
    * :config -- Configure animation fields.
    * :update --
    * :draw --
    * :draw_rec --

    @author Joao Moreira, 2022.
]]

--
--- @class Anima
--
local Anima = {}

local ANIMA_STATES = {
    repeating = 1,
    come_and_back = 2,
    random = 3
}

---
--- Animation class constructor.
---
--- @param param {img: love.Image, frames: number, frame_size: table, speed: number, angle: number, color: table, scale: table, origin: table, pos_in_texture: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, kx: number, ky: number} # A table containing the following fields:
-- * img (Required): The source image for animation (could be a Love.Image or a string containing the file path). All the frames in the source image should be in the horizontal.
-- * frames: The amount of frames in the animation.
-- * frame_size: A table with the animation's frame size. Should contain the index x (width) and y (height).
-- * speed: Time in seconds to update frame.
-- * pos_in_texture: Optional table parameter to indicate where the animation is localized in the image. Useful when there is a lot of animation in one single image (default value is {x=0, y=0}).
--- @return table animation # A instance of Anima class.
function Anima:new(param)
    if not param then return {} end

    local animation = {}
    setmetatable(animation, self)
    self.__index = self

    Anima.__constructor__(animation, param)

    return animation
end

--- Configure the animation fields.
---
--- @param param {img: love.Image,frames: number, frame_size: table, speed: number, angle: number, color: table, scale: table, origin: table, pos_in_texture: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, max_rows: number, state: string, bottom: number, grid: table, kx: number, ky: number}  # A table containing the follow fields:
---
function Anima:__constructor__(param)

    self:set_img(param.img)

    self.__amount_frames = param.frames or 1
    self.__frame_time = 0.
    self.__update_time = 0.
    self.__stopped_time = 0.
    self.__row_count = 0
    self.__is_visible = true
    self.__is_enabled = true
    self.__initial_direction = nil
    self.__current_state = ANIMA_STATES.repeating
    self.__direction = (param.is_reversed and -1) or 1
    self.__color = param.color or { 1, 1, 1, 1 }
    self.__angle = param.angle or 0.
    self.__speed = param.speed or 0.3
    self.__current_frame = (self.__direction < 0 and self.__amount_frames) or 1
    self.__stop_at_the_end = param.stop_at_the_end or false
    self.__max_rows = param.max_rows or nil

    self:set_frame_size(param.frame_size)

    self.__bottom = param.bottom or self.__frame_size.y

    self:set_state(param.state)

    self.__grid = {
        x = param.grid and param.grid.x or self.__amount_frames,
        y = param.grid and param.grid.y or 1
    }

    self:set_flip({ x = param.flip_x, y = param.flip_y })

    self:set_origin(param.origin)

    self:set_pos_in_texture(param.pos_in_texture)

    self:set_scale(param.scale)

    self.__effects_list = {}

    if param.frame_size or not self.__quad then
        self.__quad = love.graphics.newQuad(0, 0,
            self.__frame_size.x,
            self.__frame_size.y,
            self.__img:getDimensions()
        )
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

--
--- Set state.
---@param state string Possible values are "repeating", "random" or "come and back". If none of these is informed, then the state is setted as "repeating".
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
    if not self.__last_config then
        self.__last_config = {}
    end

    self.__last_config.scale = { x = self.__scale.x, y = self.__scale.y }
    self.__last_config.color = self.__color
    self.__last_config.direction = self.__direction
    self.__last_config.angle = self.__angle
    self.__last_config.speed = self.__speed
    self.__last_config.flip = { x = self.__flip.x, y = self.__flip.y }
    self.__last_config.kx = self.__kx
    self.__last_config.ky = self.__ky
    self.__last_config.current_frame = self.__current_frame
end

--
---Configure the animation with the last configuration. Should be used after "__push" method.
---
function Anima:__pop()
    if not self.__last_config then
        return
    end

    self.__scale = {
        x = self.__last_config.scale.x,
        y = self.__last_config.scale.y
    }

    self.__color = {
        self.__last_config.color[1], self.__last_config.color[2],
        self.__last_config.color[3], self.__last_config.color[4] or 1
    }
    self.__direction = self.__last_config.direction
    self.__angle = self.__last_config.angle
    self.__speed = self.__last_config.speed

    self.__flip = {
        x = self.__last_config.flip.x,
        y = self.__last_config.flip.y
    }

    self.__kx = self.__last_config.kx
    self.__ky = self.__last_config.ky
    self.__current_frame = self.__last_config.current_frame

    self.__last_config = nil
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

    if self.__stopped or
        (self.__max_rows and self.__row_count >= self.__max_rows) then

        self.__stopped_time = (self.__stopped_time + dt) % 5000000
        return
    end

    self.__update_time = self.__update_time + dt

    if self.__update_time >= self.__speed then
        self.__update_time = self.__update_time - self.__speed

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
                    self.__update_time = self.__update_time + self.__speed
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
                    self.__update_time = self.__update_time + self.__speed
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
    love.graphics.push()

    self:draw_with_no_effects(x, y)

    love.graphics.pop()

    if self.__effects_list then
        for i = #self.__effects_list, 1, -1 do
            local r = self.__effects_list[i].draw
                and self.__effects_list[i]:draw(x, y)
        end
    end
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

---
--- Draw the animation without apply any effect.
---
---@param x number # The top-left position to draw (x-axis).
---@param y number # The top-left position to draw (y-axis).
function Anima:draw_with_no_effects(x, y)

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

    if not self.__is_visible then return end

    love.graphics.draw(self.__img, self.__quad,
        math.floor(x), math.floor(y),
        self.__angle, self.__scale.x * self.__flip.x,
        self.__scale.y * self.__flip.y,
        self.__origin.x, self.__origin.y,
        self.__kx,
        self.__ky
    )
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

return Anima
