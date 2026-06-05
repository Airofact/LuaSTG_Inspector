---@diagnostic disable: inject-field
---@diagnostic disable: undefined-field

local ClassMetaInfo = require"ClassMetaInfo"

local InstanceQuery = {}

---按类标识符统计实例数量
---@param enabled_groups table<number, boolean>
---@param config table
---@return table
function InstanceQuery.collect_counts(enabled_groups, config)
    local cn = config

    local result = {
        counts_by_identifier = {},
        meta_by_identifier = {},
        totals = 0,
        totals_by_definition_type = { editor = 0, global = 0, ["local"] = 0, invalid = 0 },
    }

    local function group_enabled(g)
        if not enabled_groups then return true end
        return enabled_groups[g] == true
    end

    local function should_include(def_type)
        if def_type == "editor" then return cn.show_editor ~= false end
        if def_type == "global" then return cn.show_global ~= false end
        if def_type == "local" then return cn.show_local ~= false end
        return cn.show_invalid ~= false
    end

    for g = 0, GROUP_NUM_OF_GROUP - 1 do
        if group_enabled(g) then
            for _, unit in ObjList(g) do
                local cls = unit.class
                if cls then
                    if not ClassMetaInfo.has_meta(cls) then
                        ClassMetaInfo.ensure()
                    end

                    local def_type = cls.__definition_type
                    if not (def_type == "editor" or def_type == "global" or def_type == "local") then
                        def_type = "invalid"
                    end

                    if should_include(def_type) then
                        local identifier = cls.__identifier or "(unknown)"
                        result.counts_by_identifier[identifier] = (result.counts_by_identifier[identifier] or 0) + 1
                        if not result.meta_by_identifier[identifier] then
                            result.meta_by_identifier[identifier] = { definition_type = def_type }
                        end
                        result.totals = result.totals + 1
                        result.totals_by_definition_type[def_type] = (result.totals_by_definition_type[def_type] or 0) + 1
                    end
                end
            end
        end
    end

    return result
end

return InstanceQuery
