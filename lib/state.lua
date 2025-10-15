---@diagnostic disable: undefined-global

local Utils = require("lib.utils")
local Log = require("lib.log")

local M = {}

---@type Hs.Vimnav.State
local defaultState = {
	focusCachedResult = false,
	focusLastElement = nil,
}

---@type Hs.Vimnav.State
M.state = {}

---Creates the state
---@return nil
function M:new()
	Log.log.df("[State:new] Creating state")

	self.state = Utils.deepCopy(defaultState)
end

---Reset all state completely
---@return nil
function M:resetAll()
	Log.log.df("[State:resetAll] Resetting all state")
	self.state = Utils.deepCopy(defaultState)
end

return M
