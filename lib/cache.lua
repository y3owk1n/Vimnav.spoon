---@diagnostic disable: undefined-global

local Log = require("lib.log")

local M = {}

M.cache = {}

function M:new()
	Log.log.df("[Cache.new] Creating cache")

	self.cache.elements = setmetatable({}, { __mode = "k" })
	self.cache.attributes = setmetatable({}, { __mode = "k" })
	self.cache.electrons = setmetatable({}, { __mode = "k" })
	self.cache.canvasTemplate = {}
	self.cache.markPool = {}
	self.cache.markActive = {}
end

---Gets an element from the cache
---@param key string The key to use for the cache
---@param factory fun(): Hs.Vimnav.Element|nil Factory function to create the element
---@param force? boolean If true, the element will be refreshed
---@return Hs.Vimnav.Element|nil
function M:getElement(key, factory, force)
	Log.log.df("[Cache.getElement] Getting element: %s", key)

	force = force or false

	if
		self.cache.elements[key]
		and pcall(function()
			return self.cache.elements[key]:isValid()
		end)
		and self.cache.elements[key]:isValid()
		and not force
	then
		Log.log.df("[Cache.getElement] Found element in cache: %s", key)
		return self.cache.elements[key]
	end

	local element = factory()
	if element then
		self.cache.elements[key] = element
	end

	return element
end

---Gets an attribute from an element
---@param element Hs.Vimnav.Element The element to get the attribute from
---@param attributeName string The attribute to get
---@param force? boolean If true, the attribute will be refreshed
---@return Hs.Vimnav.Element|nil
function M:getAttribute(element, attributeName, force)
	Log.log.df(
		"[Cache.getAttribute] Getting attribute: %s for element: %s",
		attributeName,
		tostring(element)
	)

	if not element then
		Log.log.ef("[Cache.getAttribute] No element found")
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
	Log.log.df("[Cache.getMark] Getting mark")

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
	Log.log.df("[Cache.clearMarks] Clearing marks")

	for i = 1, #self.cache.markActive do
		local mark = self.cache.markActive[i]
		mark.element = nil
		mark.frame = nil
		mark.role = nil
		self.cache.markPool[#self.cache.markPool + 1] = mark
	end

	self.cache.markActive = {}
end

---Clears the cache for elements and attributes
---@return nil
function M:clearElements()
	Log.log.df("[Cache.clearElements] Clearing elements")

	self.cache.elements = setmetatable({}, { __mode = "k" })
	self.cache.attributes = setmetatable({}, { __mode = "k" })
end

---Clears the cache for electrons
---@return nil
function M:clearElectron()
	Log.log.df("[Cache.clearElectron] Clearing electrons")

	self.cache.electrons = setmetatable({}, { __mode = "k" })
end

---Clears the cache for canvas templates
---@return nil
function M:clearCanvasTemplate()
	Log.log.df("[Cache.clearCanvasTemplate] Clearing canvas templates")

	self.cache.canvasTemplate = nil
end

---Clears the cache for all caches
---@return nil
function M:clearAll()
	Log.log.df("[Cache.clearAll] Clearing all caches")

	self:clearElements()
	self:clearElectron()
	self:clearCanvasTemplate()
	self:clearMarks()
end

---Collects garbage
---@return nil
function M:collectGarbage()
	Log.log.df("[Cache.collectGarbage] Collecting garbage")

	collectgarbage("collect")
end

return M
