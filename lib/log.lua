---@diagnostic disable: undefined-global

local M = {}

M.log = nil

---Creates a new logger
---@param name string Name of the logger
---@param logLevel string Log level
function M:new(name, logLevel)
	self.log = hs.logger.new(name, logLevel)
end

return M
