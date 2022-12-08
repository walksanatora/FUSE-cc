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
        elseif name == "open" then
            if string.match(opt["mode"],'r') then
                local fname = fs.getName(opt["path"])
                if fname == "info" then
                    return util.createReadHandleFromBuf(textutils.serialise(periph.list()))
                else
                    local slot = tonumber(fname)
                    if not slot then
                        error("slot is not a number")
                    end
                    if slot > periph.size() then
                        error("tried to index a item slot which does not exist")
                    end
                    local data = periph.getItemDetail(slot)
                    return util.createReadHandleFromBuf(textutils.serialise(data))
                end
            else
                error("Writability is a lie so mv works")
            end
        elseif name == "spec_move" then --special function to check "hey does the recieving fs have special functions for handling movement from this fs"
            return not not util.startsWith(opt["type"],"sfs:") -- check if string starts with sfs:, then cast to bool
        elseif name == "smove" then -- the actual handler for special move
            --get the peripheral we are pulling from
            local periph_name = string.sub(opt['type'],5)
            --get the slot we are pulling from
            local send_slot = tonumber(fs.getName(opt["path"]))
            if not send_slot then --make sure the slot is a number
                error("source item slot is not a number")
            end --make sure the slot is within the number of slots of the inventory
            if send_slot > peripheral.wrap(periph_name).size() then
                error("tried to index a item send_slot which does not exist (sender)")
            end

            --get the recieving slot (can be nil)
            local recv_slot = tonumber(fs.getName(opt["path"]))
            periph.pullItems(periph_name,send_slot,nil,recv_slot)
            return
        end
    end
    _G.MOUNTS[mdir] = "sfs:"..side
    _G.HANDLES["sfs:"..side] = handler
end


return handlerfactory