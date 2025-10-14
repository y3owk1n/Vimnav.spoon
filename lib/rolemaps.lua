local M = {}

---Pre-compute role sets as hash maps for O(1) lookup
---@param vimnav Hs.Vimnav
---@return nil
function M.init(vimnav)
	M.jumpableSet = {}
	for _, role in ipairs(vimnav.config.axRoles.jumpable) do
		M.jumpableSet[role] = true
	end

	M.editableSet = {}
	for _, role in ipairs(vimnav.config.axRoles.editable) do
		M.editableSet[role] = true
	end

	M.skipSet = {
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
	vimnav.log.df("[M.init] Initialized role maps")
end

---Checks if the role is jumpable
---@param role string
---@return boolean
function M.isJumpable(role)
	return M.jumpableSet and M.jumpableSet[role] == true
end

---Checks if the role is editable
---@param role string
---@return boolean
function M.isEditable(role)
	return M.editableSet and M.editableSet[role] == true
end

---Checks if the role should be skipped
---@param role string
---@return boolean
function M.shouldSkip(role)
	return M.skipSet and M.skipSet[role] == true
end

return M
