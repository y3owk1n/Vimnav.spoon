---@diagnostic disable: undefined-global

local Config = require("lib.config")
local Log = require("lib.log")

local M = {}

---Menubar item
M.item = nil

---Creates the menu bar item
---@return nil
function M:create()
	Log.log.df("[MenuBar.create] Creating menu bar item")

	if not Config.config.menubar.enabled then
		Log.log.df("[MenuBar.create] Menubar disabled")
		return
	end

	M:destroy()

	local Modes = require("lib.modes")

	self.item = hs.menubar.new()
	self.item:setTitle(Modes.defaultModeChars[Modes.MODES.NORMAL])
end

---Set the menubar title
---@param mode number Mode to set
---@param keys string|nil Keys to display
---@return nil
function M:setTitle(mode, keys)
	Log.log.df("[MenuBar.setTitle] Setting menubar title")

	if not Config.config.menubar.enabled or not self.item then
		Log.log.df("[MenuBar.setTitle] Menubar disabled")
		return
	end

	local modeChar = require("lib.modes").defaultModeChars[mode] or "?"

	local toDisplayModeChar = modeChar

	if keys then
		toDisplayModeChar = string.format("%s [%s]", modeChar, keys)
	end

	self.item:setTitle(toDisplayModeChar)
end

---Destroys the menu bar item
---@return nil
function M:destroy()
	Log.log.df("[MenuBar.destroy] Destroying menu bar item")

	if self.item then
		self.item:delete()
		self.item = nil
	end
end

return M
