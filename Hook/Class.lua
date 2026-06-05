-- Hook Class函数以捕获本地定义的类
local original_Class = Class

-- 引入邪恶名称窃取者 --- 老师这个名字真的太好笑了
local EvilNameStealer = require("EvilNameStealer")

function Class(...)
    local class = original_Class(...)

    -- 使用邪恶名称窃取者获取变量名
    local var_name = EvilNameStealer.GetReturnedValueName()

    if var_name then
        -- 使用debug库获取调用处的信息
        local info = debug.getinfo(2, "S")
        if info and info.source then
            -- 标记为本地定义的类
            class.__identifier = var_name
        end
    end

    return class
end