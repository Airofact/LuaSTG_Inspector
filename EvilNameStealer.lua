
-- 缓存源代码以提高性能
local source_cache = setmetatable({}, {__mode = "k"})

--- @class ObjectMetaInfoRenderer.EvilNameStealer
local lib = {}

--- @class ObjectMetaInfoRenderer.EvilNameStealer.CallContext
--- @field lines string[] 源代码行
--- @field call_line integer 调用行号

--- 获取调用处的源代码上下文
--- @return ObjectMetaInfoRenderer.EvilNameStealer.CallContext?
local function get_caller_context()
    local level = 4  -- 1=当前函数, 2=get_retval_variable_name, 3=Class函数, 4=调用者
    local info = debug.getinfo(level, "Sl")
    if not info then return nil end

    -- 在 LuaSTG 环境中，source 直接是相对路径，不带 @ 前缀
    -- 利用搜索路径来查找文件
    local source_content
    if info.source then
        local file_path = info.source

        if not source_cache[file_path] then
            local actual_path = file_path
            local tried_paths = {}

            -- 首先尝试直接打开文件
            local file, err = io.open(file_path, "r")
            if file == nil then
                table.insert(tried_paths, file_path)
                -- 如果直接打开失败，尝试搜索路径
                if lstg.FileManager.GetSearchPaths then
                    local search_paths = lstg.FileManager.GetSearchPaths()
                    for _, search_path in ipairs(search_paths) do
                        actual_path = search_path .. file_path:gsub("\\", "/")
                        file = io.open(actual_path, "r")
                        if file then
                            break
                        else
                            table.insert(tried_paths, actual_path)
                        end
                    end
                end
            end

            if file then
                print(string.format("[EvilNameStealer] 成功读取文件: %s", actual_path))
                local src = { lines = {} }
                for line in file:lines() do
                    line = line:gsub("\r", "")
                    table.insert(src.lines, line)
                end
                source_cache[file_path] = src
                file:close()
            else
                print(string.format("[EvilNameStealer] 无法找到文件: %s, 在以下路径中尝试过:", file_path))
                for _, path in ipairs(tried_paths) do
                    print(path)
                end
                return nil  -- 无法读取文件
            end
        end
        source_content = source_cache[file_path]
    else
        return nil
    end

    if not source_content then
        return nil
    end

    local result = {
        lines = source_content.lines,
        call_line = info.currentline
    }
    return result
end

--- 智能变量名提取
--- @param expr_str string 表达式字符串
--- @return string 变量名
local function extract_variable_name(expr_str)
    -- 简单变量名
    if expr_str:match("^[%a_][%w_]*$") then
        return expr_str
    end

    -- 表字段访问：t.key
    local dot_match = expr_str:match("^([%a_][%w_]*%.[%a_][%w_]*)$")
    if dot_match then
        return dot_match
    end

    -- 字符串索引访问：t["key"]
    local string_index = expr_str:match('^([%a_][%w_]*)%[%s*"([%a_][%w_]*)"%s*%]$')
    if string_index then
        local table_name, key = string.match(expr_str, '^([%a_][%w_]*)%[%s*"([%a_][%w_]*)"%s*%]$')
        return table_name .. "." .. key
    end

    -- 变量索引访问：t[key_var]
    local var_index = expr_str:match("^([%a_][%w_]*)%[%s*([%a_][%w_]*)%s*%]$")
    if var_index then
        return expr_str  -- 返回原始表达式
    end

    -- 链式赋值中的变量名
    local last_comma = expr_str:find(",", 1, true)
    if last_comma then
        local last_var = expr_str:sub(last_comma + 1):match("^%s*([%a_][%w_]*)%s*$")
        if last_var then
            return last_var
        end
    end

    -- 无法识别的表达式，返回原始字符串
    return expr_str
end

-- 反向解析找到变量名
--- @param context ObjectMetaInfoRenderer.EvilNameStealer.CallContext
--- @return string? 变量名
local function find_assignment_variable(context)
    local call_line_index = context.call_line
    local lines = context.lines

    if call_line_index < 1 or call_line_index > #lines then
        return nil  -- 行号超出范围
    end
    local line = lines[call_line_index]
    if not line then
        return nil  -- 行内容为空
    end
    -- 从调用行开始向上搜索
    -- 查找"Class("的位置
    local class_pos = line:find("Class%(")
    if class_pos then
        -- 从Class(位置向前查找"="
        local lines_forward = {}
        for i = 1, call_line_index - 1 do
            table.insert(lines_forward, lines[i])
        end
        local line = table.concat(lines_forward, " ")
        class_pos = class_pos + #line
        line = line .. lines[call_line_index]

        local search_start = class_pos - 1
        local found_equals = false
        local bracket_depth = 0

        -- 反向扫描当前行
        for pos = search_start, 1, -1 do
            local char = line:sub(pos, pos)
            local escape = false

            if not escape then
                -- 处理括号深度
                if char == ")" then
                    bracket_depth = bracket_depth + 1
                elseif char == "(" then
                    bracket_depth = bracket_depth - 1
                    if bracket_depth < 0 then
                        bracket_depth = 0  -- 无效位置，重置
                    end
                end

                -- 找到赋值符号（不在括号内）
                if char == "=" and bracket_depth == 0 then
                    found_equals = true

                    -- 向前提取变量表达式
                    local p = pos - 1

                    -- 跳过空格
                    while p >= 1 and line:sub(p, p):match("%s") do p = p - 1 end


                    local chars = {}

                    -- 查找变量起始位置
                    -- sp case: ]=   Func()
                    local sp_no_break = line:sub(p, p) == "]" and line:sub(p+1, p+1) == "="
                    while p >= 1 do
                        local c = line:sub(p, p)
                        if c:match("[%w_%.:%[%]\'\"]") then
                            table.insert(chars, c)
                            -- sp case: ] = Func(); .name = Func()
                            if((c == "]" and (line:sub(p+1, p+1)):match("%s")) or c == '.' and (line:sub(p-1, p-1)):match("%s")) then sp_no_break = true end
                            p = p - 1
                        else
                            if sp_no_break then while p >= 1 and line:sub(p, p):match("%s") do p = p - 1 end sp_no_break = false
                            else break end
                        end
                    end

                    -- 提取变量表达式
                    local var_expr = table.concat(chars):reverse()

                    -- 智能提取变量名
                    return extract_variable_name(var_expr)
                end
            end
        end

        -- 没找到"="，出错
        if not found_equals then return end
    end


    return nil
end

--- 邪恶名称窃取者(?我这取名风格有点那啥了) 获取返回到的变量名
--- 用法: 把它放到想要获得返回值对应变量名(full name)的函数里 调用它即可
--- warning: 使用debug库 且性能差 不建议动态频繁调用
--- @return string? VariableName 变量名(处理后版本) 若解析出错则返回nil
local function get_retval_variable_name()
    local context = get_caller_context()
    if not context then return nil end
    return find_assignment_variable(context)
end

lib.GetReturnedValueName = get_retval_variable_name

return lib