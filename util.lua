local function DeepCopy(obj,seen)
	--handle non-tables and previously-seen tables
	if type(obj) ~="table" then return obj end

	--make a New table; then mark as seen and then copy recursively
	local s = seen or {}
	local res = {}
	s[obj] = res
	for k, v in pairs(obj) do res[DeepCopy(k,s)] = DeepCopy(v,s)end
	return setmetatable(res,getmetatable(obj))
end

function split(str, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for sstr in string.gmatch(str, "([^"..sep.."]+)") do
			table.insert(t, sstr)
	end
	return t
end

function starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

--merges t2 into t1 (overwriting values in t1)
local function merge(t1,t2)
	for k,v in pairs(t2) do
		if type(v) == 'table' then
			if type(t1[k]or false) == 'table' then
				merge(t1[k] or {},t2[k] or {})
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
end

--TODO: create generic handles for binary read
--creates a read handle from a string
function genericReadHandle(buffer)
	local readHandle = {}
    local lbuf = buffer
    local closed = false
    function readHandle.readLine(trailing)
        if closed then error("File has been closed") end
        if string.len(lbuf) == 0 then return nil end
        local lines = split(lbuf,'\n')
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
end

return {
    ['clone'] = DeepCopy,
	['merge'] = merge,
	['startsWith'] = starts,
	['split'] = split,
	['createReadHandleFromBuf'] = genericReadHandle,
}

