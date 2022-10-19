local Font = {}
local defaultSpaceBetweenLines = 25
local defaultSpaceBetweenCharacters = 2

local pathName = {
    [1] = "a", [2] = "b", [3] = "c", [4]="d", [5]="e", [6]="f", [7]="g", [8]="h", [9]="i", [10]="j", [11]="k", [12]="l", [13]="m", [14]="n", [15]="o", [16]="p", [17]="q", [18]="r", [19]="s", [20]="t", [21]="u", [22]="v", [23]="w", [24]="x", [25]="y", [26]="z", [27]="0", [28]="1", [29]="2", [30]="3", [31]="4", [32]="5", [33]="6", [34]="7", [35]="8", [36]="9", [37]="bar", [38]="exclamation", [39]="interrogation", [40]="line", [41]="underline", [42]="point", [43]="percent", [44]="space", [45] = "a_", [46] = "b_", [47] = "c_", [48]="d_", [49]="e_", [50]="f_", [51]="g_", [52]="h_", [53]="i_", [54]="j_", [55]="k_", [56]="l_", [57]="m_", [58]="n_", [59]="o_", [60]="p_", [61]="q_", [62]="r_", [63]="s_", [64]="t_", [65]="u_", [66]="v_", [67]="w_", [68]="x_", [69]="y_", [70]="z_", [71]="left_par", [72]="right_par", [73]="left_key", [74]="right_key", [75]="left_bracket", [76]="right_bracket", [77]="sum", [78]="vertical_bar", [79]="two_points", [80]="semicolon", [81]="same", [82]="comma", [83]="asterisc", [84]="hashtag", [85]="e_commerce", [86]="circumflex", [87]="til", [88]="simple_quotes", [89]="á", [90]="á_", [91]="à", [92]="à_", [93]="ã", [94]="ã_", [95]="â", [96]="â_", [97]="ee", [98]="é_", [99]="è", [100]="è_", [101]="ê", [102]="ê_", [103]="í", [104]="í_", [105]="î", [106]="î_", [107]="ì", [108]="ì_", [109]="ó", [110]="ó_", [111]="ò", [112]="ò_", [113]="ô", [114]="ô_", [115]="õ", [116]="õ_", [117]="ú", [118]="ú_", [119]="ù", [120]="ù_", [121]="ç",[122]="ç_", [123]="arroba", [124]="û", [125]="û_", [126]="smaller", [127]="bigger"
}
Font.pathName = pathName

local id = {
    [1] = "a", [2] = "b", [3] = "c", [4]="d", [5]="e", [6]="f", [7]="g", [8]="h", [9]="i", [10]="j", [11]="k", [12]="l", [13]="m", [14]="n",
    [15]="o", [16]="p", [17]="q", [18]="r", [19]="s", [20]="t", [21]="u", [22]="v", [23]="w", [24]="x", [25]="y", [26]="z", [27]="0", [28]="1", [29]="2", [30]="3", [31]="4", [32]="5", [33]="6", [34]="7", [35]="8", [36]="9", [37]="/", [38]="!", [39]="?", [40]="-", [41]="_", [42]=".", [43]="%", [44]=" ", [45] = "A", [46] = "B", [47] = "C", [48]="D", [49]="E", [50]="F", [51]="G", [52]="H", [53]="I", [54]="J", [55]="K", [56]="L", [57]="M", [58]="N", [59]="O", [60]="P", [61]="Q", [62]="R", [63]="S", [64]="T", [65]="U", [66]="V", [67]="W", [68]="X", [69]="Y", [70]="Z", [71]="(", [72]=")", [73]="{", [74]="}", [75]="[", [76]="]", [77]="+", [78]="|", [79]=":", [80]=";", [81]="=", [82]=",",
    [83]="*", [84]="#", [85]="&", [86]="^", [87]="~", [88]="'", [89]="á", [90]="Á", [91]="à", [92]="À", [93]="ã", [94]="Ã", [95]="â", [96]="Â", [97]="é", [98]="É", [99]="è", [100]="È", [101]="ê", [102]="Ê", [103]="í", [104]="Í", [105]="î", [106]="Î", [107]="ì", [108]="Ì",
    [109]="ó", [110]="Ó", [111]="ò", [112]="Ò", [113]="ô", [114]="Ô", [115]="õ", [116]="Õ", [117]="ú", [118]="Ú", [119]="ù", [120]="Ù", [121]="ç", [122]="Ç", [123]="@", [124]="û", [125]="Û", [126]="<", [127]=">"
}
Font.id = id



