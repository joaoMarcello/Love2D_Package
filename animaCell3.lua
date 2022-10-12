--[[ Lua library for do animation in Love2D.

    @author Joao Moreira, 2022.
]]

local Anima = {}

local ANIMA_STATES = {
    repeating = 1,
    come_and_back = 2,
    random = 3
}

---
--- Animation class constructor.
--- @param param? {img: love.Image, frames: number, angle: number} # A table containing the following fields:
-- * img: (Required) The source image for animation (could be a image object or a string containing the path to the image). All the frames in the source image should be in the horizontal.
-- * frames: The amount of frames in the animation.
-- * frame_size: A table with the animation's frame size. Should contain the index x (width) and y (height).
-- * speed: Time in seconds to update frame.
-- * pos_in_texture: Optional table parameter to indicate where the animation is localized in the image. Useful when there is a lot of animation in one single image (default value is {x=0, y=0}).
--- @return table animation # A instance of Anima class.
function Anima:new(param)
    local animation = {}
    setmetatable(animation, self)
    self.__index = self

    if type(param.img) == "string" then
        animation.__img = love.graphics.newImage(param.img)
    else
        animation.__img = param.img
    end
    animation.__img:setFilter("linear", "nearest")

    animation.__frame_time = 0.
    animation.__update_time = 0.
    animation.__stopped_time = 0.
    animation.__row_count = 0
    animation.__is_visible = true
    animation.__is_enabled = true
    animation.__initial_direction = nil
    animation.__current_state = ANIMA_STATES.repeating
    animation.__direction = (param.is_reversed and -1) or 1
    animation.__color = param.color or { 1, 1, 1, 1 }
    animation.__angle = param.angle or 0.
    animation.__speed = param.speed or 0.05
    animation.__amount_frames = param.frames or 1

    animation.__grid = { x = animation.__amount_frames, y = 1 }

    animation.__frame_size = {
        x = (param.frame_size and param.frame_size.x)
            or animation.__img:getWidth() / animation.__amount_frames,
        y = (param.frame_size and param.frame_size.y)
            or animation.__img:getHeight()
    }

    animation.__origin = {
        x = param.origin and param.origin.x or animation.__frame_size.x / 2,
        y = (param.origin and param.origin.y) or animation.__frame_size.y / 2
    }

    animation.__flip = {
        x = (param.flip_x and -1) or 1,
        y = (param.flip_y and -1) or 1
    }

    animation.__pos_in_texture = {
        x = (param.pos_in_texture and param.pos_in_texture.x) or 0,
        y = (param.pos_in_texture and param.pos_in_texture.y) or 0
    }

    animation.__scale = {
        x = (param.scale and param.scale.x)
            or 1.,
        y = (param.scale and param.scale.y)
            or 1.
    }

    animation.__kx = 0
    animation.__ky = 0

    animation:config(param)

    return animation
end

---
--- Configure the animation instance.
--- @param param table # Same as in the constructor function.
--- @param param.frames integer # Frames.
function Anima:config(param)
    self.__amount_frames = param.frames or self.__amount_frames

    self.__frame_size = {
        x = (param.frame_size and param.frame_size.x)
            or self.__frame_size.x,
        y = (param.frame_size and param.frame_size.y)
            or self.__frame_size.y
    }

    self.__direction = (param.is_reversed and -1) or self.__direction
    self.__current_frame = (self.__direction < 0 and self.__amount_frames) or 1
    self.__stop_at_the_end = param.stop_at_the_end or self.__stop_at_the_end
    self.__max_rows = param.max_rows or self.__max_rows

    if param.state == "random" then
        self.__current_state = ANIMA_STATES.random
    elseif param.state == "come_and_back"
        or param.state == "come and back" then

        self.__current_state = ANIMA_STATES.come_and_back
    end

    self.__color = param.color or self.__color
    self.__angle = param.angle or self.__angle
    self.__speed = param.speed or self.__speed
    self.__bottom = param.bottom or self.__frame_size.y

    self.__flip = {
        x = (param.flip_x and -1) or self.__flip.x,
        y = (param.flip_y and -1) or self.__flip.y
    }

    self.__origin = {
        x = (param.origin and param.origin.x) or self.__origin.x,
        y = (param.origin and param.origin.y) or self.__origin.y
    }

    self.__pos_in_texture = {
        x = (param.pos_in_texture and param.pos_in_texture.x)
            or self.__pos_in_texture.x,
        y = (param.pos_in_texture and param.pos_in_texture.y)
            or self.__pos_in_texture.y
    }

    self.__scale = {
        x = (param.scale and param.scale.x)
            or self.__scale.x,
        y = (param.scale and param.scale.y)
            or self.__scale.y
    }

    if param.frame_size or not self.__quad then
        self.__quad = love.graphics.newQuad(0, 0,
            self.__frame_size.x,
            self.__frame_size.y,
            self.__img:getDimensions()
        )
    end

    collectgarbage("collect")
end

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

---
-- Execute the animation logic.
---@param dt number # the delta time.
function Anima:update(dt)
    self.__update_time = (self.__update_time + dt) % 500000.
    if not self.__is_enabled then return end

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

                else -- ELSE animation is in "come and back" state

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
                end -- END ELSE animation not in repeating state

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
--- Draw the animation.
---
---@param x number # The top-left position to draw in the x-axis.
---@param y number # The top-left position to draw in the y-axis.
function Anima:draw(x, y)
    -- self.__quad:setViewport(
    --     self.__pos_in_texture.x
    --     + self.__frame_size.x
    --     * ((self.__current_frame - 1) % self.__grid.x),
    --     self.__pos_in_texture.y + self.__frame_size.y * math.floor((self.__current_frame - 1) / self.__grid.y),
    --     self.__frame_size.x,
    --     self.__frame_size.y
    -- )

    self.__quad:setViewport(self.__pos_in_texture.x + self.__frame_size.x * ((self.__current_frame - 1) % self.__grid.x)
        ,
        self.__pos_in_texture.y + self.__frame_size.y * math.floor((self.__current_frame - 1) / self.__grid.x),
        self.__frame_size.x,
        self.__frame_size.y)
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

function Anima:__is_flipped_in_y()
    return self.__flip.y < 0
end

function Anima:__is_flipped_in_x()
    return self.__flip.x < 0
end

---
--- Tells if animation should stop in the last frame.
---
---@return boolean
function Anima:__is_stopping_in_the_end()
    return self.__stop_at_the_end
end

function Anima:__is_repeating()
    return self.__current_state == ANIMA_STATES.repeating
end

function Anima:__is_random()
    return self.__current_state == ANIMA_STATES.random
end

--- Tells if the animation is normal mode.
---@return boolean
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
