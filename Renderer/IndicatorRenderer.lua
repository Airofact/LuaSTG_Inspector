---@diagnostic disable: inject-field
---@diagnostic disable: undefined-field

local Atomic = require"Renderer.AtomicIndicatorRenderer"

local function extend_handle(parent)
    local handle = {}
    handle.__index = handle
    return setmetatable(handle, { __index = parent })
end

local function resolve_point(point)
    if type(point) == "function" then
        return point()
    end
    if type(point) == "table" then
        return point.x or point[1], point.y or point[2]
    end
end

local function render_line_quad(IMG, ax, ay, bx, by, t_half)
    local dx, dy = bx - ax, by - ay
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 0 then return end

    local px = -dy / len * t_half
    local py =  dx / len * t_half
    Render4V(IMG, ax + px, ay + py, 0.5,
                  bx + px, by + py, 0.5,
                  bx - px, by - py, 0.5,
                  ax - px, ay - py, 0.5)
end

----------------------------------------
-- Position
----------------------------------------
local PositionHandle = extend_handle(Atomic.Handle)
local PositionIndicatorRenderer = plus.Class(Atomic)

function PositionHandle:set_position(x, y)
    local indicator = self.renderer.indicators[self.id]
    if indicator then
        indicator.unit = nil
        indicator.x = x
        indicator.y = y
    end
    return self
end

function PositionHandle:set_unit(unit)
    local indicator = self.renderer.indicators[self.id]
    if indicator then
        indicator.unit = unit
    end
    return self
end

function PositionIndicatorRenderer:init(IMG)
    Atomic.init(self)
    self.IMG = IMG
end

---@param x number
---@param y number
---@param color? lstg.Color
---@return number id, table handle
function PositionIndicatorRenderer:add(x, y, color)
    return Atomic.add(self, {
        x = x,
        y = y,
        color = color or Color(255, 255, 255, 255),
    }, PositionHandle)
end

---@param unit lstg.GameObject
---@param color? lstg.Color
---@return number id, table handle
function PositionIndicatorRenderer:add_for_unit(unit, color)
    return Atomic.add(self, {
        unit = unit,
        color = color or Color(255, 255, 255, 255),
    }, PositionHandle)
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
local BoxHandle = extend_handle(Atomic.Handle)
local BoxIndicatorRenderer = plus.Class(Atomic)

function BoxHandle:set_box(left, top, right, bottom)
    local indicator = self.renderer.indicators[self.id]
    if indicator then
        indicator.left = left
        indicator.top = top
        indicator.right = right
        indicator.bottom = bottom
    end
    return self
end

function BoxIndicatorRenderer:init(IMG)
    Atomic.init(self)
    self.IMG = IMG
end

---@return number id, table handle
function BoxIndicatorRenderer:add(l, t, r, b, color)
    return Atomic.add(self, {
        left = l,
        top = t,
        right = r,
        bottom = b,
        color = color or Color(255, 255, 255, 255),
    }, BoxHandle)
end

---@param items table[] @{x, y}[]
---@return number? id, table? handle
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
local PolylineHandle = extend_handle(Atomic.Handle)
local PolylineIndicatorRenderer = plus.Class(Atomic)

function PolylineHandle:set_polyline(points)
    local indicator = self.renderer.indicators[self.id]
    if indicator and type(points) == "table" then
        indicator.mode = "source"
        indicator.points = points
        indicator.dynamic = type(points[1]) == "function"
    end
    return self
end

function PolylineHandle:set_polyline_count(count)
    local indicator = self.renderer.indicators[self.id]
    if indicator and type(count) == "number" then
        count = math.max(0, math.floor(count))
        indicator.mode = "retained"
        indicator.point_count = count
    end
    return self
end

function PolylineHandle:set_polyline_point(index, x, y)
    local indicator = self.renderer.indicators[self.id]
    if indicator and indicator.mode == "retained" and
            type(index) == "number" and index >= 1 and index <= indicator.point_count then
        index = math.floor(index)
        indicator.x_list[index] = x
        indicator.y_list[index] = y
    end
    return self
end

function PolylineIndicatorRenderer:init(IMG)
    Atomic.init(self)
    self.IMG = IMG
end

