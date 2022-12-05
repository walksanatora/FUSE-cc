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

return {
    ['clone'] = DeepCopy,
	['merge'] = merge,
	['startsWith'] = starts,
	['split'] = split,
}

