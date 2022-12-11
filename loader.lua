local utils = require('util')
local find_util = require("find")

local enable_dbg = false

if settings.get("fuse.enable") then
    local fs_old = fs
    local fs_new = {}
    function fs_old_handle(func,options)
        local fpath = fs.combine("",options['path'])
        if func == 'attributes' then
            return fs_old.attributes(fpath)
        elseif func == 'list' then
            return fs_old.list(fpath)
        elseif func == 'open' then
            return fs_old.open(fpath,options['mode'])
        elseif func == 'exists' then
            return fs_old.exists(fpath)
        elseif func == 'mkdir' then
            return fs_old.makeDir(fpath)
        elseif func == 'delete' then
            return fs_old.delete(fpath)
        end
    end
    -- sMountpath : sName
    _G.MOUNTS = {
        [""] = "hdd", --since they have diffrent names
        ["rom"] = "rom"
    }
    -- sName : fHandle
    _G.HANDLES = {
        ['hdd'] = fs_old_handle,
        ['rom'] = fs_old_handle
    }
    --takes a path, gets the handler fname, then passes the type and options
    function getHandleName(path)
        local keys = utils.keys(MOUNTS)
        table.sort(keys,function(a,b) return #a>#b end)
        local sane_path = fs_old.combine("",path)
        --print("checking for: '"..sane_path.."'")
        for _, k in ipairs(keys) do
            --print("trying: '"..k.."'")
            if utils.startsWith(sane_path,k) or sane_path == k then
                --print("selected name: "..k)
                return MOUNTS[k]
            end
        end
        return fs_old.getDrive(path)
    end

    --takes a path, calls the handler function with args
    function callHandle(path,name,opts)
        local handle_name = getHandleName(path)
        --print("calling "..name.." for: "..path)
        if handle_name then
            return HANDLES[handle_name](name,opts)
        else return nil end
    end

    --#region pass throughs
    fs_new.complete = fs_old.complete
    fs_new.combine = fs_old.combine
    fs_new.getName = fs_old.getName
    fs_new.getDir = fs_old.getDir
    fs_new.getFreeSpace = fs_old.getFreeSpace
    fs_new.getCapacity = fs_old.getCapacity
    --#endregion
    --modified functions
    function fs_new.isDriveRoot(path)
        local cpath = fs_old.combine("",path)
        if not fs.exists(cpath) then error("path does not exists") end
        for k,_ in pairs(MOUNTS) do
            if k == cpath then return true end
        end
        return false
    end
    function fs_new.list(path)
        local listed = callHandle(path,'list',{['path']=path})
        for _, v in ipairs(utils.keys(MOUNTS)) do
            local p = fs.getDir(v)
            local n = fs.getName(v)
            local s = textutils.serialise
            if (p == path) and (string.len(n) ~= 0) and not utils.contains(listed,n) then
                --print("appending: "..n)
                table.insert(listed,n)
            --else
            --    print(s(p == path)..s(string.len(n) ~= 0)..s(not utils.contains(listed,n)).."\np:"..p.." n:"..n)
            end
        end
        return listed
    end
    function fs_new.getSize(path)
        return fs_new.attributes(path)['size']
    end
    function fs_new.exists(path)
        return callHandle(path,'exists',{['path']=path})
    end
    function fs_new.isDir(path)
        local isd = false
        xpcall(function()
            isd = fs_new.attributes(path)['isDir']
        end,function()
            if enable_dbg then print("TRACEBACK: "..debug.traceback())end
        end)
        return isd
    end
    function fs_new.isReadOnly(path)
        local iro = false
        xpcall(function()
            iro = fs_new.attributes(path)['isReadOnly']
        end,function()
            if enable_dbg then print("TRACEBACK: "..debug.traceback())end
        end)
        return iro
    end
    function fs_new.makeDir(path)
        return callHandle(path,'mkdir',{['path']=path})
    end
    function fs_new.move(path,dest)
        local srct = fs_new.getDrive(path)
        local dstt = fs_new.getDrive(dest)
        if srct == dstt then --fs types are the same type, *I would hope you can copy between them*
            return callHandle(path,"move",{['path']=path,['dest']=dest})
        else
            if HANDLES[dstt]("spec_move",{['path']=path,['dest']=dest,['type']=srct}) then --check if destination has a special handler for when the source fs copies to it
                return HANDLES[dbg]("smove",{['path']=path,['dest']=dest,['type']=srct})
            else
                local rhandle = HANDLES[srct]("open",{['path']=path,['mode']='r'})
                local whandle = HANDLES[dstt]("open",{['path']=dest,['mode']='w'}) --most errors are here
                local rdata = ""
                while rdata do
                    rdata = rhandle.read(32)
                    if rdata then print("wrote: "..rdata) end
                    whandle.write(rdata)
                    whandle.flush()
                end
                rhandle.close()
                whandle.close()
                fs_new.delete(path)
            end
        end
    end
    function fs_new.copy(path,dest)
        local srct = fs_new.getDrive(path)
        local dstt = fs_new.getDrive(dest)
        if srct == dstt then --fs types are the same type, *I would hope you can copy between them*
            return callHandle(path,"copy",{['path']=path,['dest']=dest})
        else
            if HANDLES[dstt]("spec_copy",{['path']=path,['dest']=dest,['type']=srct}) then --check if destination has a special handler for when the source fs copies to it
                return HANDLES[dstt]("scopy",{['path']=path,['dest']=dest,['type']=srct})
            else
                local rhandle = HANDLES[srct]("open",{['path']=path,['mode']='r'})
                local whandle = HANDLES[dstt]("open",{['path']=dest,['mode']='w'}) --most errors are here
                local rdata = ""
                while rdata do
                    rdata = rhandle.read(32)
                    if rdata then print("wrote: "..rdata) end
                    whandle.write(rdata)
                    whandle.flush()
                end
                rhandle.close()
                whandle.close()
            end
        end
    end
    function fs_new.delete(path)
        return callHandle(path,'delete',{['path']=path})
    end
    function fs_new.open(path,mode)
        return callHandle(path,'open',{['path']=path,['mode']=mode})
    end
    function fs_new.getDrive(path)
        return getHandleName(path)
    end
    function fs_new.find(wildcard)
        local parts = {}
        for p in wildcard:gmatch("[^/]+") do parts[#parts+1] = p end
        local retval = {}
        for _,v in ipairs(find_util.combineKeys(find_util.aux_find(parts, shell.dir()))) do
            table.insert(retval, v)
        end
        table.sort(retval)
        return retval
    end
    function fs_new.attributes(path)
        return callHandle(path,'attributes',{['path'] = path})
    end

    function fs_new.unload()
        _G.fs = fs_old
        _G.MOUNTS = nil
        _G.HANDLES = nil
        shell.setDir("/")
    end
    _G.fs = fs_new
else
    printError("fuse is not enabled, please set fuse.enable")
end