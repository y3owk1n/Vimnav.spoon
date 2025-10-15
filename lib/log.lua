---@diagnostic disable: undefined-global

local M = {}

M.log = nil

function M:new(name, logLevel)
	self.log = hs.logger.new(name, logLevel)
end

return M