function Font:new(path)
    local f = {}
    setmetatable(f, self)
    self.__index = self

    f.img = {}
    f.quad = {}
    f.h = 0
    f.scale = 0.7
    f.spaceBetween = defaultSpaceBetweenCharacters
    f.spaceBetweenLines = defaultSpaceBetweenLines
    f.color = {255,255,255, 255}
    f.limits = {top=0, left=0, right = love.graphics.getWidth(), bottom=love.graphics.getHeight()}

    f.m = 0
    f.amount = 0

    for i=1, #pathName do
        if pcall(function() table.insert(f.img, love.graphics.newImage(path.."/"..pathName[i]..".png"))   end) then
            table.insert(f.quad, love.graphics.newQuad(0,0,f.img[i]:getWidth(), f.img[i]:getHeight(), f.img[i]:getDimensions()))
            if f.img[i]:getHeight()  > f.h then f.h = f.img[i]:getHeight() end 
            f.m = f.m + f.img[i]:getWidth()
            f.amount = f.amount + 1
        else
            table.insert(f.img, 0)
            table.insert(f.quad, 0)
        end

        :: continue ::
    end

    if type(f.img[12]) ~= "number" then f.h = f.img[12]:getHeight() end


    f.m = f.m/f.amount
    if type(f.img[5]) ~= "number" then f.m = f.img[5]:getWidth() end
    
    if f.h == 0 then f.h = 30 end

    f.defaultHeight = f.h
    f.h = f.h * f.scale
    return f
end
--

function Font:addMark(markName, markImg)
    if not self.marks then self.marks = {} end
    local markSize = #markName

    while #markName < 4 do
        markName = markName.."*"
    end
    while #markName > 4 do
        markName = markName:sub(1, #markName-1)
        markSize = 4
    end

    if type(markImg) == "string" then markImg = love.graphics.newImage(markImg) end

    local quad = markImg and love.graphics.newQuad(0,0,markImg:getWidth(), markImg:getHeight(), markImg:getDimensions()) or 0
    table.insert(self.marks, {name=markName, img=markImg, quad=quad, size=markSize })

    --table.insert(self.id, markName)
    --table.insert(self.pathName, markName)
    --table.insert(self.img, markImg)
end


function Font:isMark(ind, str)
    if not self.marks then return false end
    local c = str:sub(ind, ind + 3)

    for k=1, #self.marks do
        if c == self.marks[k].name or
        (c:sub(1, 2) == self.marks[k].name:sub(1, 2) and self.marks[k].size==2) or
        (c:sub(1, 1) == self.marks[k].name:sub(1, 1) and self.marks[k].size==1) or
        (c:sub(1, 3) == self.marks[k].name:sub(1, 3) and self.marks[k].size==3) then--]]
            return self.marks[k]
        end
    end
    return false
end


local function searchMark(m, marks)
    if not marks then return end

    for k=1, #marks do
        if m == marks[k].name or
        (m:sub(1, 2) == marks[k].name:sub(1, 2) and marks[k].size==2) or
        (m:sub(1, 1) == marks[k].name:sub(1, 1) and marks[k].size==1) or
        (m:sub(1, 3) == marks[k].name:sub(1, 3) and marks[k].size==3) then
            return k, marks[k]
        end
    end
    return false
end
--
local function getIndex(c)
    for i=1, #pathName do
        if id[i] == c then return i end
    end
    return nil--39
