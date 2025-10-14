---@diagnostic disable: undefined-global

local M = {}

---Helper function to check if something is a "list-like" table
---@param t table
---@return boolean
function M.isList(t)
	if type(t) ~= "table" then
		return false
	end
	local count = 0
	for k, _ in pairs(t) do
		count = count + 1
		if type(k) ~= "number" or k <= 0 or k > count then
			return false
		end
	end
	return true
end

---Helper function to deep copy a value
---@param obj table
---@return table
function M.deepCopy(obj)
	if type(obj) ~= "table" then
		return obj
	end

	local copy = {}
	for k, v in pairs(obj) do
		copy[k] = M.deepCopy(v)
	end
	return copy
end

---Merges two tables with optional array extension
---@param base table Base table
---@param overlay table Table to merge into base
---@param extendArrays boolean If true, arrays are merged; if false, arrays are replaced
---@return table Merged result
function M.tblMerge(base, overlay, extendArrays)
	local result = M.deepCopy(base)

	for key, value in pairs(overlay) do
		local baseValue = result[key]
		local isOverlayArray = type(value) == "table" and M.isList(value)
		local isBaseArray = type(baseValue) == "table" and M.isList(baseValue)

		if extendArrays and isOverlayArray and isBaseArray then
			-- both are arrays: merge without duplicates
			for _, v in ipairs(value) do
				if not M.tblContains(baseValue, v) then
					table.insert(baseValue, v)
				end
			end
		elseif type(value) == "table" and type(baseValue) == "table" then
			-- both are tables (objects or mixed): recurse
			result[key] = M.tblMerge(baseValue, value, extendArrays)
		else
			-- plain value or type mismatch: replace
			result[key] = M.deepCopy(value)
		end
	end

	return result
end

