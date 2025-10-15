---@diagnostic disable: undefined-global

local State = require("lib.state")
local Log = require("lib.log")
local Cache = require("lib.cache")
local Config = require("lib.config")

local M = {}

---Light cleanup - resets input states
---@return nil
function M.light()
	Log.log.df("[CleanupManager.light] Performing light cleanup")
	State:resetInput()
end

---Medium cleanup - clears UI elements and focus state
---@return nil
function M.medium()
	Log.log.df("[CleanupManager.medium] Performing medium cleanup")

	-- First do light cleanup
	M.light()

	-- Clear UI elements
	require("lib.marks"):clear()
	require("lib.whichkey"):hide()

	-- Reset focus state
	State:resetFocus()
end

---Heavy cleanup - clears caches and forces GC
---@return nil
function M.heavy()
	Log.log.df("[CleanupManager.heavy] Performing heavy cleanup")

	-- First do medium cleanup
	M.medium()

	-- Clear all caches
	Cache:clearAll()
	Cache:collectGarbage()
end

---Full cleanup - stops timers and performs complete reset
---@return nil
function M.full()
	Log.log.df("[CleanupManager.full] Performing full cleanup")

	-- First do heavy cleanup
	M.heavy()

	-- Stop all timers
	require("lib.timer"):stopAll()
end

---Cleanup for app switching - medium + element cache
---@return nil
function M.onAppSwitch()
	Log.log.df("[CleanupManager.onAppSwitch] App switch cleanup")
	M.heavy()
end

---Cleanup before sleep - full cleanup with UI hiding
---@return nil
function M.onSleep()
	Log.log.df("[CleanupManager.onSleep] Sleep cleanup")
	M.full()
end

---Cleanup on wake - just heavy, no timer stop
function M.onWake()
	Log.log.df("[CleanupManager.onWake] Wake cleanup")
	M.heavy()
end

---Cleanup on mode change - light cleanup only
---@param fromMode number Mode to leave
---@param toMode number Mode to enter
---@return nil
function M.onModeChange(fromMode, toMode)
	Log.log.df(
		"[CleanupManager.onModeChange] Mode change: %s -> %s",
		fromMode,
		toMode
	)

	-- Always do light cleanup on mode change
	M.light()

	local MODES = require("lib.modes").MODES

	-- Clear marks when leaving LINKS mode
	if fromMode == MODES.LINKS then
		require("lib.marks"):clear()
	end

	-- Clear marks when entering certain modes
	if toMode == MODES.NORMAL or toMode == MODES.PASSTHROUGH then
		require("lib.marks"):clear()
	end
end

---Cleanup when command execution completes
---@return nil
function M.onCommandComplete()
	Log.log.df("[CleanupManager.onCommandComplete] Command complete cleanup")

	State:resetLeader()
	State:resetKeyCapture()

	if State.state.showingHelp then
		State:resetHelp()
	else
		require("lib.whichkey"):hide()
	end
end

---Cleanup when escape is pressed
---@return nil
function M.onEscape()
	Log.log.df("[CleanupManager.onEscape] Escape cleanup")

	M.light()
	require("lib.whichkey"):hide()
	require("lib.menubar"):setTitle(State.state.mode)
	require("lib.overlay"):update(State.state.mode)
end

---Cleanup on screen change
function M.onScreenChange()
	Log.log.df("[CleanupManager.onScreenChange] Screen changed")

	-- Only clear element cache (positions changed)
	Cache:clearElements()

	local Overlay = require("lib.overlay")

	if
		Config.config.overlay.enabled
		and State.state.mode ~= require("lib.modes").MODES.DISABLED
	then
		Overlay:destroy()
		hs.timer.doAfter(0.1, function()
			Overlay:create()
			Overlay:update(State.mode)
		end)
	end

	-- Redraw marks if showing
	local Marks = require("lib.marks")
	if Marks.canvas and #Marks.marks > 0 then
		hs.timer.doAfter(0.2, Marks.draw)
	end
end

return M
