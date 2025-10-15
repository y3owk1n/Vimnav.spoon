---@diagnostic disable: undefined-global

local Elements = require("lib.elements")
local Cache = require("lib.cache")
local Modes = require("lib.modes")
local Roles = require("lib.roles")
local Marks = require("lib.marks")
local Log = require("lib.log")
local Config = require("lib.config")
local Cleanup = require("lib.cleanup")

local M = {}

--------------------------------------------------------------------------------
-- Focus
--------------------------------------------------------------------------------

---@type boolean
M.focusCachedResult = false
---@type table|string|nil
M.focusLastElement = nil

M.focusCheckTimer = nil

---Updates focus state (called by timer)
---@return nil
function M:updateFocusState()
	local focusedElement = Elements.getAxFocusedElement(true, true)

	-- Quick check: if same element, skip
	if focusedElement == self.focusLastElement then
		return
	end

	self.focusLastElement = focusedElement

	if focusedElement then
		local role = Cache:getAttribute(focusedElement, "AXRole")
		local isEditable = role and Roles:isEditable(role) or false

		if isEditable ~= self.focusCachedResult then
			self.focusCachedResult = isEditable

			-- Update mode based on focus change
			if isEditable and Modes:isMode(Modes.MODES.NORMAL) then
				Modes:setModeInsert()
				Marks:clear()
			elseif not isEditable then
				if
					Modes:isMode(Modes.MODES.INSERT)
					or Modes:isMode(Modes.MODES.INSERT_NORMAL)
					or Modes:isMode(Modes.MODES.INSERT_VISUAL)
				then
					Modes:setModeNormal()
					Marks:clear()
				end
			end

			Log.log.df(
				"[updateFocusState] Focus changed: editable=%s, role=%s",
				tostring(isEditable),
				tostring(role)
			)
		end
	else
		if self.focusCachedResult then
			self.focusCachedResult = false
			if
				Modes:isMode(Modes.MODES.INSERT)
				or Modes:isMode(Modes.MODES.INSERT_NORMAL)
				or Modes:isMode(Modes.MODES.INSERT_VISUAL)
			then
				Modes:setModeNormal()
				Marks:clear()
			end
		end
	end
end

---Reset focus state
---@return nil
function M:resetFocus()
	Log.log.df("[Timer:resetFocus] Resetting focus")
	self.focusCachedResult = false
	self.focusLastElement = nil
end

---Starts focus polling
---@return nil
function M:startFocusCheck()
	Log.log.df("[Timer.startFocusCheck] Starting focus polling")

	M:stopFocusCheck()

	self.focusCheckTimer = hs.timer
		.new(Config.config.focus.checkInterval or 0.1, function()
			pcall(function()
				self:updateFocusState()
			end)
		end)
		:start()
end

---Stop focus check timer
function M:stopFocusCheck()
	Log.log.df("[Timer.stopFocusCheck] Stopping focus polling")
	if self.focusCheckTimer then
		self.focusCheckTimer:stop()
		self.focusCheckTimer = nil
	end
end

--------------------------------------------------------------------------------
-- Periodic Cleanup
--------------------------------------------------------------------------------

M.periodicCleanupTimer = nil

---Start Periodic cache cleanup to prevent memory leaks
---@return nil
function M:startPeriodicCleanup()
	Log.log.df("[Timer.startPeriodicCleanup] Starting periodic cache cleanup")

	M:stopPeriodicCleanup()

	self.periodicCleanupTimer = hs.timer
		.new(30, function() -- Every 30 seconds
			-- Only clean up if we're not actively showing marks
			if Modes.mode ~= Modes.MODES.LINKS then
				Cleanup.medium()
				Log.log.df(
					"[Timer.setupPeriodicCleanup] Periodic cache cleanup completed"
				)
			end
		end)
		:start()
end

---Stop cleanup timer
---@return nil
function M:stopPeriodicCleanup()
	Log.log.df("[Timer.stopCleanup] Stopped")
	if self.periodicCleanupTimer then
		self.periodicCleanupTimer:stop()
		self.periodicCleanupTimer = nil
	end
end

---Stop all timers
---@return nil
function M:stopAll()
	Log.log.df("[TimerManager.stopAll] Stopping all timers")

	M:stopFocusCheck()
	M:stopPeriodicCleanup()
end

return M
