local util = require("FUSE.util")

local function handlerfactory(periph,mdir,side)
    function handler(name,opt)
        if name == "attributes" then
            if opt['path'] == mdir then
                return {
                    ['size'] = periph.size(),
                    ['isDir'] = true,
                    ['isReadOnly'] = false,
                    ['created'] = 0,
                    ['modified'] = 0
                }
            else
                local File = fs.getName(opt['path'])
                local nSlotid = tonumber(File)
                if nSlotid then
                    return {
                        ['size'] = periph.getItemLimit("size"),
                        ['isDir'] = false,
                        ['isReadOnly'] = false,
                        ['created'] = 0,
                        ['modified'] = 0
                    }
                elseif File == "info" then
                    return {
                        ['size'] = 0,
                        ['isDir'] = false,
                        ['isReadOnly'] = true,
                        ['created'] = 0,
                        ['modified'] = 0
                    }
                end
                error("Invalid path")
            end
        elseif name == "list" then
            local slots = {}
            local cout = 0
            for _ in pairs(periph.list()) do
                table.insert(slots,tostring(cout))
                cout = cout+1
            end
            table.insert(slots,"info")
            return slots
        end
    end
    _G.MOUNTS[mdir] = "sfs:"..side
    _G.HANDLES["sfs:"..side] = handler
end


return handlerfactory