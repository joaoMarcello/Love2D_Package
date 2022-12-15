-- ---@class JM.Anima.Frame
-- local Frame = {}

-- ---@param args {left: number, right:number, top:number, bottom:number}
-- function Frame:new(args)
--     local obj = {}
--     setmetatable(obj, self)
--     self.__index = self

--     Frame.__constructor__(obj, args)

--     return obj
-- end

-- --- Constructor.
-- ---@param args {left: number, right:number, top:number, bottom:number}
-- function Frame:__constructor__(args)
--     local left = args.left or args[1]
--     local top = args.top or args[3]
--     local right = args.right or args[2]
--     local bottom = args.bottom or args[4]

--     self.x = left
--     self.y = top
--     self.w = right - left
--     self.h = bottom - top
--     self.ox = self.w / 2
--     self.oy = self.h / 2

--     self.bottom = self.y + self.h
-- end

-- function Frame:get_offset()
--     return self.ox, self.oy
-- end

-- --- Sets the Quad Viewport.
-- ---@param img love.Image
-- ---@param quad love.Quad
-- function Frame:setViewport(img, quad)
--     quad:setViewport(
--         self.x, self.y,
--         self.w, self.h,
--         img:getWidth(), img:getHeight()
--     )
-- end

-- return Frame
