local ENABLE_LOCAL_CLASS_MATCH = true

-- 注册 Class Hook，需要在 THlib 之前执行
if ENABLE_LOCAL_CLASS_MATCH then
	lstg.plugin.RegisterEvent("beforeTHlib", "dims.debug.inspector.hookClass", 0, function()
		if not lstg.FileManager.GetSearchPaths then
			print("[Inspector] 请自行拓展 lstg.FileManager.GetSearchPaths 函数，否则无法使用 EvilNameStealer 功能，本地类名称将无法获取。")
			return
		end
		print("[Inspector] 本地类匹配会严重影响启动时间，请谨慎使用。")
		require'Hook.Class'
	end)
end

-- 注册主要功能，需要在 THlib 之后执行
lstg.plugin.RegisterEvent("afterTHlib", "dims.debug.inspector.objectMetaInfoRenderer", 0, function()
	require'InspectorView'
	require'Hook.Render'
end)