local State = require("lib.state")
local Log = require("lib.log")
local MenuBar = require("lib.menubar")
local Overlay = require("lib.overlay")

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
---@param mode number
---@return boolean success Whether the mode was set
---@return number|nil prevMode The previous mode
function M.setMode(mode)
	if mode == State.state.mode then
		Log.log.df(
			"[ModeManager.setMode] Mode already set to %s... abort",
			mode
		)
		return false
	end

	local previousMode = State.state.mode

	State.state.mode = mode

	require("lib.cleanup").onModeChange(previousMode, mode)

	MenuBar.setTitle(mode)
	Overlay.update(mode)

	Log.log.df(
		"[ModeManager.setMode] Mode changed: %s -> %s",
		previousMode,
		mode
	)

	return true, previousMode
end

---@param mode number
function M.getMode(mode)
	return defaultModeChars[mode] or "?"
end

---Checks if the current mode is the given mode
---@param mode number
---@return boolean
function M.isMode(mode)
	return State.state.mode == mode
end

---Set mode to disabled
---@return boolean
function M.setModeDisabled()
	return M.setMode(M.MODES.DISABLED)
end

---Set mode to passthrough
---@return boolean
function M.setModePassthrough()
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
	local ok = M.setMode(M.MODES.NORMAL)

	if not ok then
		return false
	end

	require("lib.marks").clear()

	return true
end

return M
