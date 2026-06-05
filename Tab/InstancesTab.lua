local TAB = require"Tab.TabEnum"

local imgui_exist, imgui = pcall(require, "imgui")
local Inspector = require"Inspector"

---@param view InspectorView
local function layout(view)
    if not imgui_exist then return end

    local ImGui = imgui.ImGui

    -- 类选择
    ImGui.Text("Filter by class:")
    ImGui.SameLine()
    if Inspector.selected_class then
        ImGui.TextColored(imgui.ImVec4(0, 1, 1, 1), Inspector.selected_class)
        ImGui.SameLine()
    end

    -- 清除选中按钮
    if #Inspector.selected_units > 0 then
        if ImGui.Button("Clear Selection") then
            Inspector:clear_selected_units()
        end
        ImGui.SameLine()
        ImGui.TextColored(imgui.ImVec4(1, 0, 1, 1), string.format("Selected: %d", #Inspector.selected_units))
    else
        if not Inspector.selected_class then
            ImGui.TextDisabled(" (click a class in Statistics tab)")
        end
    end

    ImGui.Separator()

    -- 收集实例
    local instances = {}
    local enabled_groups = Inspector.config.enabled_groups
    local function groupEnabled(g)
        if not enabled_groups then return true end
        return enabled_groups[g] == true
    end

    for g = 0, GROUP_NUM_OF_GROUP - 1 do
        if groupEnabled(g) then
            for _, unit in ObjList(g) do
                if IsValid(unit) and unit.class then
                    if not Inspector.selected_class or unit.class.__identifier == Inspector.selected_class then
                        table.insert(instances, unit)
                    end
                end
            end
        end
    end

    ImGui.Text(string.format("Found %d instances", #instances))
    ImGui.Separator()

    -- 实例列表
    if #instances > 0 then
        -- 表头
        ImGui.Columns(4, "InstanceColumns", true)
        ImGui.Separator()
        ImGui.Text("ID")
        ImGui.NextColumn()
        ImGui.Text("Class")
        ImGui.NextColumn()
        ImGui.Text("Pos (x, y)")
        ImGui.NextColumn()
        ImGui.Text("HP")
        ImGui.NextColumn()
        ImGui.Separator()

        -- 显示实例（限制数量）
        local max_show = math.min(#instances, 100)
        for i = 1, max_show do
            local unit = instances[i]

            -- 检查选中状态
            local is_selected = Inspector:is_unit_selected(unit)
            local is_first = Inspector:is_unit_first_selected(unit)

            -- ID（可点击选中，支持多选）
            local id_text = tostring(i)
            if is_first then
                -- 第一个选中的显示紫色标记
                id_text = "> " .. id_text
            end

            if ImGui.Selectable(id_text, is_selected, imgui.ImGuiSelectableFlags.SpanAllColumns) then
                if ImGui.IsKeyDown(imgui.ImGuiKey.LeftCtrl) then
                    Inspector:toggle_selected_unit(unit)
                    Inspector:switch_prime_selected_unit(unit)
                else
                    Inspector:clear_selected_units()
                    Inspector:toggle_selected_unit(unit)
                end
            end

            if ImGui.IsMouseDoubleClicked(imgui.ImGuiMouseButton.Left) then
                view.switch_to_tab = TAB.INSPECTOR
            end
            ImGui.NextColumn()

            -- 类名
            local identifier = unit.class.__identifier or "(unknown)"
            if is_first then
                ImGui.TextColored(imgui.ImVec4(1, 0, 1, 1), identifier)
            else
                ImGui.Text(identifier)
            end
            ImGui.NextColumn()

            -- 位置
            ImGui.Text(string.format("(%.1f, %.1f)", unit.x or 0, unit.y or 0))
            ImGui.NextColumn()

            -- HP
            if unit.hp then
                ImGui.Text(string.format("%.1f", unit.hp))
            else
                ImGui.TextDisabled("-")
            end
            ImGui.NextColumn()
        end

        ImGui.Columns(1)

        if #instances > 100 then
            ImGui.TextDisabled(string.format("... and %d more (showing first 100)", #instances - 100))
        end
    else
        ImGui.Text("No instances found.")
    end
end

return {
    TAB = TAB,
    layout = layout,
}
