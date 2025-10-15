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

M.eventSourceIgnoreSignature = 0xDEADBEEFDEADBEEF -- 64-bit value

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
		M.eventSourceIgnoreSignature
	)
	up:setProperty(
		hs.eventtap.event.properties.eventSourceUserData,
		M.eventSourceIgnoreSignature
	)

	dn:post(application)
	if delay and delay > 0 then
		hs.timer.usleep(delay * 1e6)
	end
	up:post(application)
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