---Checks if a table contains a value
---@param tbl table
---@param val any
---@return boolean
function M.tblContains(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

local eventSourceIgnoreSignature = 0xDEADBEEFDEADBEEF -- 64-bit value

---Custom keyStroke function
---This is a modified version that will send a special userData to the eventloop
---and ask it to ignore keys from here
---@param mods "cmd"|"ctrl"|"alt"|"shift"|"fn"|("cmd"|"ctrl"|"alt"|"shift"|"fn")[]
---@param key string
---@param delay? number
---@param application? table
---@return nil
function M.keyStroke(mods, key, delay, application)
	if type(mods) == "string" then
		mods = { mods }
	end

	local dn = hs.eventtap.event.newKeyEvent(mods, key, true)
	local up = hs.eventtap.event.newKeyEvent(mods, key, false)

	dn:setProperty(
		hs.eventtap.event.properties.eventSourceUserData,
		eventSourceIgnoreSignature
	)
	up:setProperty(
		hs.eventtap.event.properties.eventSourceUserData,
		eventSourceIgnoreSignature
	)

	dn:post(application)
	if delay and delay > 0 then
		hs.timer.usleep(delay * 1e6)
	end
	up:post(application)
end

---Gets an element from the cache
---@param vimnav Hs.Vimnav
---@param key string
---@param factory fun(): Hs.Vimnav.Element|nil
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getCachedElement(vimnav, key, factory, force)
	force = force or false

	if
		vimnav.cache.elements[key]
		and pcall(function()
			return vimnav.cache.elements[key]:isValid()
		end)
		and vimnav.cache.elements[key]:isValid()
		and not force
	then
		return vimnav.cache.elements[key]
	end

	local element = factory()
	if element then
		vimnav.cache.elements[key] = element
	end
	return element
end

---Gets an attribute from an element
---@param vimnav Hs.Vimnav
---@param element Hs.Vimnav.Element
---@param attributeName string
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAttribute(vimnav, element, attributeName, force)
	if not element then
		return nil
	end

	local cacheKey = tostring(element) .. ":" .. attributeName
	local cached = vimnav.cache.attributes[cacheKey]

	if cached ~= nil and not force then
		return cached == "NIL_VALUE" and nil or cached
	end

	local success, result = pcall(function()
		return element:attributeValue(attributeName)
	end)

	result = success and result or nil

	-- Store nil as a special marker to distinguish from uncached
	vimnav.cache.attributes[cacheKey] = result == nil and "NIL_VALUE" or result
	return result
end

---Generates all combinations of letters
---@param vimnav Hs.Vimnav
---@return nil
function M.generateCombinations(vimnav)
	if #vimnav.state.allCombinations > 0 then
		vimnav.log.df("[M.generateCombinations] Already generated combinations")
		return
	end -- Already generated

	local chars = vimnav.config.hints.chars

	if not chars then
		vimnav.log.ef(
			"[M.generateCombinations] No link hint characters configured"
		)
		return
	end

	vimnav.state.maxElements = #chars * #chars

	for i = 1, #chars do
		for j = 1, #chars do
			table.insert(
				vimnav.state.allCombinations,
				chars:sub(i, i) .. chars:sub(j, j)
			)
			if #vimnav.state.allCombinations >= vimnav.state.maxElements then
				return
			end
		end
	end
	vimnav.log.df(
		"[M.generateCombinations] Generated "
			.. #vimnav.state.allCombinations
			.. " combinations"
	)
end

---Fetches all mapping prefixes
---@param vimnav Hs.Vimnav
---@return nil
function M.fetchMappingPrefixes(vimnav)
	vimnav.state.mappingPrefixes = {}
	vimnav.state.mappingPrefixes.normal = {}
	vimnav.state.mappingPrefixes.visual = {}
	vimnav.state.mappingPrefixes.insertNormal = {}
	vimnav.state.mappingPrefixes.insertVisual = {}

	local leaderKey = vimnav.config.leader.key or " "

	local function addLeaderPrefixes(mapping, prefixTable)
		for k, v in pairs(mapping) do
			if v == "noop" then
				goto continue
			end

			-- Handle leader key mappings
			if k:sub(1, 8) == "<leader>" then
				-- Mark leader key as prefix
				prefixTable[leaderKey] = true

				-- Extract the part after <leader>
				local afterLeader = k:sub(9)
				if #afterLeader > 1 then
					-- Add all prefixes for multi-char sequences
					-- e.g., for "<leader>ba", add "<leader>b" as prefix
					for i = 1, #afterLeader - 1 do
						local prefix = "<leader>" .. afterLeader:sub(1, i)
						prefixTable[prefix] = true
					end
				end
			elseif #k == 2 then
				prefixTable[string.sub(k, 1, 1)] = true
			elseif #k == 3 then
				prefixTable[string.sub(k, 1, 1)] = true
				prefixTable[string.sub(k, 1, 2)] = true
			end
			::continue::
		end
	end

	addLeaderPrefixes(
		vimnav.config.mapping.normal,
		vimnav.state.mappingPrefixes.normal
	)
	addLeaderPrefixes(
		vimnav.config.mapping.insertNormal,
		vimnav.state.mappingPrefixes.insertNormal
	)
	addLeaderPrefixes(
		vimnav.config.mapping.insertVisual,
		vimnav.state.mappingPrefixes.insertVisual
	)
	addLeaderPrefixes(
		vimnav.config.mapping.visual,
		vimnav.state.mappingPrefixes.visual
	)

	vimnav.log.df("[M.fetchMappingPrefixes] Fetched mapping prefixes")
end

---Convert hex to RGB table
---@param hex string
---@return table
function M.hexToRgb(hex)
	hex = hex:gsub("#", "")
	return {
		red = tonumber("0x" .. hex:sub(1, 2)) / 255,
		green = tonumber("0x" .. hex:sub(3, 4)) / 255,
		blue = tonumber("0x" .. hex:sub(5, 6)) / 255,
	}
end

---Double click at a point
---@param point table
function M.doubleClickAtPoint(point)
	-- first click
	local click1_down = hs.eventtap.event.newMouseEvent(
		hs.eventtap.event.types.leftMouseDown,
		point
	)
	local click1_up = hs.eventtap.event.newMouseEvent(
		hs.eventtap.event.types.leftMouseUp,
		point
	)

	click1_down:setProperty(
		hs.eventtap.event.properties.mouseEventClickState,
		1
	)
	click1_up:setProperty(hs.eventtap.event.properties.mouseEventClickState, 1)

	click1_down:post()
	click1_up:post()

	-- second click
	local click2_down = hs.eventtap.event.newMouseEvent(
		hs.eventtap.event.types.leftMouseDown,
		point
	)
	local click2_up = hs.eventtap.event.newMouseEvent(
		hs.eventtap.event.types.leftMouseUp,
		point
	)

	click2_down:setProperty(
		hs.eventtap.event.properties.mouseEventClickState,
		2
	)
	click2_up:setProperty(hs.eventtap.event.properties.mouseEventClickState, 2)

	hs.timer.usleep(10000) -- setting it to 10ms... maybe vary based on diff macos settings on double click?

	click2_down:post()
	click2_up:post()
end

return M
