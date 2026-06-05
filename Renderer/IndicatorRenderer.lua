---@diagnostic disable: inject-field
---@diagnostic disable: undefined-field

local Atomic = require"Renderer.AtomicIndicatorRenderer"

----------------------------------------
-- Position
----------------------------------------
local PositionIndicatorRenderer = plus.Class(Atomic)

function PositionIndicatorRenderer:init(IMG)
    Atomic.init(self)
    self.IMG = IMG
end

---@param x number
---@param y number
---@param color? lstg.Color
---@return number id
function PositionIndicatorRenderer:add(x, y, color)
    return Atomic.add(self, { x = x, y = y, color = color or Color(255, 255, 255, 255) })
end

---@param unit lstg.GameObject
---@param color? lstg.Color
---@return number id
function PositionIndicatorRenderer:add_for_unit(unit, color)
    return Atomic.add(self, { unit = unit, color = color or Color(255, 255, 255, 255) })
end

function PositionIndicatorRenderer:render(cfg)
    if not cfg.show then return end
    local size, t = cfg.size, cfg.thickness
    for _, ind in pairs(self.indicators) do
        local x, y
        if ind.unit then
            if IsValid(ind.unit) then
                x, y = ind.unit.x or 0, ind.unit.y or 0
            end
        else
            x, y = ind.x, ind.y
        end
        if x then
            SetImageState(self.IMG, "", ind.color)
            Render4V(self.IMG, x - size, y - t / 2, 0.5,
                         x + size, y - t / 2, 0.5,
                         x + size, y + t / 2, 0.5,
                         x - size, y + t / 2, 0.5)
            Render4V(self.IMG, x - t / 2, y - size, 0.5,
                         x + t / 2, y - size, 0.5,
                         x + t / 2, y + size, 0.5,
                         x - t / 2, y + size, 0.5)
        end
    end
end

----------------------------------------
-- Box
----------------------------------------
local BoxIndicatorRenderer = plus.Class(Atomic)

function BoxIndicatorRenderer:init(IMG)
    Atomic.init(self)
    self.IMG = IMG
end

function BoxIndicatorRenderer:add(l, t, r, b, color)
    return Atomic.add(self, { left = l, top = t, right = r, bottom = b, color = color or Color(255, 255, 255, 255) })
end

---@param items table[] @{x, y}[]
function BoxIndicatorRenderer:add_for_items(items, half_w, half_h, color)
    if #items == 0 then return end
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge
    for _, item in ipairs(items) do
        if item.x < min_x then min_x = item.x end
        if item.y < min_y then min_y = item.y end
        if item.x > max_x then max_x = item.x end
        if item.y > max_y then max_y = item.y end
    end
    return self:add(min_x - half_w, min_y - half_h, max_x + half_w, max_y + half_h, color)
end

function BoxIndicatorRenderer:render(cfg)
    if not cfg.show then return end
    local t = cfg.thickness
    for _, hl in pairs(self.indicators) do
        local l, r, tb, b = hl.left, hl.right, hl.top, hl.bottom
        SetImageState(self.IMG, "", hl.color)
        Render4V(self.IMG, l, tb - t / 2, 0.5, r, tb - t / 2, 0.5,
                       r, tb + t / 2, 0.5, l, tb + t / 2, 0.5)
        Render4V(self.IMG, l, b - t / 2, 0.5, r, b - t / 2, 0.5,
                       r, b + t / 2, 0.5, l, b + t / 2, 0.5)
        Render4V(self.IMG, l - t / 2, tb, 0.5, l + t / 2, tb, 0.5,
                       l + t / 2, b, 0.5, l - t / 2, b, 0.5)
        Render4V(self.IMG, r - t / 2, tb, 0.5, r + t / 2, tb, 0.5,
                       r + t / 2, b, 0.5, r - t / 2, b, 0.5)
    end
end

----------------------------------------
-- Polyline
----------------------------------------
local PolylineIndicatorRenderer = plus.Class(Atomic)

function PolylineIndicatorRenderer:init(IMG)
    Atomic.init(self)
    self.IMG = IMG
end

---@param points table[] @{x, y}[] | function[]
---@param color? lstg.Color
---@return number id
function PolylineIndicatorRenderer:add(points, color)
    return Atomic.add(self, {
        points = points,
        color = color or Color(255, 255, 255, 255),
        dynamic = type(points[1]) == "function",
    })
end

function PolylineIndicatorRenderer:render(cfg)
    if not cfg.show then return end
    local t_half = cfg.thickness / 2
    for _, pl in pairs(self.indicators) do
        local pts = pl.points
        if #pts >= 2 then
            SetImageState(self.IMG, "", pl.color)
            if pl.dynamic then
                local ax, ay = pts[1]()
                for i = 2, #pts do
                    local bx, by = pts[i]()
                    local dx, dy = bx - ax, by - ay
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 0 then
                        local px = -dy / len * t_half
                        local py =  dx / len * t_half
                        Render4V(self.IMG, ax + px, ay + py, 0.5,
                                     bx + px, by + py, 0.5,
                                     bx - px, by - py, 0.5,
                                     ax - px, ay - py, 0.5)
                    end
                    ax, ay = bx, by
                end
            else
                local ax, ay = pts[1].x, pts[1].y
                for i = 2, #pts do
                    local bx, by = pts[i].x, pts[i].y
                    local dx, dy = bx - ax, by - ay
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 0 then
                        local px = -dy / len * t_half
                        local py =  dx / len * t_half
                        Render4V(self.IMG, ax + px, ay + py, 0.5,
                                     bx + px, by + py, 0.5,
                                     bx - px, by - py, 0.5,
                                     ax - px, ay - py, 0.5)
                    end
                    ax, ay = bx, by
                end
            end
        end
    end
end

----------------------------------------
-- IndicatorRenderer
----------------------------------------
local IndicatorRenderer = plus.Class()

local function init_img()
    local IMG = "_inspector_crosshair"
    assert(lstg.CheckRes(2, "white"), "Resource 'white' not found")
    CopyImage(IMG, "white")
    SetImageState(IMG, "", Color(255, 255, 255, 255))
    return IMG
end

function IndicatorRenderer:init()
    local IMG = init_img()
    self.positions = PositionIndicatorRenderer(IMG)
    self.boxes = BoxIndicatorRenderer(IMG)
    self.polylines = PolylineIndicatorRenderer(IMG)
end

function IndicatorRenderer:render(cfg)
    self.positions:render(cfg.position)
    self.boxes:render(cfg.box)
    self.polylines:render(cfg.polyline)
end

return IndicatorRenderer()
