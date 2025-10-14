local Elements = require("lib.elements")
local State = require("lib.state")
local Cache = require("lib.cache")
local Modes = require("lib.modes")
local Roles = require("lib.roles")
local Marks = require("lib.marks")
local Log = require("lib.log")
local Config = require("lib.config")
local Cleanup = require("lib.cleanup")

local M = {}

---Updates focus state (called by timer)
---@return nil
local function updateFocusState()
	local focusedElement = Elements.getAxFocusedElement(true)

	-- Quick check: if same element, skip
	if focusedElement == State.state.focusLastElement then
		return
	end

	State.state.focusLastElement = focusedElement

	if focusedElement then
		local role = Cache:getAttribute(focusedElement, "AXRole")
		local isEditable = role and Roles:isEditable(role) or false

		if isEditable ~= State.state.focusCachedResult then
			State.state.focusCachedResult = isEditable

			-- Update mode based on focus change
			if isEditable and Modes.isMode(Modes.MODES.NORMAL) then
				Modes.setModeInsert()
				Marks.clear()
			elseif not isEditable then
				if
					Modes.isMode(Modes.MODES.INSERT)
					or Modes.isMode(Modes.MODES.INSERT_NORMAL)
					or Modes.isMode(Modes.MODES.INSERT_VISUAL)
				then
					Modes.setModeNormal()
					Marks.clear()
				end
			end

			Log.log.df(
				"[updateFocusState] Focus changed: editable=%s, role=%s",
				tostring(isEditable),
				tostring(role)
			)
		end
	else
		if State.state.focusCachedResult then
			State.state.focusCachedResult = false
			if
				Modes.isMode(Modes.MODES.INSERT)
				or Modes.isMode(Modes.MODES.INSERT_NORMAL)
				or Modes.isMode(Modes.MODES.INSERT_VISUAL)
			then
				Modes.setModeNormal()
				Marks.clear()
			end
		end
	end
end

---Starts focus polling
---@return nil
function M.startFocusCheck()
	M.stopFocusCheck()

	State.state.focusCheckTimer = hs.timer
		.new(Config.config.focus.checkInterval or 0.1, function()
			pcall(updateFocusState)
		end)
		:start()

	Log.log.df("[TimerManager.startFocusCheck] Focus polling started")
end

---Stop focus check timer
function M.stopFocusCheck()
	if State.state.focusCheckTimer then
		State.state.focusCheckTimer:stop()
		State.state.focusCheckTimer = nil
		Log.log.df("[TimerManager.stopFocusCheck] Stopped")
	end
end

---Start Periodic cache cleanup to prevent memory leaks
---@return nil
function M.startPeriodicCleanup()
	M.stopPeriodicCleanup()

	State.state.cleanupTimer = hs.timer
		.new(30, function() -- Every 30 seconds
			-- Only clean up if we're not actively showing marks
			if State.state.mode ~= Modes.MODES.LINKS then
				Cleanup.medium()
				Log.log.df(
					"[TimerManager.setupPeriodicCleanup] Periodic cache cleanup completed"
				)
			end
		end)
		:start()
end

---Stop cleanup timer
function M.stopPeriodicCleanup()
	if State.state.cleanupTimer then
		State.state.cleanupTimer:stop()
		State.state.cleanupTimer = nil
		Log.log.df("[TimerManager.stopCleanup] Stopped")
	end
end

---Stop which-key timer
function M.stopWhichkey()
	if State.state.whichkeyTimer then
		State.state.whichkeyTimer:stop()
		State.state.whichkeyTimer = nil
		Log.log.df("[TimerManager.stopWhichkey] Stopped")
	end
end

---Stop all timers
function M.stopAll()
	M.stopFocusCheck()
	M.stopPeriodicCleanup()
	M.stopWhichkey()
	Log.log.df("[TimerManager.stopAll] All timers stopped")
end

return M
