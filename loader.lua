local utils = require('util')

local dbg = peripheral.find("debugger")

local function print(str)
    if dbg and true then
        dbg.print(str)
    end
end

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
        [""] = "hdd",
        ["rom"] = "rom"
    }
    -- sName : fHandle
    _G.HANDLES = {
        ['hdd'] = fs_old_handle,
        ['rom'] = fs_old_handle
    }
    --takes a path, gets the handler fname, then passes the type and options
    function getHandleName(path)
        local keys = {}
        local cout = 1
        for k, _ in pairs(MOUNTS) do
            keys[cout] = k
            cout = cout + 1
        end
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
    fs_new.isDriveRoot = fs_old.isDriveRoot --TODO: make this a modified function since modified mounts exist
    fs_new.combine = fs_old.combine
    fs_new.getName = fs_old.getName
    fs_new.getDir = fs_old.getDir
    fs_new.getFreeSpace = fs_old.getFreeSpace
    fs_new.getCapacity = fs_old.getCapacity
    --#endregion
    --modified functions
    function fs_new.list(path)
        return callHandle(path,'list',{['path']=path})
    end
    function fs_new.getSize(path)
        return fs_new.attributes(path)['size']
    end
    function fs_new.exists(path)
        return callHandle(path,'exists',{['path']=path})
    end
    function fs_new.isDir(path)
        local iro = false
        xpcall(function()
            isd = fs_new.attributes(path)['isDir']
        end,function()print("TRACEBACK: "..debug.traceback())end)
        return iro
    end
    function fs_new.isReadOnly(path)
        local iro = false
        xpcall(function()
            iro = fs_new.attributes(path)['isReadOnly']
        end,function()print("TRACEBACK: "..debug.traceback().."\n\n")end)
        return iro
    end
    function fs_new.makeDir(path)
        return callHandle(path,'mkdir',{['path']=path})
    end
    function fs_new.move(path,dest)
        --todo implement, was gonna just do it but then remember cross-fs moves
    end
    function fs_new.copy(path,dest)
        local srct = fs_new.getDrive(path)
        local dstt = fs_new.getDrive(dest)
        if srct == dstt then
            return callHandle(path,"copy",{['path']=path,['dest']=dest})
        else
            if HANDLES[dstt]("spec_copy",{['path']=path,['dest']=dest,['type']=srct}) then
                print("destination fs has special handlers for fs type: "..srct)
                HANDLES[dbg]("scopy",{['path']=path,['dest']=dest,['type']=srct})
            else
                print("destination lacks special handlers for fs type, time to read,write data")
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
    fs_new.find = fs_old.find
    function fs_new.attributes(path)
        return callHandle(path,'attributes',{['path'] = path})
    end

    function fs_new.restore()
        _G.fs = fs_old
        _G.MOUNTS = nil
        _G.HANDLES = nil
    end
    _G.fs = fs_new
else
    printError("fuse is not enabled, please set fuse.enable")
end