---@param points table[] @{x, y}[] | function[]
---@param color? lstg.Color
---@return number? id, table? handle
function PolylineIndicatorRenderer:add(points, color)
    if type(points) ~= "table" then return end
    return Atomic.add(self, {
        mode = "source",
        points = points,
        color = color or Color(255, 255, 255, 255),
        dynamic = type(points[1]) == "function",
        point_count = 0,
        x_list = {},
        y_list = {},
    }, PolylineHandle)
end

function PolylineIndicatorRenderer:render(cfg)
    if not cfg.show then return end
    local t_half = cfg.thickness / 2

    for _, pl in pairs(self.indicators) do
        SetImageState(self.IMG, "", pl.color)
        if pl.mode == "retained" then
            local count = pl.point_count
            if count >= 2 then
                local ax, ay = pl.x_list[1], pl.y_list[1]
                for i = 2, count do
                    local bx, by = pl.x_list[i], pl.y_list[i]
                    if ax ~= nil and ay ~= nil and bx ~= nil and by ~= nil then
                        render_line_quad(self.IMG, ax, ay, bx, by, t_half)
                    end
                    ax, ay = bx, by
                end
            end
        else
            local points = pl.points
            if #points >= 2 then
                local ax, ay = resolve_point(points[1])
                for i = 2, #points do
                    local bx, by = resolve_point(points[i])
                    if ax ~= nil and ay ~= nil and bx ~= nil and by ~= nil then
                        render_line_quad(self.IMG, ax, ay, bx, by, t_half)
                    end
                    ax, ay = bx, by
                end
            end
        end
    end
end

----------------------------------------
-- Bezier
----------------------------------------
local function clamp_node_count(node_count, min_count)
    node_count = math.floor(node_count or min_count)
    if node_count < min_count then return min_count end
    if node_count > 512 then return 512 end
    return node_count
end

local BezierHandle = extend_handle(Atomic.Handle)
local CubicHandle = extend_handle(BezierHandle)
local QuinticHandle = extend_handle(BezierHandle)
local BezierIndicatorRenderer = plus.Class(Atomic)
local EMPTY_OPTIONS = {}

function BezierHandle:set_width(width)
    local indicator = self.renderer.indicators[self.id]
    if indicator and indicator.width ~= width then
        indicator.width = width
        indicator.geometry_dirty = true
    end
    return self
end

function BezierHandle:set_node_count(node_count)
    local indicator = self.renderer.indicators[self.id]
    if indicator then
        if node_count ~= nil then
            node_count = clamp_node_count(node_count, self.renderer.point_count)
        end
        if indicator.node_count ~= node_count then
            indicator.node_count = node_count
            indicator.geometry_dirty = true
        end
    end
    return self
end

local function set_control(indicator, index, x, y)
    if indicator.control_x[index] == x and indicator.control_y[index] == y then
        return false
    end
    indicator.control_x[index] = x
    indicator.control_y[index] = y
    return true
end

function CubicHandle:set_cubic(x1, y1, x2, y2, x3, y3, x4, y4)
    local indicator = self.renderer.indicators[self.id]
    if not indicator then return self end

    local changed = indicator.control_mode ~= "manual"
    indicator.control_mode = "manual"
    indicator.points = nil
    changed = set_control(indicator, 1, x1, y1) or changed
    changed = set_control(indicator, 2, x2, y2) or changed
    changed = set_control(indicator, 3, x3, y3) or changed
    changed = set_control(indicator, 4, x4, y4) or changed
    if changed then indicator.geometry_dirty = true end
    return self
end

function QuinticHandle:set_quintic(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6)
    local indicator = self.renderer.indicators[self.id]
    if not indicator then return self end

    local changed = indicator.control_mode ~= "manual"
    indicator.control_mode = "manual"
    indicator.points = nil
    changed = set_control(indicator, 1, x1, y1) or changed
    changed = set_control(indicator, 2, x2, y2) or changed
    changed = set_control(indicator, 3, x3, y3) or changed
    changed = set_control(indicator, 4, x4, y4) or changed
    changed = set_control(indicator, 5, x5, y5) or changed
    changed = set_control(indicator, 6, x6, y6) or changed
    if changed then indicator.geometry_dirty = true end
    return self
end

function BezierIndicatorRenderer:init(degree)
    Atomic.init(self)
    self.degree = degree
    self.point_count = degree + 1
    self.handle_type = degree == 3 and CubicHandle or QuinticHandle
end

