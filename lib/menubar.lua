local State = dofile(hs.spoons.resourcePath("./state.lua"))
local Constants = dofile(hs.spoons.resourcePath("./constants.lua"))

local M = {}

---Creates the menu bar item
---@param vimnav Hs.Vimnav
---@return nil
function M.create(vimnav)
	if not vimnav.config.menubar.enabled then
		return
	end

	M.destroy(vimnav)

	vimnav.state.menubarItem = hs.menubar.new()
	vimnav.state.menubarItem:setTitle(
		Constants.defaultModeChars[Constants.MODES.NORMAL]
	)
	vimnav.log.df("[M.create] Created menu bar item")
end

---Set the menubar title
---@param vimnav Hs.Vimnav
---@param mode number
---@param keys string|nil
function M.setTitle(vimnav, mode, keys)
	if not vimnav.config.menubar.enabled or not vimnav.state.menubarItem then
		return
	end

	local modeChar = Constants.defaultModeChars[mode] or "?"

	local toDisplayModeChar = modeChar

	if keys then
		toDisplayModeChar = string.format("%s [%s]", modeChar, keys)
	end

	vimnav.state.menubarItem:setTitle(toDisplayModeChar)
end

---Destroys the menu bar item
---@param vimnav Hs.Vimnav
---@return nil
function M.destroy(vimnav)
	State.resetMenubarItem(vimnav)
end

return M
