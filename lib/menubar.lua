---@diagnostic disable: undefined-global

local Config = require("lib.config")
local State = require("lib.state")
local Log = require("lib.log")

local M = {}

---Creates the menu bar item
---@return nil
function M.create()
	Log.log.df("[MenuBar.create] Creating menu bar item")

	if not Config.config.menubar.enabled then
		Log.log.df("[MenuBar.create] Menubar disabled")
		return
	end

	M.destroy()

	State.state.menubarItem = hs.menubar.new()
	State.menubarItem:setTitle(
		require("lib.modes").defaultModeChars[MODES.NORMAL]
	)
end

---Set the menubar title
---@param mode number
---@param keys string|nil
function M.setTitle(mode, keys)
	Log.log.df("[MenuBar.setTitle] Setting menubar title")

	if not Config.config.menubar.enabled or not State.state.menubarItem then
		Log.log.df("[MenuBar.setTitle] Menubar disabled")
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
	Log.log.df("[MenuBar.destroy] Destroying menu bar item")

	State:resetMenubarItem()
end

return M