---@param points table[]|function[]
---@param color? lstg.Color
---@param width? number
---@param node_count? number
---@param opts? table
---@return number? id, table? handle
function BezierIndicatorRenderer:add(points, color, width, node_count, opts)
    if type(points) ~= "table" or #points ~= self.point_count then return end
    opts = opts or EMPTY_OPTIONS
    if node_count ~= nil or opts.node_count ~= nil then
        node_count = clamp_node_count(opts.node_count or node_count, self.point_count)
    end

    return Atomic.add(self, {
        data = lstg.BentLaserData(),
        control_mode = "source",
        points = points,
        color = opts.color or color or Color(255, 255, 255, 255),
        width = opts.width or width,
        node_count = node_count,
        texture = opts.texture,
        blend = opts.blend,
        uv_left = opts.uv_left,
        uv_top = opts.uv_top,
        uv_width = opts.uv_width,
        uv_height = opts.uv_height,
        scale = opts.scale,
        control_x = {},
        control_y = {},
        work_x = {},
        work_y = {},
        x_list = {},
        y_list = {},
        geometry_dirty = true,
        built_node_count = nil,
        built_width = nil,
    }, self.handle_type)
end

function BezierIndicatorRenderer:_release_indicator(indicator)
    if indicator.data then
        indicator.data:Release()
        indicator.data = nil
    end
end

function BezierIndicatorRenderer:resolve_control_points(indicator)
    if indicator.control_mode == "manual" then return true end

    for i = 1, self.point_count do
        local x, y = resolve_point(indicator.points[i])
        if x == nil or y == nil then return false end
        if indicator.control_x[i] ~= x or indicator.control_y[i] ~= y then
            indicator.control_x[i] = x
            indicator.control_y[i] = y
            indicator.geometry_dirty = true
        end
    end
    return true
end

function BezierIndicatorRenderer:sample(indicator, node_count)
    local degree = self.degree
    local point_count = self.point_count
    local cx, cy = indicator.control_x, indicator.control_y
    local wx, wy = indicator.work_x, indicator.work_y

    for i = 1, node_count do
        local t = (i - 1) / (node_count - 1)
        for j = 1, point_count do
            wx[j] = cx[j]
            wy[j] = cy[j]
        end
        for r = 1, degree do
            for j = 1, point_count - r do
                wx[j] = wx[j] + (wx[j + 1] - wx[j]) * t
                wy[j] = wy[j] + (wy[j + 1] - wy[j]) * t
            end
        end
        indicator.x_list[i] = wx[1]
        indicator.y_list[i] = wy[1]
    end
end

function BezierIndicatorRenderer:render(cfg)
    if not cfg or not cfg.show then return end

    local min_count = self.point_count
    for _, indicator in pairs(self.indicators) do
        if self:resolve_control_points(indicator) then
            local node_count = clamp_node_count(indicator.node_count or cfg.node_count, min_count)
            local width = indicator.width or cfg.width or 4

            if indicator.geometry_dirty or indicator.built_node_count ~= node_count or indicator.built_width ~= width then
                self:sample(indicator, node_count)
                indicator.data:UpdateAllNode(node_count, indicator.x_list, indicator.y_list, width)
                indicator.geometry_dirty = false
                indicator.built_node_count = node_count
                indicator.built_width = width
            end

            indicator.data:Render(
                indicator.texture or cfg.texture or "laser_bent2",
                indicator.blend or cfg.blend or "mul+add",
                indicator.color,
                indicator.uv_left or cfg.uv_left or 0,
                indicator.uv_top or cfg.uv_top or 0,
                indicator.uv_width or cfg.uv_width or 256,
                indicator.uv_height or cfg.uv_height or 32,
                indicator.scale or cfg.scale or 1
            )
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
    self.beziers3 = BezierIndicatorRenderer(3)
    self.beziers5 = BezierIndicatorRenderer(5)
end

function IndicatorRenderer:clear()
    self.positions:clear()
    self.boxes:clear()
    self.polylines:clear()
    self.beziers3:clear()
    self.beziers5:clear()
end

function IndicatorRenderer:render(cfg)
    self.positions:render(cfg.position)
    self.boxes:render(cfg.box)
    self.polylines:render(cfg.polyline)
    self.beziers3:render(cfg.bezier3)
    self.beziers5:render(cfg.bezier5)
end

return IndicatorRenderer()
