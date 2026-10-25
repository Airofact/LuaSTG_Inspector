---@diagnostic disable: inject-field
---@diagnostic disable: undefined-field

local IndicatorHandle = {}
IndicatorHandle.__index = IndicatorHandle

function IndicatorHandle:is_valid()
    return self.renderer.indicators[self.id] ~= nil
end

function IndicatorHandle:dispose()
    self.renderer:remove(self)
    return self
end

function IndicatorHandle:set_color(color)
    local indicator = self.renderer.indicators[self.id]
    if indicator then
        indicator.color = color
    end
    return self
end

local AtomicIndicatorRenderer = plus.Class()
AtomicIndicatorRenderer.Handle = IndicatorHandle

function AtomicIndicatorRenderer:init()
    self.next_id = 0
    self.indicators = {}
end

function AtomicIndicatorRenderer:add(data, handle_type)
    self.next_id = self.next_id + 1
    local id = self.next_id
    self.indicators[id] = data
    local handle = setmetatable({ renderer = self, id = id }, handle_type or IndicatorHandle)
    return id, handle
end

function AtomicIndicatorRenderer:_release_indicator(_indicator)
end

function AtomicIndicatorRenderer:remove(target)
    local id = target
    if type(target) == "table" then
        if target.renderer ~= self then return false end
        id = target.id
    end

    local indicator = self.indicators[id]
    if not indicator then return false end

    self:_release_indicator(indicator)
    self.indicators[id] = nil
    return true
end

function AtomicIndicatorRenderer:clear()
    for id, indicator in pairs(self.indicators) do
        self:_release_indicator(indicator)
        self.indicators[id] = nil
    end
end

---子类重写
function AtomicIndicatorRenderer:render(_cfg)
end

return AtomicIndicatorRenderer
