local Config = require("lib.config")
local State = require("lib.state")
local Log = require("lib.log")

local M = {}

---Creates the menu bar item
---@return nil
function M.create()
	if not Config.config.menubar.enabled then
		return
	end

	M.destroy()

	State.state.menubarItem = hs.menubar.new()
	State.menubarItem:setTitle(
		require("lib.modes").defaultModeChars[MODES.NORMAL]
	)
	Log.log.df("[MenuBar.create] Created menu bar item")
end

---Set the menubar title
---@param mode number
---@param keys string|nil
function M.setTitle(mode, keys)
	if not Config.config.menubar.enabled or not State.state.menubarItem then
		return
	end

	local modeChar = require("lib.modes").defaultModeChars[mode] or "?"

	local toDisplayModeChar = modeChar

	if keys then
		toDisplayModeChar = string.format("%s [%s]", modeChar, keys)
	end

	State.state.menubarItem:setTitle(toDisplayModeChar)
end

---Destroys the menu bar item
---@return nil
function M.destroy()
	State:resetMenubarItem()
end

return M
