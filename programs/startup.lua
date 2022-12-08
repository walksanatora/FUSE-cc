--startup file for a custom storagefs that automatically mounts/unmounts file systems
_ = periphemu and periphemu.create("top","debugger")
shell.run("FUSE/loader")
shell.run("FUSE/fs/examplefs")
local sfs = require("FUSE.fs.storagefs")

shell.setPath(shell.path()..":/FUSE/programs")

--make sure the folder exist and is empty
fs.makeDir("stor")
fs.delete("stor/*")

parallel.waitForAny(function() --peripheral handler
    local sidemap = {}
    local dbg = peripheral.find("debugger")
    local function print(str)
        if dbg then
            dbg.print(str)
        end
    end

    --regenerate storage fs for all connected peripherals
    --since handles are cleared on reboot
    for _, side in ipairs(peripheral.getNames()) do
        local periph = peripheral.wrap(side)
        if periph.getItemDetail then
            fs.makeDir("stor/"..side)
            sfs(periph,"stor/"..side,side)
            table.insert(sidemap,side)
        end
    end

    parallel.waitForAny(function() --attach handler
        while true do
            local _,side = os.pullEvent("peripheral")
            local periph = peripheral.wrap(side)
            if periph.getItemDetail then
                fs.makeDir("stor/"..side)
                sfs(periph,"stor/"..side,side)
                table.insert(sidemap,side)
            end
        end
    end,
    function() --detach handler
        while true do
            local _,side = os.pullEvent("peripheral_detach")
            MOUNTS["stor/"..side] = nil
            HANDLES["sfs:"..side] = nil
            fs.delete("stor/"..side)
        end
    end)
end,
function () --spawn a shell for me good sir
    shell.run("shell");
    shell.exit()
end)