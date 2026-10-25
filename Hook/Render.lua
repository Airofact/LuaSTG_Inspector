local Inspector = require("Inspector")
local ObjectMetaInfoRenderer = require("Renderer.ObjectMetaInfoRenderer")
local InstanceInfoRenderer = require("Renderer.InstanceInfoRenderer")
local IndicatorRenderer = require("Renderer.IndicatorRenderer")

local original_AfterRender = AfterRender

function AfterRender()
    if original_AfterRender then
        original_AfterRender()
    end

    local config = Inspector.config
    if not config.enabled then
        return
    end

    ObjectMetaInfoRenderer:render(config.enabled_groups, Inspector.selected_units, config.object_meta_info)
    InstanceInfoRenderer:render(config.enabled_groups, config.instance_info)
    IndicatorRenderer:render(config.indicator)
end
