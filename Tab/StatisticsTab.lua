local TAB = require"Tab.TabEnum"

local imgui_exist, imgui = pcall(require, "imgui")
local ClassMetaInfo = require"ClassMetaInfo"
local InstanceQuery = require"InstanceQuery"
local Inspector = require"Inspector"

---@param view InspectorView
local function layout(view)
    if not imgui_exist then return end

    local ImGui = imgui.ImGui
    local config = Inspector.config
    local statistics = config.statistics

    ImGui.SeparatorText("Class Info")

    if ImGui.Button("Reload Class Info") then
        ClassMetaInfo.reinitialize()
    end

    ImGui.SeparatorText("Instance Counts")

    local v
    v, statistics.show_counts = ImGui.Checkbox("Show Instance Counts", statistics.show_counts)

    v, statistics.max_rows = ImGui.SliderInt("Max Rows", statistics.max_rows, 5, 200)

    if not statistics.show_counts then return end

    local counts = InstanceQuery.collect_counts(config.enabled_groups, config.object_meta_info)
    ImGui.Text(string.format("Total: %d (Editor: %d, Global: %d, Local: %d, Invalid: %d)",
        counts.totals,
        counts.totals_by_definition_type.editor,
        counts.totals_by_definition_type.global,
        counts.totals_by_definition_type["local"],
        counts.totals_by_definition_type.invalid
    ))

    local entries = {}
    for id, n in pairs(counts.counts_by_identifier) do
        entries[#entries + 1] = {
            id = id,
            n = n,
            def = counts.meta_by_identifier[id] and counts.meta_by_identifier[id].definition_type or "invalid"
        }
    end
    table.sort(entries, function(a, b)
        if a.n ~= b.n then return a.n > b.n end
        return a.id < b.id
    end)

    local show_rows = math.min(#entries, statistics.max_rows)
    if show_rows == 0 then
        ImGui.Text("No instances matched.")
        return
    end

    ImGui.TextDisabled(string.format("Showing %d of %d (click to view)", show_rows, #entries))
    for i = 1, show_rows do
        local e = entries[i]
        local color
        if e.def == "editor" then
            color = imgui.ImVec4(0, 1, 0, 1)
        elseif e.def == "global" then
            color = imgui.ImVec4(1, 1, 0, 1)
        elseif e.def == "local" then
            color = imgui.ImVec4(0, 1, 1, 1)
        else
            color = imgui.ImVec4(1, 0, 0, 1)
        end

        ImGui.PushStyleColor(imgui.ImGuiCol.Text, color)
        if ImGui.Selectable(string.format("[%4d] %s##class_%d", e.n, e.id, i)) then
            Inspector.selected_class = e.id
            Inspector:clear_selected_units()
            view.switch_to_tab = TAB.INSTANCES
        end
        ImGui.PopStyleColor()
    end
end

return {
    TAB = TAB,
    layout = layout,
}
