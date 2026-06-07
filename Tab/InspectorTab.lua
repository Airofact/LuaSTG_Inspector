local imgui_exist, imgui = pcall(require, "imgui")
local Inspector = require"Inspector"

local GAMEOBJECT_PROPERTIES = {
    "x", "y", "rot", "omiga", "timer", "vx", "vy", "ax", "ay", "layer", "group",
    "hide", "bound", "navi", "colli", "status", "hscale", "vscale", "a", "b", "rect", "img",
    "pause", "rmove", "nopause", "_angle", "_speed"
}

local function is_expandable(key, value)
    local vtype = type(value)
    return vtype == "table" or vtype == "thread"
end

---@param value any
local function layoutProperty(key, value)
    if not imgui_exist then return end

    local ImGui = imgui.ImGui
    local vtype = type(value)
    local display_value

    if vtype == "nil" then
        display_value = "nil"
    elseif vtype == "boolean" then
        display_value = value and "true" or "false"
    elseif vtype == "number" then
        display_value = string.format("%.4f", value)
    elseif vtype == "string" then
        display_value = string.format("%q", value)
    elseif vtype == "table" then
        -- 尝试获取类的标识符
        if value.__identifier then
            display_value = string.format("table: %s", value.__identifier)
        else
            display_value = string.format("table: %s", tostring(value))
        end
    elseif vtype == "function" then
        display_value = string.format("function: %s", tostring(value))
    elseif vtype == "userdata" then
        display_value = string.format("userdata: %s", tostring(value))
    elseif vtype == "thread" then
        local co_status = coroutine.status(value)
        if co_status == "dead" then
            display_value = "thread: dead"
        else
            local info = debug.getinfo(value, 2, "Sl")
            if info then
                local funcname = info.name or info.what or "?"
                display_value = string.format("thread: %s @ %s:%d in %s", co_status, info.short_src, info.currentline, funcname)
            else
                display_value = string.format("thread: %s", co_status)
            end
        end
    else
        display_value = tostring(value)
    end

    -- 显示类型颜色
    local type_color
    if vtype == "number" then
        type_color = imgui.ImVec4(1, 1, 0, 1)  -- 黄色
    elseif vtype == "string" then
        type_color = imgui.ImVec4(1, 0.5, 0, 1)  -- 橙色
    elseif vtype == "boolean" then
        type_color = imgui.ImVec4(0, 1, 0, 1)  -- 绿色
    elseif vtype == "table" then
        type_color = imgui.ImVec4(0, 0.5, 1, 1)  -- 蓝色
    elseif vtype == "function" then
        type_color = imgui.ImVec4(1, 0, 1, 1)  -- 紫色
    elseif vtype == "thread" then
        type_color = imgui.ImVec4(0, 1, 0.8, 1)  -- 青色
    else
        type_color = imgui.ImVec4(0.7, 0.7, 0.7, 1)  -- 灰色
    end

    if not is_expandable(key, value) then
        ImGui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1), string.format("%s:", tostring(key)))
        ImGui.SameLine()
        ImGui.TextColored(type_color, display_value)
    else
        if ImGui.TreeNode(string.format("%s: %s", tostring(key), display_value)) then
            if vtype == "thread" then
                local co_status = coroutine.status(value)
                ImGui.Text(string.format("Status: %s", co_status))
                if co_status ~= "dead" then
                    local info = debug.getinfo(value, 1, "Slun")
                    if info then
                        ImGui.Text(string.format("Source: %s:%d", info.short_src, info.currentline))
                        ImGui.Text(string.format("Function: %s", info.name or info.what or "?"))
                    end
                    ImGui.SeparatorText("Traceback")
                    ImGui.Text(debug.traceback(value))
                end
            else
                -- 展开表格内容
                for k, v in pairs(value) do
                    layoutProperty(k, v)
                end
            end
            ImGui.TreePop()
        end
    end
end

local function layoutGameObjectUserdataPart(unit)
    if not imgui_exist then return end

    local ImGui = imgui.ImGui
    for _, prop in ipairs(GAMEOBJECT_PROPERTIES) do
        if unit[prop] ~= nil then
            layoutProperty(prop, unit[prop])
        end
    end
end

