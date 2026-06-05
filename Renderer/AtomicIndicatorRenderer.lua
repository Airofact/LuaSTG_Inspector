---@diagnostic disable: inject-field
---@diagnostic disable: undefined-field

local AtomicIndicatorRenderer = plus.Class()

function AtomicIndicatorRenderer:init()
    self.next_id = 0
    self.indicators = {}
end

function AtomicIndicatorRenderer:add(data)
    self.next_id = self.next_id + 1
    local id = self.next_id
    self.indicators[id] = data
    return id
end

function AtomicIndicatorRenderer:remove(id)
    self.indicators[id] = nil
end

---子类重写
function AtomicIndicatorRenderer:render(_cfg)
end

return AtomicIndicatorRenderer
