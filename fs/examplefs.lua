--mounter for examplefs
local utils = require('util')

local d = peripheral.find("debugger")

function handler(name,opts)
    if name == "attributes" then --https://tweaked.cc/module/fs.html#v:attributes
        return {
            ['size'] = 0,
            ['isDir'] = opts['path'] == "example",
            ['isReadOnly'] = true,
            ['created'] = 0,
            ['modified'] = 0
        }
    elseif name == "list" then --https://tweaked.cc/module/fs.html#v:list
        return {"examplefile"}
    elseif name == "open" then --https://tweaked.cc/module/fs.html#v:open
        if string.match(opts['mode'],'b') then
            if string.match(opts['mode'],'r') then
                return utils.createReadHandleFromBuf("this is a example file from\nthe examplefs\n\nisn't it neat")
            elseif string.match(opts['mode'],'w') then
                --bin write
                error("File System is Read Only")
            else
                error('invalid mode: '..opts['mode'])
            end
        else
            if string.match(opts['mode'],'r') then
                return utils.createReadHandleFromBuf("this is a example file from\nthe examplefs\n\nisn't it neat")
            elseif string.match(opts['mode'],'w') then
                --write
            else
                error('invalid mode: '..opts['mode'])
            end
        end
        --todo: implement open handlers for w,wb,r,rb
    elseif name == "delete" then --https://tweaked.cc/module/fs.html#v:delete
        error("examplefs is not writable")
    elseif name == "exists" then
        return not not string.find(opts.path,"examplefile")
    end
end

_G.MOUNTS["example"] = "examplefs"
_G.HANDLES["examplefs"] = handler

print("loaded example file system")