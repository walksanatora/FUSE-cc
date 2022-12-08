--functions copied from yellowbox

--https://gist.github.com/MCJack123/e634347fe7a3025d19d9f7fcf7e01c24#file-yellowbox-lua-L212-L221
local function combineKeys(t, prefix)
    prefix = prefix or ""
    if t == nil then return {} end
    local retval = {}
    for k,v in pairs(t) do
        if type(v) == "string" then table.insert(retval, prefix .. k)
        else for _,w in ipairs(combineKeys(v, prefix .. k .. "/")) do table.insert(retval, w) end end
    end
    return retval
end

--https://gist.github.com/MCJack123/e634347fe7a3025d19d9f7fcf7e01c24#file-yellowbox-lua-L195-L210
local function aux_find(parts, disk)
    if #parts == 0 then return disk elseif type(disk) ~= "table" then return nil end
    local parts2 = {}
    for i,v in ipairs(parts) do parts2[i] = v end
    local name = table.remove(parts2, 1)
    local retval = {}
    if disk then
        if #parts2 == 0 then print("pt2 = 0:"..textutils.serialise(disk,{compact=true})) end
        for k, v in pairs(disk) do
            if k:match("^" .. name:gsub("([%%%.])", "%%%1"):gsub("%*", "%.%*") .. "$") then
                retval[k] = aux_find(parts2, v)
            end
        end
    end
    return retval
end

local function gen_disk(include_contents,path)
    sleep()
    local path = path or ""
    local pth = fs.getName(path)
    local tree = {}
    for _,v in pairs(fs.list(path)) do
        if fs.isDir(path.."/"..v) then
            tree[v] = gen_disk(include_contents,path.."/"..v)
        else
            local contents = ""
            if include_contents then
                local chandle = fs.open(path.."/"..v,'r')
                contents = chandle.readAll()
                chandle.close()
            end
            tree[v] = contents
        end
    end
    return tree
end

return {
    ['combineKeys'] = combineKeys,
    ['aux_find'] = aux_find,
    ['gen_disk'] = gen_disk
}