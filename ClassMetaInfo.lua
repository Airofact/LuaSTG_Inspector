---@diagnostic disable: inject-field
---@diagnostic disable: undefined-field

---class table 元数据注入层
---负责扫描 _editor_class / _G / all_class 并注入 __identifier 和 __definition_type
---与渲染逻辑完全解耦，ObjectMetaInfoRenderer 仅消费元数据

local function is_class(tbl)
	local success, ret = pcall(function() return tbl.is_class end)
	return success and ret
end

---@param class table
local function has_meta(class)
	return class.__definition_type ~= nil
end

local injected = {}

---全量扫描并注入所有 class table 的元数据（幂等）
local function initialize_class_metadata()
	-- 编辑器类
	for identifier, class in pairs(_editor_class or {}) do
		if type(class) == "table" and is_class(class) then
			if not injected[class] then
				class.__identifier = identifier
				class.__definition_type = "editor"
				injected[class] = true
			end
		end
	end

	-- 全局类（跳过已注入的）
	for identifier, class in pairs(_G) do
		if type(class) == "table" then
			if is_class(class) and not injected[class] then
				class.__identifier = identifier
				class.__definition_type = "global"
				injected[class] = true
			end
		end
	end

	-- all_class 中未标记 definition_type 的补标记
	if all_class then
		for _, class in pairs(all_class) do
			if type(class) == "table" and class.is_class then
				if not injected[class] then
					if class.__identifier then
						class.__definition_type = "local"
					else
						class.__definition_type = "invalid"
					end
					injected[class] = true
				end
			end
		end
	end
end

---@class ClassMetaInfo
local ClassMetaInfo = {}

---确保元数据已注入（幂等，已注入的 class 零开销跳过）
function ClassMetaInfo.ensure()
	initialize_class_metadata()
end

---检查某个 class 是否已注入元数据
---@param class table
---@return boolean
function ClassMetaInfo.has_meta(class)
	return has_meta(class)
end

---清空所有注入的元数据（热重载用）
function ClassMetaInfo.clear()
	if all_class then
		for _, class in pairs(all_class) do
			if type(class) == "table" then
				if is_class(class) then
					class.__identifier = nil
					class.__definition_type = nil
				end
			end
		end
	end
	injected = {}
end

---重新注入（先清空再扫描）
function ClassMetaInfo.reinitialize()
	ClassMetaInfo.clear()
	initialize_class_metadata()
end

return ClassMetaInfo
