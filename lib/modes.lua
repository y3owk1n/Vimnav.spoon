---@diagnostic disable: undefined-global

local State = require("lib.state")
local Log = require("lib.log")

local M = {}

local MODES = {
	DISABLED = 1,
	NORMAL = 2,
	INSERT = 3,
	INSERT_NORMAL = 4,
	INSERT_VISUAL = 5,
	LINKS = 6,
	PASSTHROUGH = 7,
	VISUAL = 8,
}

local defaultModeChars = {
	[MODES.DISABLED] = "X",
	[MODES.INSERT] = "I",
	[MODES.INSERT_NORMAL] = "IN",
	[MODES.INSERT_VISUAL] = "IV",
	[MODES.LINKS] = "L",
	[MODES.NORMAL] = "N",
	[MODES.PASSTHROUGH] = "P",
	[MODES.VISUAL] = "V",
}

M.MODES = MODES
M.defaultModeChars = defaultModeChars

---Sets the mode
---@param mode number Mode to set
---@return boolean success Whether the mode was set
---@return number|nil prevMode The previous mode
function M.setMode(mode)
	Log.log.df("[Modes.setMode] Setting mode: %s", mode)
	if mode == State.state.mode then
		Log.log.df("[Modes.setMode] Mode already set to %s... abort", mode)
		return false
	end

	local previousMode = State.state.mode

	State.state.mode = mode

	require("lib.cleanup").onModeChange(previousMode, mode)

	require("lib.menubar"):setTitle(mode)
	require("lib.overlay").update(mode)

	Log.log.df("[Modes.setMode] Mode changed: %s -> %s", previousMode, mode)

	return true, previousMode
end

---Checks if the current mode is the given mode
---@param mode number Mode to check
---@return boolean
function M.isMode(mode)
	local isMode = State.state.mode == mode

	Log.log.df("[Modes.isMode] Mode is %s: %s", mode, tostring(isMode))

	return isMode
end

---Set mode to disabled
---@return boolean
function M.setModeDisabled()
	Log.log.df("[Modes.setModeDisabled] Setting mode to disabled")

	return M.setMode(M.MODES.DISABLED)
end

---Set mode to passthrough
---@return boolean
function M.setModePassthrough()
	Log.log.df("[Modes.setModePassthrough] Setting mode to passthrough")

	local ok = M.setMode(M.MODES.PASSTHROUGH)

	if not ok then
		return false
	end

	require("lib.marks").clear()

	return true
end

---Set mode to links
---@return boolean
function M.setModeLink()
	Log.log.df("[Modes.setModeLink] Setting mode to links")

	local ok = M.setMode(M.MODES.LINKS)

	if not ok then
		return false
	end

	require("lib.marks").clear()

	return true
end

---Set mode to insert
---@return boolean
function M.setModeInsert()
	Log.log.df("[Modes.setModeInsert] Setting mode to insert")

	local ok = M.setMode(M.MODES.INSERT)

	if not ok then
		return false
	end

	require("lib.marks").clear()

	return true
end

---Set mode to insert normal
---@return boolean
function M.setModeInsertNormal()
	Log.log.df("[Modes.setModeInsertNormal] Setting mode to insert normal")

	local ok = M.setMode(M.MODES.INSERT_NORMAL)

	if not ok then
		return false
	end

	require("lib.marks").clear()

	return true
end

---Set mode to insert visual
---@return boolean
function M.setModeInsertVisual()
	Log.log.df("[Modes.setModeInsertVisual] Setting mode to insert visual")

	local ok = M.setMode(M.MODES.INSERT_VISUAL)

	if not ok then
		return false
	end

	require("lib.marks").clear()

	return true
end

---Set mode to visual
---@return boolean
function M.setModeVisual()
	Log.log.df("[Modes.setModeVisual] Setting mode to visual")

	local ok = M.setMode(M.MODES.VISUAL)

	if not ok then
		return false
	end

	require("lib.marks").clear()

	return true
end

---Set mode to normal
---@return boolean
function M.setModeNormal()
	Log.log.df("[Modes.setModeNormal] Setting mode to normal")

	local ok = M.setMode(M.MODES.NORMAL)

	if not ok then
		return false
	end

	require("lib.marks").clear()

	return true
end

return M
