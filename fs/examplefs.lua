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
                local readHandle = {}
                local lbuf = "this is a example file from\nthe examplefs\n\nisn't it neat"
                local closed = false
                
                function readHandle.readLine(trailing)
                    if closed then error("File has been closed") end
                    if string.len(lbuf) == 0 then return nil end
                    local lines = utils.split(lbuf,'\n')
                    local first = table.remove(lines)
                    lbuf = table.concat(lines,'\n')
                    if trailing then
                        return first..'\n'
                    else
                        return first
                    end
                end

                function readHandle.readAll()
                    if closed then error("File has been closed") end
                    if string.len(lbuf) == 0 then return nil
                    else
                        local lbc = lbuf
                        lbuf=""
                        return lbc
                    end
                end

                function readHandle.read(charcout)
                    if closed then error("File has been closed") end
                    if string.len(lbuf) == 0 then return nil end
                    local chars = string.sub(lbuf,0,charcout or 1)
                    lbuf = string.sub(lbuf,(charcout or 1)+1)
                    return chars
                end

                function readHandle.close()
                    if closed then error("File has been closed") end
                    lbuf = ""
                    closed = true
                end

                return readHandle
            elseif string.match(opts['mode'],'w') then
                --bin write
                error("File System is Read Only")
            else
                error('invalid mode: '..opts['mode'])
            end
        else
            if string.match(opts['mode'],'r') then

                local readHandle = {}
                local lbuf = "this is a example file from\nthe examplefs\nisn't it neat"
                local closed = false
                
                function readHandle.readLine(trailing)
                    if closed then error("File has been closed") end
                    if string.len(lbuf) == 0 then return nil end
                    local lines = utils.split(lbuf,'\n')
                    local first = table.remove(lines)
                    lbuf = table.concat(lines,'\n')
                    if trailing then
                        return first..'\n'
                    else
                        return first
                    end
                end

                function readHandle.readAll()
                    if closed then error("File has been closed") end
                    if string.len(lbuf) == 0 then return nil
                    else
                        local lbc = lbuf
                        lbuf=""
                        return lbc
                    end
                end

                function readHandle.read(charcout)
                    if closed then error("File has been closed") end
                    if string.len(lbuf) == 0 then return nil end
                    local chars = string.sub(lbuf,0,charcout or 1)
                    lbuf = string.sub(lbuf,(charcout or 1)+1)
                    return chars
                end

                function readHandle.close()
                    if closed then error("File has been closed") end
                    lbuf = ""
                    closed = true
                end

                return readHandle
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