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

--https://discord.com/channels/477910221872824320/477911902152949771/1050676423997796372
--link is in the minecraftcomputermods discord
local function aux_find(parts, p)
    local ok, t = pcall(fs.list, p or "")
    if #parts == 0 then return fs.getName(p) elseif not ok then return nil end
    local parts2 = {}
    for i, v in ipairs(parts) do parts2[i] = v end
    local name = table.remove(parts2, 1)
    local retval = {}
    for _, k in pairs(t) do if k:match("^" .. name:gsub("([%%%.])", "%%%1"):gsub("%*", "%.%*") .. "$") then retval[k] = aux_find(parts2, fs.combine(p or "", k)) end end
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