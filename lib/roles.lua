---@diagnostic disable: undefined-global

local Config = require("lib.config")
local Log = require("lib.log")

local M = {}

---Pre-compute role sets as hash maps for O(1) lookup
---@return nil
function M:new()
	Log.log.df("[Roles.init] Initializing role maps")

	self.jumpableSet = {}
	for _, role in ipairs(Config.config.axRoles.jumpable) do
		self.jumpableSet[role] = true
	end

	self.editableSet = {}
	for _, role in ipairs(Config.config.axRoles.editable) do
		self.editableSet[role] = true
	end

	self.skipSet = {
		AXGenericElement = true,
		AXUnknown = true,
		AXSeparator = true,
		AXSplitter = true,
		AXProgressIndicator = true,
		AXValueIndicator = true,
		AXLayoutArea = true,
		AXLayoutItem = true,
		AXStaticText = true, -- Usually not interactive
	}
end

---Checks if the role is jumpable
---@param role string
---@return boolean
function M:isJumpable(role)
	local isJumpable = self.jumpableSet and self.jumpableSet[role] == true

	Log.log.df(
		"[Roles.isJumpable] Role=%s, isJumpable=%s",
		role,
		tostring(isJumpable)
	)

	return isJumpable
end

---Checks if the role is editable
---@param role string
---@return boolean
function M:isEditable(role)
	local isEditable = self.editableSet and self.editableSet[role] == true

	Log.log.df(
		"[Roles.isEditable] Role=%s, isEditable=%s",
		role,
		tostring(isEditable)
	)

	return isEditable
end

---Checks if the role should be skipped
---@param role string
---@return boolean
function M:shouldSkip(role)
	local shouldSkip = self.skipSet and self.skipSet[role] == true

	Log.log.df(
		"[Roles.shouldSkip] Role=%s, shouldSkip=%s",
		role,
		tostring(shouldSkip)
	)

	return shouldSkip
end

return M
