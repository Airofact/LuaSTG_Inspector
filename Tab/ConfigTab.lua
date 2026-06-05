local imgui_exist, imgui = pcall(require, "imgui")
local Inspector = require"Inspector"

local function layout()
    if not imgui_exist then return end

    local config = Inspector.config
    local ImGui = imgui.ImGui
    local cn = config.object_meta_info
    local hp = config.instance_info
    local ch = config.indicator
    local groups = config.enabled_groups

    ----------------------------------------
    -- Class Name
    ----------------------------------------
    ImGui.SeparatorText("Class Name")

    local v
    v, cn.show = ImGui.Checkbox("Show Class Name", cn.show)
    v, cn.show_invalid = ImGui.Checkbox("Show Invalid Class", cn.show_invalid)
    v, cn.show_group_id = ImGui.Checkbox("Show Group ID", cn.show_group_id)
    v, cn.show_editor = ImGui.Checkbox("Display Editor Classes", cn.show_editor)
    v, cn.show_global = ImGui.Checkbox("Display Global Classes", cn.show_global)
    v, cn.show_local = ImGui.Checkbox("Display Local Classes", cn.show_local)
    v, cn.font_scale = ImGui.SliderFloat("Font Scale", cn.font_scale, 0.1, 1.0, "%.2f")

    ----------------------------------------
    -- HP
    ----------------------------------------
    ImGui.SeparatorText("HP")

    v, hp.show = ImGui.Checkbox("Show HP", hp.show)
    v, hp.show_protect = ImGui.Checkbox("Show Protect Indicator", hp.show_protect)
    v, hp.font_scale = ImGui.SliderFloat("HP Font Scale", hp.font_scale, 0.1, 1.0, "%.2f")

    ----------------------------------------
    -- Indicator
    ----------------------------------------
    ImGui.SeparatorText("Indicator")

    local pos = ch.position
    local box = ch.box
    local v

    ImGui.Text("Position (crosshair)")
    v, pos.show = ImGui.Checkbox("Show Position##pos", pos.show)
    v, pos.size = ImGui.SliderInt("Size##pos", pos.size, 5, 100)
    v, pos.thickness = ImGui.SliderInt("Thickness##pos", pos.thickness, 1, 10)

    ImGui.Separator()
    ImGui.Text("Box (highlight)")
    v, box.show = ImGui.Checkbox("Show Box##box", box.show)
    v, box.thickness = ImGui.SliderInt("Thickness##box", box.thickness, 1, 10)

    ImGui.Separator()
    ImGui.Text("Polyline")
    local pl = ch.polyline
    v, pl.show = ImGui.Checkbox("Show Polyline##pl", pl.show)
    v, pl.thickness = ImGui.SliderInt("Thickness##pl", pl.thickness, 1, 10)

    ----------------------------------------
    -- Groups
    ----------------------------------------
    ImGui.SeparatorText("Groups")

    if ImGui.Button("Select All") then
        for i = 0, GROUP_NUM_OF_GROUP - 1 do
            groups[i] = true
        end
    end
    ImGui.SameLine()
    if ImGui.Button("Deselect All") then
        for i = 0, GROUP_NUM_OF_GROUP - 1 do
            groups[i] = false
        end
    end

    local columns = 2
    ImGui.Columns(columns, "GroupColumns", false)

    for i = 0, GROUP_NUM_OF_GROUP - 1 do
        local name = config.group_names[i] or string.format("GROUP_%d", i)
        local label = string.format("%s (%d)", name, i)
        local chg, val = ImGui.Checkbox(label, groups[i])
        if chg then groups[i] = val end

        if (i + 1) % math.ceil(GROUP_NUM_OF_GROUP / columns) == 0 then
            ImGui.NextColumn()
        end
    end
    ImGui.Columns(1)
end

return { layout = layout }
