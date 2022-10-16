---@class JM.Frame
local Frame = {}

---@param args {x: number, y:number, w:number, h:number}
function Frame:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Frame.__constructor__(obj, args)

    return obj
end

---comment
---@param args {x: number, y:number, w:number, h:number}
function Frame:__constructor__(args)
    self.x = args.x or args[1]
    self.y = args.y or args[2]
    self.w = args.w or args[3]
    self.h = args.h or args[4]
    self.ox = self.w / 2
    self.oy = self.h / 2
    self.bottom = self.y + self.h
end

---comment
---@param img love.Image
---@param quad love.Quad
function Frame:setViewport(img, quad)
    quad:setViewport(
        self.x, self.y,
        self.w, self.h,
        img:getWidth(), img:getHeight()
    )
end

return Frame
