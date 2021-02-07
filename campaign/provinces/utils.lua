
local function trim(s)
    return s:match'^%s*(.*%S)' or ''
end

local function split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
       return { str }
    end
    if maxNb == nil or maxNb < 1 then
       maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
       nb = nb + 1
       result[nb] = part
       lastPos = pos
       if nb == maxNb then
          break
       end
    end
    -- Handle the last field
    if nb ~= maxNb then
       result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

-- little helper to query UIComponent a little bit easier
local function _(path)
    path = trim(path)
    local str = string.gsub(path, "%s*root%s*>%s+", "")
    local args = split(str, ">")
    for k, v in pairs(args) do
        args[k] = trim(v)
    end
    return find_uicomponent(core:get_ui_root(), unpack(args))
end

return {
    trim = trim,
    split = split,
    _ = _
}