local function layoutClassTable(class)
    if not imgui_exist then return end

    local ImGui = imgui.ImGui
    for k, v in pairs(class) do
        if k == 1 then
            ImGui.TextColored(imgui.ImVec4(0.5, 0.5, 1, 1), string.format("Registered Init Callback: %s", v))
        elseif k == 2 then
            ImGui.TextColored(imgui.ImVec4(1, 0.5, 0.5, 1), string.format("Registered Delete Callback: %s", v))
        elseif k == 3 then
            ImGui.TextColored(imgui.ImVec4(0.5, 1, 1, 1), string.format("Registered Frame Callback: %s", v))
        elseif k == 4 then
            ImGui.TextColored(imgui.ImVec4(1, 0.5, 1, 1), string.format("Registered Render Callback: %s", v))
        elseif k == 5 then
            ImGui.TextColored(imgui.ImVec4(1, 1, 0.5, 1), string.format("Registered Collision Callback: %s", v))
        elseif k == 6 then
            ImGui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), string.format("Registered Kill Callback: %s", v))
        elseif k == "base" then
            ImGui.TextColored(imgui.ImVec4(0.8, 0.8, 0.2, 1), string.format("Base Class: %s", tostring(v.__identifier or v)))
        elseif k == "is_class" and v == false then
            ImGui.TextColored(imgui.ImVec4(0.8, 0.2, 0.2, 1), "Warning: This table is not a valid class (is_class = false)")
        elseif k == "__identifier" then
            ImGui.TextColored(imgui.ImVec4(0.2, 0.8, 0.8, 1), string.format("Class Identifier: %s", tostring(v)))
        elseif k == "__definition_type" then
            ImGui.TextColored(imgui.ImVec4(0.8, 0.2, 0.2, 1), string.format("Definition Type: %s", tostring(v)))
        elseif k == "init" or k == "del" or k == "frame" or k == "render" or k == "colli" or k == "kill" then
            ImGui.TextColored(imgui.ImVec4(0.8, 0.2, 0.8, 1), string.format("Defined %s Callback: %s", tostring(k), tostring(v)))
        else
            layoutProperty(k, v)
        end
    end
end

local function layoutGameObject(unit)
    if not imgui_exist then return end
    local ImGui = imgui.ImGui

    local props = {}
    for k, v in pairs(unit) do
        table.insert(props, { key = k, value = v })
    end
    table.sort(props, function(a, b) return tostring(a.key) < tostring(b.key) end)
    for _, prop in ipairs(props) do
        local k, v = prop.key, prop.value
        if type(v) == "userdata" and k == 3 then
            -- 特例：object[3] 是游戏对象的元表，包含类信息等，单独处理
            if ImGui.TreeNode("GameObject: ".. tostring(v)) then
                layoutGameObjectUserdataPart(unit)
                ImGui.TreePop()
            end
        elseif k == 2 then
            -- 特例：object[2] 是游戏对象的uuid
            ImGui.TextColored(imgui.ImVec4(0.5, 1, 0.5, 1), string.format("   > UUID: %s", tostring(v)))
        elseif type(v) == "table" and k == 1 then
            -- 特例：object[1] 是游戏对象的类表
            if ImGui.TreeNode("Class Table: ".. tostring(v)) then
                layoutClassTable(v)
                ImGui.TreePop()
            end
        else
            layoutProperty(k, v)
        end
    end
end

local function layout()
    if not imgui_exist then return end

    local ImGui = imgui.ImGui

    local unit = Inspector:get_first_selected_unit()

    if not unit then
        ImGui.Text("No unit selected.")
        ImGui.TextDisabled("Select instances from Instances tab.")
        return
    end

    -- 显示选中数量
    local selected_count = #Inspector.selected_units
    if selected_count > 1 then
        ImGui.TextColored(imgui.ImVec4(1, 0, 1, 1), string.format("Showing first of %d selected", selected_count))
    end

    if not IsValid(unit) then
        ImGui.Text("Selected unit is not valid.")
        return
    end

    -- 基本信息
    ImGui.SeparatorText("Basic Info")
    ImGui.Text(string.format("Class: %s", unit.class and unit.class.__identifier or "(unknown)"))
    ImGui.Text(string.format("Group: %d", unit.group or -1))
    ImGui.Text(string.format("Layer: %d", unit.layer or -1))
    ImGui.Text(string.format("Position: (%.1f, %.1f)", unit.x, unit.y))
    local v, a = GetV(unit)
    ImGui.Text(string.format("Speed: Ortho(%.1f, %.1f), Polar(%.1f, %.1f)", unit.vx, unit.vy, v, a))

    ImGui.Separator()

    -- 遍历所有属性
    ImGui.SeparatorText("Properties")

    if ImGui.BeginChild("PropertyList", imgui.ImVec2(0, 0), imgui.ImGuiChildFlags.Borders) then
        layoutGameObject(unit)
        ImGui.EndChild()
    end
end

return {
    layout = layout,
}