end
--

local function countBrokenLine(s)
    local c = 0

    local inf, sup = s:find("\n")

    while inf do
        c= c + 1
        local r = s:sub(inf + 1, #s):find("\n")
        inf  = r and (r + inf) or nil
    end

    return c
end

--
function Font:addInterval(s, inf, sup, color)
    if not self.intervals then self.intervals = {} end
    local interval = {inf = inf or 1, sup = sup or 1, color = color or {255, 0, 0}}


    local count = countBrokenLine(s:sub(interval.inf, interval.sup))

    interval.sup = interval.sup + count
    while s:sub(interval.sup, interval.sup) == "\n" do
        interval.sup = interval.sup + 1
    end

    table.insert(self.intervals, interval)
    return interval
end

--
function Font:draw(s, x, y)
    s = tostring(s)
    local tempY = 0
    local inicialX = x

    local findMark = false
    local ind, mark, result

    for i=1, #s do
        if findMark then
            findMark = findMark + 1;
            if findMark <= mark.size then goto continue end
        end
        findMark = false

        ind, mark = searchMark(s:sub(i,i+3), self.marks)
        if ind then findMark = 1 end
        if not ind then ind = getIndex(s:sub(i,i)) end
        if not ind then ind = getIndex(s:sub(i,i+1)); end--if ind then i = i + 1 end  end
        if not ind and s:sub(i,i) ~= "\n" then goto continue end

        love.graphics.setColor(self.color)
        if self.esp then
            if self.intervals then
                for k, intervals in ipairs(self.intervals) do
                    local color = intervals.color

                    if i >= intervals.inf and i <= intervals.sup then love.graphics.setColor(intervals.color or {255,0,0}) end
                end
            end
        end

        if s:sub(i,i) == "\n" then x = inicialX; tempY = tempY + self.h + self.spaceBetweenLines; goto continue end 


        if type(self.img[ind]) == "number" then
            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("fill", x, tempY + y, self.m*self.scale, self.h)
            x = x + self.m*self.scale + self.spaceBetween
            goto continue

        elseif findMark then
            love.graphics.setColor(255,255,255)
            local sx, sy =(self.h + 10)/self.marks[ind].img:getWidth(), (self.h + 10)/self.marks[ind].img:getHeight()
            local dy = math.floor(tempY + y)-5
            if dy + self.marks[ind].img:getHeight() * sy < self.limits.top then goto continue end

            local r = self:adjustQuad(self.marks[ind].img, self.marks[ind].quad, math.floor(x),dy, self.h+10, self.marks[ind].img:getHeight() * sy)

            if not r then
                love.graphics.draw(self.marks[ind].img, self.marks[ind].quad, math.floor(x), dy < self.limits.top and self.limits.top or dy, 0.0, sx, sy,0 )
            end
            x = x + self.h + 10 + self.spaceBetween
            goto continue
        end

        local py =  tempY + y + self.h  - self.img[ind]:getHeight()*self.scale
        if ind==7 or ind== 10 or ind==16 or ind==17 or ind==25 or ind==61 or ind==80 or ind==82 or ind==121 or ind==122 then py = py + self.defaultHeight * self.scale * 0.2 end-- + self.img[ind]:getHeight()*self.scale/3.0 end


        if py > self.limits.bottom or py + self.img[ind]:getHeight()*self.scale < self.limits.top
        then goto continue1 end

        if py < -self.img[ind]:getHeight()*self.scale
        or x > love.graphics.getWidth() or x < -self.img[ind]:getWidth()*self.scale
        then goto continue1 end


        result= self:adjustQuad(self.img[ind], self.quad[ind], x, py, self.img[ind]:getWidth()*self.scale, self.img[ind]:getHeight()*self.scale)
        if not result then
            love.graphics.draw(self.img[ind], self.quad[ind], x < self.limits.left and self.limits.left or  x, py < self.limits.top and self.limits.top or py , 0, self.scale, self.scale, 0, 0)
        end
        :: continue1 :: 
        x = x + self.img[ind]:getWidth() * self.scale + self.spaceBetween
        :: continue ::
    end

end

function Font:adjustQuad(img, quad, x, y, w, h)
    local tam = self.h
    local num

    quad:setViewport(0,0, img:getWidth(),img:getHeight())

    if y > self.limits.bottom or y + h < self.limits.top or x + w < self.limits.left or x > self.limits.right then
        return true
    elseif y + h > self.limits.bottom then
        tam = self.limits.bottom - y
        num =  ((img:getHeight()*tam)/(1.000*h))
        quad:setViewport(0,0, img:getWidth(),num)
    end

    if y < self.limits.top then
        tam = self.limits.top - y
        num = ((img:getHeight()*tam)/(1.000*h))
        quad:setViewport(0,num, img:getWidth(),img:getHeight()-num)
    end

    local qx, qy, qw, qh = quad:getViewport()

    if x < self.limits.left then
        tam = self.limits.left - x
        num =  ((img:getWidth()*tam)/(1.000*w))
        quad:setViewport(num , qy, qw-num, qh)
    end

    qx, qy, qw, qh = quad:getViewport()

    if x + w > self.limits.right then
        tam = x + w - self.limits.right 
        num =  ((img:getWidth()*tam)/(1.000*w))
        quad:setViewport(qx, qy, qw-num, qh)
    end

end

function Font:especialDraw(s, x, y)
    self.esp = true
    self:draw(s, x, y)
    self.esp = nil
end


function Font:setHeight(h)
    self.scale = h / self.defaultHeight
    self.h = self.defaultHeight * self.scale
    self.spaceBetweenLines = defaultSpaceBetweenLines * self.scale
end

function Font:getSizeString(s)
    local w, h = 0, self.h
    local biggest = 0
    local findMark = false
    local ind, mark

    for i=1, #s do
        if findMark then
            findMark = findMark + 1;
            if findMark <= mark.size then goto continue end
        end
        findMark = false

        if s:sub(i,i) == "\n" then 
            if w > biggest then biggest = w end
            w = 0
            h = h + self.h + self.spaceBetweenLines
            goto continue
        end


        ind, mark = searchMark(s:sub(i,i+3), self.marks)
        if ind then findMark = 1 end
        if not ind then ind = getIndex(s:sub(i,i)) end
        if not ind then ind = getIndex(s:sub(i,i+1)); end--if ind then i = i + 1 end  end
        if not ind then goto continue end

        if type(self.img[ind]) == "number" then w = w + self.m*self.scale + self.spaceBetween
        elseif findMark then
            w = w + self.h + 10 + self.spaceBetween
        else
            w = w + self.img[ind]:getWidth() * self.scale + self.spaceBetween
        end

        if w > biggest then biggest = w end
        :: continue ::
    end

    return biggest, h
end

function Font:catch()
    local c = {}
    c.scale = self.scale
    c.spaceBetween = self.spaceBetween
    c.color = self.color
    c.h = self.h
    c.limits = self.limits

    self.c = c
end

function Font:pop()
    if not self.c then return end
    self.scale = self.c.scale
    self.spaceBetween = self.c.spaceBetween
    self.color = self.c.color
    self.limits = self.c.limits
    self.intervals = nil
    self:setHeight(self.c.h)
end

function Font:getScale(h)
    self:catch()
    self:setHeight(h)
    local scale = self.scale
    self:pop()
    return scale
end

function Font:drawCenter(s, x, y)
    s = tostring(s)
    self:draw(s, x - self:getSizeString(s)/2, y)
end

function Font:especialDrawCenter(s, x, y)
    self.esp = true
    self:drawCenter(s, x, y)
    self.esp = nil
end

function Font:drawRec(s, x, y, w, h)
    s = tostring(s)
    local width, height = self:getSizeString(s)
    self:especialDrawCenter(s, x + w/2, y + h/2 - height/2)
end

return Font
