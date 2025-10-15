local Config = require("lib.config")
local Log = require("lib.log")

local M = {}

---Pre-compute role sets as hash maps for O(1) lookup
---@return nil
function M:new()
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
	Log.log.df("[M.init] Initialized role maps")
end

---Checks if the role is jumpable
---@param role string
---@return boolean
function M:isJumpable(role)
	return self.jumpableSet and self.jumpableSet[role] == true
end

---Checks if the role is editable
---@param role string
---@return boolean
function M:isEditable(role)
	return self.editableSet and self.editableSet[role] == true
end

---Checks if the role should be skipped
---@param role string
---@return boolean
function M:shouldSkip(role)
	return self.skipSet and self.skipSet[role] == true
end

return M
