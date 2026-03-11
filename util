-- =============================================================================
-- THUD Raid Tools - Utility & Compatibility Layer (Fixed for 1.12.1)
-- =============================================================================

-- Fix global gmatch/gfind for the 1.12 client 
cgmatch = string.gmatch or string.gfind
cunpack = unpack or table.unpack

-- Fixed string join for older Lua (Replaced ... with defined arguments) 
cstrjoin = string.join or function(delim, arg1, arg2, arg3, arg4, arg5)
    local arg = {arg1, arg2, arg3, arg4, arg5}
    local result = ""
    for i = 1, 5 do
        if arg[i] then
            if result == "" then 
                result = arg[i] 
            else 
                result = result .. delim .. arg[i] 
            end
        end
    end
    return result
end

-- Custom string match wrapper
cmatch = string.match or function (s, pattern, init)
    init = init or 1
    local results = { string.find(s, pattern, init) }
    if table.getn(results) > 2 then
        local captures = {}
        for i = 3, table.getn(results) do
            table.insert(captures, results[i])
        end
        return cunpack(captures)
    elseif results[1] and results[2] then
        return string.sub(s, results[1], results[2])
    end
    return nil
end

-- Version comparison
function THUD_CompareVersion(v1, v2)
    local function split(str)
        local parts = {}
        for num in cgmatch(str, "(%d+)") do
            table.insert(parts, tonumber(num))
        end
        return parts
    end
    local p1, p2 = split(v1), split(v2)
    local maxLen = math.max(table.getn(p1), table.getn(p2))
    for i = 1, maxLen do
        local n1 = p1[i] or 0
        local n2 = p2[i] or 0
        if n1 > n2 then return 1 end
        if n1 < n2 then return -1 end
    end
    return 0
end

function THUD_Trim(s)
    if not s then return "" end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
