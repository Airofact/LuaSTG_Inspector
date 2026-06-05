local lstg_debug = require("lib.Ldebug")
local imgui_exist, imgui = pcall(require, "imgui")

local ClassMetaInfo = require"ClassMetaInfo"
local ConfigTab = require"Tab.ConfigTab"
local TAB = require"Tab.TabEnum"
local StatisticsTab = require"Tab.StatisticsTab"
local InstancesTab = require"Tab.InstancesTab"
local InspectorTab = require"Tab.InspectorTab"
local Inspector = require"Inspector"
local config = Inspector.config

---@class InspectorView : lstg.debug.View
local InspectorView = {}

function InspectorView:getWindowName() return "Inspector" end

function InspectorView:getMenuItemName() return "Inspector" end

function InspectorView:getMenuGroupName() return "Tool" end

function InspectorView:getEnable() return config.enabled end

function InspectorView:setEnable(v) config.enabled = v end

function InspectorView:initialize()
    self.current_tab = TAB.STATISTICS
    self.switch_to_tab = nil
    ClassMetaInfo.ensure()
end

function InspectorView:update()
end

function InspectorView:layout()
    if not imgui_exist then return end

    local ImGui = imgui.ImGui

    if not config.enabled then
        ImGui.Text("Enable the inspector above.")
        return
    end

    if ImGui.BeginTabBar("InspectorTabs") then
        local F = imgui.ImGuiTabItemFlags
        local flags = {
            [TAB.CONFIG] = F.None,
            [TAB.STATISTICS] = F.None,
            [TAB.INSTANCES] = F.None,
            [TAB.INSPECTOR] = F.None,
        }

        if self.switch_to_tab then
            flags[self.switch_to_tab] = F.SetSelected
            self.current_tab = self.switch_to_tab
            self.switch_to_tab = nil
        end

        if ImGui.BeginTabItem("Config", true, flags[TAB.CONFIG]) then
            self.current_tab = TAB.CONFIG
            ConfigTab.layout()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Statistics", true, flags[TAB.STATISTICS]) then
            self.current_tab = TAB.STATISTICS
            StatisticsTab.layout(self)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Instances", true, flags[TAB.INSTANCES]) then
            self.current_tab = TAB.INSTANCES
            InstancesTab.layout(self)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Inspector", true, flags[TAB.INSPECTOR]) then
            self.current_tab = TAB.INSPECTOR
            InspectorTab.layout()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

InspectorView:initialize()
lstg_debug.addView("lstg.debug.Inspector", InspectorView)

return InspectorView
