local M = {}

M.pool = {}
M.active = {}

---Reuse mark objects to avoid GC pressure
---@return table
function M.getMark()
	local mark = table.remove(M.pool)
	if not mark then
		mark = { element = nil, frame = nil, role = nil }
	end
	M.active[#M.active + 1] = mark
	return mark
end

---Release all marks
---@return nil
function M.releaseAll()
	for i = 1, #M.active do
		local mark = M.active[i]
		mark.element = nil
		mark.frame = nil
		mark.role = nil
		M.pool[#M.pool + 1] = mark
	end
	M.active = {}
end

return M
