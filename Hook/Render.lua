local Inspector = require("Inspector")

local original_AfterRender = AfterRender

function AfterRender()
    if original_AfterRender then
        original_AfterRender()
    end

    local config = Inspector.config
    if not config.enabled then
        return
    end

    Inspector.object_meta_info:render(config.enabled_groups, Inspector.selected_units, config.object_meta_info)
    Inspector.instance_info:render(config.enabled_groups, config.instance_info)
    Inspector.indicator:render(config.indicator)
end
