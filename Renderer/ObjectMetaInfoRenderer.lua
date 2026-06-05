---@diagnostic disable: inject-field
---@diagnostic disable: undefined-field

local DirectWrite = require("DirectWrite")
local ClassMetaInfo = require"ClassMetaInfo"
local DirectWriteLabelCache = require"DirectWriteLabelCache"

local ObjectMetaInfoRenderer = plus.Class()

function ObjectMetaInfoRenderer:init()
    self.resolution = 2
    self.font_size = 14

    local font_files = {
        "Dialog/Assets/General/LXGWWenKaiScreen.ttf",
    }
    local font_collection = DirectWrite.CreateFontCollection(font_files)
    local text_format = DirectWrite.CreateTextFormat(
        "LXGW WenKai Screen",
        font_collection,
        DirectWrite.FontWeight.Regular,
        DirectWrite.FontStyle.Normal,
        DirectWrite.FontStretch.Normal,
        self.resolution * self.font_size,
        ""
    )
    self.cache = DirectWriteLabelCache(text_format, self.resolution, self.font_size)

    self.color = {
        editor = Color(0xFF00FF00),
        global = Color(0xFFFFFF00),
        local_ = Color(0xFF00FFFF),
        invalid = Color(0xFFFF0000),
    }

    CopyImage("inspector:label_bg", "white")
    SetImageState("inspector:label_bg", "", Color(0x80000000))

    self.group_pool = {}
    self.group_idx = 0
    self.item_pool = {}
    self.item_idx = 0
end

function ObjectMetaInfoRenderer:acquire_group(image, color, w, h, typename)
    self.group_idx = self.group_idx + 1
    local g = self.group_pool[self.group_idx]
    if not g then
        g = { items = {} }
        self.group_pool[self.group_idx] = g
    end
    g.image = image
    g.color = color
    g.w = w
    g.h = h
    g.typename = typename
    local items = g.items
    for i = #items, 1, -1 do
        items[i] = nil
    end
    return g
end

function ObjectMetaInfoRenderer:acquire_item(unit, x, y)
    self.item_idx = self.item_idx + 1
    local it = self.item_pool[self.item_idx]
    if not it then
        it = {}
        self.item_pool[self.item_idx] = it
    end
    it.unit = unit
    it.x = x
    it.y = y
    return it
end

---@class DwLabelItem
---@field unit lstg.GameObject @collection frame valid; consumers must IsValid
---@field x number @cached world position at collection time
---@field y number @cached world position at collection time

---@class DwLabelGroup
---@field image string
---@field color lstg.Color
---@field w number @纹理像素宽度
---@field h number @纹理像素高度
---@field typename string
---@field items DwLabelItem[]

---@param groups table<string, DwLabelGroup>
---@param unit lstg.GameObject
---@param config table
function ObjectMetaInfoRenderer:collect(groups, unit, config)
    if not ClassMetaInfo.has_meta(unit.class) then
        ClassMetaInfo.ensure()
    end

    local def = unit.class.__definition_type

    if def == "editor" and not config.show_editor then
        return
    elseif def == "global" and not config.show_global then
        return
    elseif def == "local" and not config.show_local then
        return
    elseif def == nil and not config.show_invalid then
        return
    end

    local color
    if def == "editor" then
        color = self.color.editor
    elseif def == "global" then
        color = self.color.global
    elseif def == "local" then
        color = self.color.local_
    else
        color = self.color.invalid
    end

    local valid = def == "editor" or def == "global" or def == "local"
    local text
    if not valid then
        if not config.show_invalid then return end
        text = "Unknown class"
    elseif config.show then
        text = unit.class.__identifier
        if not text then return end
        if config.show_group_id then
            text = text .. " (" .. (unit.group or "?") .. ")"
        end
    else
        return
    end

    local entry = self.cache:get(text)
    if not entry then return end

    local group = groups[entry.image]
    if not group then
        group = self:acquire_group(entry.image, color, entry.w, entry.h, unit.class.__identifier)
        groups[entry.image] = group
    end

    group.items[#group.items + 1] = self:acquire_item(unit, unit.x, unit.y)
end

---@param enabled_groups table<number, boolean>
---@param selected_units lstg.GameObject[]
---@param config table
function ObjectMetaInfoRenderer:render(enabled_groups, selected_units, config)
    self.group_idx = 0
    self.item_idx = 0

    local selected_set = {}
    if selected_units then
        for _, u in ipairs(selected_units) do
            selected_set[u] = true
        end
    end

    local groups = {}
    local penetrate_groups = {}

    for group_id, enabled in pairs(enabled_groups) do
        if enabled then
            for _, unit in ObjList(group_id) do
                if selected_set[unit] then
                    self:collect(penetrate_groups, unit, config)
                else
                    self:collect(groups, unit, config)
                end
            end
        end
    end

    local scale = config.font_scale

    for _, group in pairs(groups) do
        local bg_hs = group.w / self.resolution * scale / 16
        local bg_vs = group.h / self.resolution * scale / 16
        if #group.items > 0 then
            lstg.SetImageState(group.image, "", group.color)
            for _, item in ipairs(group.items) do
                lstg.Render("inspector:label_bg", item.x, item.y, 0, bg_hs, bg_vs)
                lstg.Render(group.image, item.x, item.y, 0, scale, scale)
            end
        end
    end

    for _, group in pairs(penetrate_groups) do
        if #group.items > 0 then
            local bg_hs = group.w / self.resolution * scale / 16
            local bg_vs = group.h / self.resolution * scale / 16
            lstg.SetImageState(group.image, "", group.color)
            for _, item in ipairs(group.items) do
                lstg.Render("inspector:label_bg", item.x, item.y, 0, bg_hs, bg_vs)
                lstg.Render(group.image, item.x, item.y, 0, scale, scale)
            end
        end
    end
end

return ObjectMetaInfoRenderer()
