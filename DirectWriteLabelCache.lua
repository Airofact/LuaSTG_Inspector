--- DirectWrite 标签纹理缓存：按文本字面量映射到精灵纹理，提供 bbox 查询
local DirectWrite = require("DirectWrite")

local DirectWriteLabelCache = plus.Class()

function DirectWriteLabelCache:init(text_format, resolution, font_size)
    self.text_format = text_format
    self.resolution = resolution or 2
    self.font_size = font_size or 14
    self.cache = {}
    self.counter = 0
end

---@return { texture_name: string, w: number, h: number }|nil
function DirectWriteLabelCache:get(text)
    if not text or text == "" then return nil end

    local entry = self.cache[text]
    if entry then return entry end

    local r = self.resolution
    local max_width = r * 512
    local layout = DirectWrite.CreateTextLayout(text, self.text_format, max_width, r * 64)
    layout:SetWordWrapping(1)  -- DWRITE_WORD_WRAPPING_NO_WRAP
    local w = math.ceil(layout:DetermineMinWidth())

    -- 如果 min width 撞到上限，文本太长，翻倍重试
    while w >= max_width do
        max_width = max_width * 2
        layout = DirectWrite.CreateTextLayout(text, self.text_format, max_width, r * 64)
        layout:SetWordWrapping(1)
        w = math.ceil(layout:DetermineMinWidth())
    end
    local h = math.ceil(r * self.font_size * 1.2)

    self.counter = self.counter + 1
    local identifier = "inspector:label_" .. self.counter
    DirectWrite.CreateTextureFromTextLayout(layout, "global", identifier, 0)
    local resource_pool = lstg.GetResourceStatus()
    if resource_pool ~= "global" then
        lstg.SetResourceStatus"global"
    end
    lstg.LoadImage(identifier, identifier, 0, 0, w, h)
    if resource_pool ~= "global" then
        lstg.SetResourceStatus(resource_pool)
    end
    lstg.SetImageScale(identifier, 1 / r)
    lstg.SetImageCenter(identifier, w / 2, h / 2)

    entry = { image = identifier, w = w, h = h }
    self.cache[text] = entry
    return entry
end

---@return number w, number h @游戏世界坐标尺寸
function DirectWriteLabelCache:measure(text)
    local e = self:get(text)
    if not e then return 0, 0 end
    return e.w / self.resolution, e.h / self.resolution
end

return DirectWriteLabelCache
