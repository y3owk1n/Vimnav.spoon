local M = {}

M.cache = {}

function M:new()
	self.cache.elements = setmetatable({}, { __mode = "k" })
	self.cache.attributes = setmetatable({}, { __mode = "k" })
	self.cache.electrons = setmetatable({}, { __mode = "k" })
	self.cache.canvasTemplate = {}
	self.cache.markPool = {}
	self.cache.markActive = {}
end

---Gets an element from the cache
---@param key string
---@param factory fun(): Hs.Vimnav.Element|nil
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M:getElement(key, factory, force)
	force = force or false

	if
		self.cache.elements[key]
		and pcall(function()
			return self.cache.elements[key]:isValid()
		end)
		and self.cache.elements[key]:isValid()
		and not force
	then
		return self.cache.elements[key]
	end

	local element = factory()
	if element then
		self.cache.elements[key] = element
	end
	return element
end

---Gets an attribute from an element
---@param element Hs.Vimnav.Element
---@param attributeName string
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M:getAttribute(element, attributeName, force)
	if not element then
		return nil
	end

	local cacheKey = tostring(element) .. ":" .. attributeName
	local cached = self.cache.attributes[cacheKey]

	if cached ~= nil and not force then
		return cached == "NIL_VALUE" and nil or cached
	end

	local success, result = pcall(function()
		return element:attributeValue(attributeName)
	end)

	result = success and result or nil

	-- Store nil as a special marker to distinguish from uncached
	self.cache.attributes[cacheKey] = result == nil and "NIL_VALUE" or result
	return result
end

---Reuse mark objects to avoid GC pressure
---@return table
function M:getMark()
	local mark = table.remove(self.cache.markPool)
	if not mark then
		mark = { element = nil, frame = nil, role = nil }
	end
	self.cache.markActive[#self.cache.markActive + 1] = mark
	return mark
end

---Release all marks
---@return nil
function M:clearMarks()
	for i = 1, #self.cache.markActive do
		local mark = self.cache.markActive[i]
		mark.element = nil
		mark.frame = nil
		mark.role = nil
		self.cache.markPool[#self.cache.markPool + 1] = mark
	end
	self.cache.markActive = {}
end

function M:clearElements()
	self.cache.elements = setmetatable({}, { __mode = "k" })
	self.cache.attributes = setmetatable({}, { __mode = "k" })
end

function M:clearElectron()
	self.cache.electrons = setmetatable({}, { __mode = "k" })
end

function M:clearCanvasTemplate()
	self.cache.canvasTemplate = nil
end

function M:clearAll()
	self:clearElements()
	self:clearElectron()
	self:clearCanvasTemplate()
	self:clearMarks()
end

function M:collectGarbage()
	collectgarbage("collect")
end

return M
