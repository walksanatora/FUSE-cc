
local uuid_cout = 0
local function handlerfactory(periph,basedir)
    function handler(name,options)

    end
    _G.MOUNTS[basedir] = "sfs"..uuid_cout
    _G.HANDLES["sfs"..uuid_cout] = handler
    uuid_cout = uuid_cout+1
end

