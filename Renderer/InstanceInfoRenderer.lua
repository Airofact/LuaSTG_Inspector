---@diagnostic disable: inject-field
---@diagnostic disable: undefined-field

local InstanceInfoRenderer = plus.Class()

---@param unit lstg.GameObject
---@param cfg table
local function renderHP(unit, cfg)
    if not unit.hp then return end

    if cfg.show_protect and unit.protect then
        SetFontState("bonus", "", Color(0xFF0000FF))
    else
        SetFontState("bonus", "", Color(0xFFFFFFFF))
    end
    RenderText("bonus", unit.hp, unit.x, unit.y, cfg.font_scale, "center", "bottom")
end

---@param enabled_groups table<number, boolean>
---@param cfg table
function InstanceInfoRenderer:render(enabled_groups, cfg)
    if not cfg.show then return end
    for group_id, enabled in pairs(enabled_groups) do
        if enabled then
            for _, unit in ObjList(group_id) do
                renderHP(unit, cfg)
            end
        end
    end
end

return InstanceInfoRenderer()
