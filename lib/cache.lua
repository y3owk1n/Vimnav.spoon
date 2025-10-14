local M = {}

function M:new()
	local cache = {}
	cache.elements = setmetatable({}, { __mode = "k" })
	cache.attributes = setmetatable({}, { __mode = "k" })
	cache.electron = setmetatable({}, { __mode = "k" })
	return cache
end

return M
