---Inspector 核心门面，持有所有单例并协调模块间交互
local Inspector = plus.Class()

function Inspector:init()
    self.config = require"InspectorConfiguration"
    self.object_meta_info = require"Renderer.ObjectMetaInfoRenderer"
    self.instance_info = require"Renderer.InstanceInfoRenderer"
    self.indicator = require"Renderer.IndicatorRenderer"

    self.selected_units = {}
    self.selected_class = nil
    self.owned_indicators = {}
end

function Inspector:add_selected_unit(unit)
    for _, u in ipairs(self.selected_units) do
        if u == unit then return end
    end
    table.insert(self.selected_units, unit)
    local id = self.indicator.positions:add_for_unit(unit, Color(255, 0, 255, 255))
    self.owned_indicators[unit] = id
end

function Inspector:remove_selected_unit(unit)
    for i, u in ipairs(self.selected_units) do
        if u == unit then
            table.remove(self.selected_units, i)
            local id = self.owned_indicators[unit]
            if id then
                self.indicator.positions:remove(id)
                self.owned_indicators[unit] = nil
            end
            return
        end
    end
end

function Inspector:toggle_selected_unit(unit)
    for i, u in ipairs(self.selected_units) do
        if u == unit then
            table.remove(self.selected_units, i)
            local id = self.owned_indicators[unit]
            if id then
                self.indicator.positions:remove(id)
                self.owned_indicators[unit] = nil
            end
            return
        end
    end
    self:add_selected_unit(unit)
end

function Inspector:is_unit_selected(unit)
    for _, u in ipairs(self.selected_units) do
        if u == unit then return true end
    end
    return false
end

function Inspector:clear_selected_units()
    for _, id in pairs(self.owned_indicators) do
        self.indicator.positions:remove(id)
    end
    self.owned_indicators = {}
    self.selected_units = {}
end

function Inspector:get_first_selected_unit()
    return self.selected_units[1]
end

function Inspector:is_unit_first_selected(unit)
    return self.selected_units[1] == unit
end

function Inspector:switch_prime_selected_unit(unit)
    if #self.selected_units <= 1 then return end
    for i, u in ipairs(self.selected_units) do
        if u == unit then
            if i == 1 then return end
            self.selected_units[1], self.selected_units[i] = self.selected_units[i], self.selected_units[1]
            break
        end
    end
end

return Inspector()
