-- Vimnav.spoon
--
-- Think of it like vimium, but available for system wide. Probably won't work on electron apps though, I don't use them.
--
-- This module is originated and credits to `dzirtuss` at `https://github.com/dzirtusss/vifari`
-- I had made lots of modifications to the original code including performance and supporting for system wide instead
-- of just within Safari. In my opinion, there are too many changes that made it hard to contribute back to the original
-- project, and Vifari is meant for only for Safari, not system wide.

---@diagnostic disable: undefined-global

local spoonPath = hs.spoons.scriptPath()
package.path = package.path
	.. ";"
	.. spoonPath
	.. "?.lua;"
	.. spoonPath
	.. "?/init.lua;"
	.. spoonPath
	.. "lib/?.lua"

local Log = require("lib.log")
local State = require("lib.state")
local Modes = require("lib.modes")
local Utils = require("lib.utils")
local Config = require("lib.config")
local Cache = require("lib.cache")
local Elements = require("lib.elements")
local Roles = require("lib.roles")
local Marks = require("lib.marks")
local Mappings = require("lib.mappings")
local MenuBar = require("lib.menubar")
local Overlay = require("lib.overlay")
local Cleanup = require("lib.cleanup")
local Whichkey = require("lib.whichkey")
local Timer = require("lib.timer")
local Actions = require("lib.actions")
local Commands = require("lib.commands")

---@class Hs.Vimnav
local M = {}

M.__index = M

M.name = "Vimnav"
M.license = "MIT - https://opensource.org/licenses/MIT"

local EventHandler = {}
local WatcherManager = {}

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

---@class Hs.Vimnav.EventHandler.HandleVimInputOpts
---@field modifiers? table

---Handles Vim input
---@param char string
---@param opts? Hs.Vimnav.EventHandler.HandleVimInputOpts
---@return nil
function EventHandler.handleVimInput(char, opts)
	opts = opts or {}
	local modifiers = opts.modifiers

	Log.log.df(
		"[EventHandler.handleVimInput] "
			.. char
			.. " modifiers: "
			.. hs.inspect(modifiers)
	)

	-- Clear element cache on every input
	Cache:clearElements()

	-- handle link capture first
	if Modes.isMode(Modes.MODES.LINKS) then
		State.state.linkCapture = State.state.linkCapture .. char:upper()
		for i, _ in ipairs(State.state.marks) do
			if i > #State.state.allCombinations then
				break
			end

			local markText = State.state.allCombinations[i]:upper()
			if markText == State.state.linkCapture then
				Marks.click(markText:lower())
				Modes.setModeNormal()
				Marks.clear()
				Cleanup.onCommandComplete()
				return
			end
		end
	end

	-- Check if this is the leader key being pressed
	local leaderKey = Config.config.leader.key
	if char == leaderKey and not State.state.leaderPressed then
		State.state.leaderPressed = true
		State.state.leaderCapture = ""
		State.state.keyCapture = "<leader>"

		Whichkey.scheduleShow(State.state.keyCapture)

		MenuBar.setTitle(State.state.mode, State.state.keyCapture)
		Overlay.update(State.state.mode, State.state.keyCapture)
		Log.log.df("[EventHandler.handleVimInput] Leader key pressed")
		return
	end

	-- Build key combination
	local keyCombo = ""

	-- make "space" into " "
	if char == "space" then
		char = " "
	end

	-- Handle leader key sequences (including multi-char)
	if State.state.leaderPressed then
		State.state.leaderCapture = State.state.leaderCapture .. char
		keyCombo = "<leader>" .. State.state.leaderCapture
	else
		if modifiers and modifiers.ctrl then
			keyCombo = "C-"
		end
		keyCombo = keyCombo .. char

		if State.state.keyCapture then
			State.state.keyCapture = State.state.keyCapture .. keyCombo
		end
	end

	if not State.state.keyCapture or State.state.leaderPressed then
		State.state.keyCapture = keyCombo
	end

	if State.state.keyCapture and #State.state.keyCapture > 0 then
		Whichkey.scheduleShow(State.state.keyCapture)
	end

	MenuBar.setTitle(State.state.mode, State.state.keyCapture)
	Overlay.update(State.state.mode, State.state.keyCapture)

	-- Execute mapping
	local mapping
	local prefixes

	if Modes.isMode(Modes.MODES.NORMAL) then
		mapping = Config.config.mapping.normal[State.state.keyCapture]
		prefixes = State.state.mappingPrefixes.normal
	end

	if Modes.isMode(Modes.MODES.INSERT_NORMAL) then
		mapping = Config.config.mapping.insertNormal[State.state.keyCapture]
		prefixes = State.state.mappingPrefixes.insertNormal
	end

	if Modes.isMode(Modes.MODES.INSERT_VISUAL) then
		mapping = Config.config.mapping.insertVisual[State.state.keyCapture]
		prefixes = State.state.mappingPrefixes.insertVisual
	end

	if Modes.isMode(Modes.MODES.VISUAL) then
		mapping = Config.config.mapping.visual[State.state.keyCapture]
		prefixes = State.state.mappingPrefixes.visual
	end

	if mapping and type(mapping) == "table" then
		local action = mapping.action
		-- Found a complete mapping, execute it
		if type(action) == "string" then
			if action == "noop" then
				Log.log.df("[EventHandler.handleVimInput] No mapping")
			else
				local cmd = Commands[action]
				if cmd then
					cmd()
				else
					Log.log.wf(
						"[EventHandler.handleVimInput] Unknown command: "
							.. mapping
					)
				end
			end
		elseif type(action) == "table" then
			Utils.keyStroke(action[1], action[2])
		elseif type(action) == "function" then
			action()
		end

		Cleanup.onCommandComplete()
	elseif prefixes and prefixes[State.state.keyCapture] then
		Log.log.df(
			"[EventHandler.handleVimInput] Found prefix: "
				.. State.state.keyCapture
		)
		-- Continue waiting for more keys
	else
		-- No mapping or prefix found, reset
		Cleanup.onCommandComplete()
	end
end

---Checks if the key is a valid key for the given name
---@param keyCode number
---@param name string
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.isKey(keyCode, name)
	return keyCode == hs.keycodes.map[name]
end

function EventHandler.isShiftEspace(event)
	local flags = event:getFlags()
	return flags.shift and EventHandler.isKey(event:getKeyCode(), "escape")
end

function EventHandler.isEspace(event)
	return EventHandler.isKey(event:getKeyCode(), "escape")
end

---Handles disabled mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleDisabledMode(event)
	return false
end

---Handles passthrough mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handlePassthroughMode(event)
	if EventHandler.isShiftEspace(event) then
		Modes.setModeNormal()
		Marks.clear()
		return true
	end

	return false
end

---Handles insert mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertMode(event)
	if EventHandler.isShiftEspace(event) then
		if Elements.isInBrowser() then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				Modes.setModeNormal()
				Marks.clear()
			end)
		end
		return true
	end

	if EventHandler.isEspace(event) then
		Modes.setModeInsertNormal()
		Marks.clear()
		return true
	end

	return false
end

---Handles insert normal mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertNormalMode(event)
	if EventHandler.isShiftEspace(event) then
		if Elements.isInBrowser() then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				Modes.setModeNormal()
				Marks.clear()
			end)
		end
		return true
	end

	if EventHandler.isEspace(event) then
		if State.state.leaderPressed then
			Cleanup.onEscape()
			return true
		end
	end

	return EventHandler.processVimInput(event)
end

---Handles insert visual mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertVisualMode(event)
	if EventHandler.isShiftEspace(event) then
		if Elements.isInBrowser() then
			Utils.keyStroke({}, "left")
			hs.timer.doAfter(0.1, function()
				Actions.forceUnfocus()
			end)
			hs.timer.doAfter(0.1, function()
				Modes.setModeNormal()
				Marks.clear()
			end)
		end
		return true
	end

	if EventHandler.isEspace(event) then
		if State.state.leaderPressed then
			Cleanup.onEscape()
			return true
		else
			Utils.keyStroke({}, "right")
			Modes.setModeInsertNormal()
			Marks.clear()
			return true
		end
	end

	return EventHandler.processVimInput(event)
end

---Handles links mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleLinkMode(event)
	if EventHandler.isEspace(event) then
		Modes.setModeNormal()
		Marks.clear()
		return true
	end

	return EventHandler.processVimInput(event)
end

---Handles normal mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleNormalMode(event)
	if EventHandler.isEspace(event) then
		Cleanup.onEscape()
		Actions.forceDeselectTextHighlights()
		return false
	end

	return EventHandler.processVimInput(event)
end

---Handles visual mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleVisualMode(event)
	if EventHandler.isEspace(event) then
		Actions.forceDeselectTextHighlights()
		Modes.setModeNormal()
		Marks.clear()
		Whichkey.hide()
		return false
	end

	return EventHandler.processVimInput(event)
end

---Handles vim input
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.processVimInput(event)
	local keyCode = event:getKeyCode()
	local flags = event:getFlags()

	for key, modifier in pairs(flags) do
		if modifier and key ~= "shift" and key ~= "ctrl" then
			return false
		end
	end

	local char = hs.keycodes.map[keyCode]

	-- Get the actual typed character (accounting for shift)
	local typedChar = flags.shift and event:getCharacters() or char

	-- Convert "space" keycode to actual space character
	if char == "space" then
		typedChar = " "
	end

	-- Basic validation - allow letters, numbers, common symbols, and space
	if not typedChar or typedChar == "" or #typedChar > 1 then
		return false
	end

	-- Check if this is the leader key being pressed
	local leaderKey = Config.config.leader.key or " "
	if typedChar == leaderKey and not State.state.leaderPressed then
		EventHandler.handleVimInput(leaderKey, {
			modifiers = flags,
		})
		return true
	end

	if flags.shift then
		char = event:getCharacters()
	end

	if flags.ctrl then
		local filteredMappings = {}

		local modeMapping

		if Modes.isMode(Modes.MODES.NORMAL) then
			modeMapping = Config.config.mapping.normal
		end

		if Modes.isMode(Modes.MODES.INSERT_NORMAL) then
			modeMapping = Config.config.mapping.insertNormal
		end

		if Modes.isMode(Modes.MODES.INSERT_VISUAL) then
			modeMapping = Config.config.mapping.insertVisual
		end

		if Modes.isMode(Modes.MODES.VISUAL) then
			modeMapping = Config.config.mapping.visual
		end

		if modeMapping then
			for _key, _ in pairs(modeMapping) do
				if _key:sub(1, 2) == "C-" then
					table.insert(filteredMappings, _key:sub(3))
				end
			end

			if Utils.tblContains(filteredMappings, char) == false then
				return false
			end
		end
	end

	EventHandler.handleVimInput(char, {
		modifiers = flags,
	})

	return true
end

---Handles events
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.process(event)
	-- Ignore synthetic events from Utils.keyStroke
	if
		event:getProperty(hs.eventtap.event.properties.eventSourceUserData)
		== eventSourceIgnoreSignature
	then
		Log.log.df(
			"[EventHandler.process] SYNTHETIC EVENT DETECTED – SKIPPING"
		)
		return false
	end

	if Modes.isMode(Modes.MODES.DISABLED) then
		return EventHandler.handleDisabledMode(event)
	end

	if Modes.isMode(Modes.MODES.PASSTHROUGH) then
		return EventHandler.handlePassthroughMode(event)
	end

	if Modes.isMode(Modes.MODES.INSERT) then
		return EventHandler.handleInsertMode(event)
	end

	if Modes.isMode(Modes.MODES.INSERT_NORMAL) then
		return EventHandler.handleInsertNormalMode(event)
	end

	if Modes.isMode(Modes.MODES.INSERT_VISUAL) then
		return EventHandler.handleInsertVisualMode(event)
	end

	if Modes.isMode(Modes.MODES.LINKS) then
		return EventHandler.handleLinkMode(event)
	end

	if Modes.isMode(Modes.MODES.NORMAL) then
		return EventHandler.handleNormalMode(event)
	end

	if Modes.isMode(Modes.MODES.VISUAL) then
		return EventHandler.handleVisualMode(event)
	end

	return false
end

function EventHandler.startEventLoop()
	if not State.state.eventLoop then
		State.state.eventLoop = hs.eventtap
			.new({ hs.eventtap.event.types.keyDown }, EventHandler.process)
			:start()
		Log.log.df("[EventHandler.startEventLoop] Started event loop")
	end
end

function EventHandler.stopEventLoop()
	if State.state.eventLoop then
		State.state.eventLoop:stop()
		State.state.eventLoop = nil
		Log.log.df("[EventHandler.stopEventLoop] Stopped event loop")
	end
end

--------------------------------------------------------------------------------
-- Watchers
--------------------------------------------------------------------------------

---Starts the app watcher
---@return nil
function WatcherManager.startAppWatcher()
	WatcherManager.stopAppWatcher()

	Timer.startFocusCheck()
	Elements.enableEnhancedUIForChrome()
	Elements.enableAccessibilityForElectron()

	State.state.appWatcher = hs.application.watcher.new(
		function(appName, eventType)
			Log.log.df(
				"[WatcherManager.startAppWatcher] App event: %s - %s",
				appName,
				eventType
			)

			if eventType == hs.application.watcher.activated then
				Log.log.df(
					"[WatcherManager.startAppWatcher] App activated: %s",
					appName
				)

				Cleanup.onAppSwitch()
				Timer.startFocusCheck()
				Elements.enableEnhancedUIForChrome()
				Elements.enableAccessibilityForElectron()
				EventHandler.startEventLoop()

				if
					Utils.tblContains(
						Config.config.applicationGroups.exclusions,
						appName
					)
				then
					Modes.setModeDisabled()
					Marks.clear()
					Log.log.df(
						"[WatcherManager.startAppWatcher] Disabled mode for excluded app: %s",
						appName
					)
				else
					Modes.setModeNormal()
					Marks.clear()
				end
			end
		end
	)

	State.state.appWatcher:start()

	Log.log.df("[WatcherManager.startAppWatcher] App watcher started")
end

function WatcherManager.stopAppWatcher()
	if State.state.appWatcher then
		State.state.appWatcher:stop()
		State.state.appWatcher = nil
		Log.log.df("[WatcherManager.stopAppWatcher] Stopped app watcher")
	end
end

function WatcherManager.startLaunchersWatcher()
	local launchers = Config.config.applicationGroups.launchers

	if not launchers or #launchers == 0 then
		return
	end

	for _, launcher in ipairs(launchers) do
		WatcherManager.stopLauncherWatcher(launcher)

		State.state.launcherWatcher[launcher] = hs.window.filter
			.new(false)
			:setAppFilter(launcher, { visible = true })

		State.state.launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowCreated,
			function()
				Log.log.df(
					"[WatcherManager.startLaunchersWatcher] Launcher opened: %s",
					launcher
				)
				Modes.setModeDisabled()
				Marks.clear()
			end
		)

		State.state.launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowDestroyed,
			function()
				Log.log.df(
					"[WatcherManager.startLaunchersWatcher] Launcher closed: %s",
					launcher
				)
				Modes.setModeNormal()
				Marks.clear()
			end
		)
	end
end

function WatcherManager.stopLauncherWatcher(launcher)
	if
		State.state.launcherWatcher and State.state.launcherWatcher[launcher]
	then
		State.state.launcherWatcher[launcher]:unsubscribeAll()
		State.state.launcherWatcher[launcher] = nil
		Log.log.df(
			"[WatcherManager.stopLauncherWatcher] Stopped launcher watcher: %s",
			launcher
		)
	end
end

function WatcherManager.stopLaunchersWatcher()
	if State.state.launcherWatcher then
		for _, launcher in pairs(State.state.launcherWatcher) do
			if launcher then
				launcher:unsubscribeAll()
				launcher = nil
			end
		end
		State.state.launcherWatcher = {}
		Log.log.df(
			"[WatcherManager.stopLaunchersWatcher] Stopped launcher watcher"
		)
	end
end

function WatcherManager.startScreenWatcher()
	WatcherManager.stopScreenWatcher()
	State.state.screenWatcher =
		hs.screen.watcher.new(Cleanup.onScreenChange):start()
	Log.log.df("[WatcherManager.startScreenWatcher] Screen watcher started")
end

function WatcherManager.stopScreenWatcher()
	if State.state.screenWatcher then
		State.state.screenWatcher:stop()
		State.state.screenWatcher = nil
		Log.log.df("[WatcherManager.stopScreenWatcher] Stopped screen watcher")
	end
end

local function handleCaffeineEvent(eventType)
	if eventType == hs.caffeinate.watcher.systemDidWake then
		Log.log.df("[handleCaffeineEvent] System woke from sleep")

		-- Give the system time to stabilize
		hs.timer.doAfter(1.0, function()
			-- Clean up everything
			Cleanup.onWake()

			-- Recreate overlay with correct screen position
			if Config.config.overlay.enabled then
				Overlay.destroy()
				hs.timer.doAfter(0.1, function()
					Overlay.create()
					Overlay.update(State.state.mode)
				end)
			end

			-- Recreate menubar in case it got corrupted
			if Config.config.menubar.enabled then
				MenuBar.destroy()
				MenuBar.create()
				MenuBar.setTitle(State.state.mode)
			end

			-- Restart focus polling
			Timer.startFocusCheck()

			-- Restart periodic cleanup timer
			Timer.startPeriodicCleanup()

			-- Re-enable enhanced accessibility if needed
			Elements.enableEnhancedUIForChrome()
			Elements.enableAccessibilityForElectron()

			-- Verify event loop is still running
			if not State.state.eventLoop or not state.eventLoop:isEnabled() then
				Log.log.wf(
					"[handleCaffeineEvent] Event loop not running, restarting..."
				)
				EventHandler.stopEventLoop()
				EventHandler.startEventLoop()
			end

			Log.log.df("[handleCaffeineEvent] Recovery complete after wake")
		end)
	elseif eventType == hs.caffeinate.watcher.systemWillSleep then
		Log.log.df("[handleCaffeineEvent] System going to sleep")

		Cleanup.onSleep()

		Log.log.df("[handleCaffeineEvent] Cleanup complete before sleep")
	end
end

function WatcherManager.startCaffeineWatcher()
	WatcherManager.stopCaffeineWatcher()
	State.state.caffeineWatcher =
		hs.caffeinate.watcher.new(handleCaffeineEvent):start()
	Log.log.df("[WatcherManager.startCaffeineWatcher] Caffeine watcher started")
end

function WatcherManager.stopCaffeineWatcher()
	if State.state.caffeineWatcher then
		State.state.caffeineWatcher:stop()
		State.state.caffeineWatcher = nil
		Log.log.df(
			"[WatcherManager.stopCaffeineWatcher] Stopped caffeine watcher"
		)
	end
end

---Clean up timers and watchers
---@return nil
function WatcherManager.stopAll()
	Timer.stopAll()
	WatcherManager.stopAppWatcher()
	WatcherManager.stopLaunchersWatcher()
	WatcherManager.stopScreenWatcher()
	WatcherManager.stopCaffeineWatcher()
end

--------------------------------------------------------------------------------
-- Timer Manager
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@type Hs.Vimnav.Config
---@diagnostic disable-next-line: missing-fields
Config.config = {}

-- Private state flag
M._running = false
M._initialized = false

---Initializes the module
---@return Hs.Vimnav
function M:init()
	if self._initialized then
		return self
	end

	-- Initialize logger with default level
	Log:new(M.name, "info")

	self._initialized = true
	Log.log.i("[M:init] Initialized")

	return self
end

---@class Hs.Vimnav.Config.SetOpts
---@field extend? boolean Whether to extend the config or replace it, true = extend, false = replace

---Configures the module
---@param userConfig Hs.Vimnav.Config
---@param opts? Hs.Vimnav.Config.SetOpts
---@return Hs.Vimnav
function M:configure(userConfig, opts)
	if not self._initialized then
		self:init()
	end

	Config:new(userConfig, opts)

	-- Reinitialize logger with configured level
	Log:new(M.name, Config.config.logLevel)

	Log.log.i("[M:configure] Configured")

	return self
end

---Starts the module
---@return Hs.Vimnav
function M:start()
	if self._running then
		Log.log.w("[M:start] Vimnav already running")
		return self
	end

	if not Config.config or not next(Config.config) then
		self:configure({})
	end

	Cache:new()
	State:new()

	Mappings.fetchMappingPrefixes()
	Mappings.generateCombinations()

	Roles:new() -- Initialize role maps for performance

	WatcherManager.stopAll()
	WatcherManager.startAppWatcher()
	WatcherManager.startLaunchersWatcher()
	WatcherManager.startScreenWatcher()
	WatcherManager.startCaffeineWatcher()
	Timer.startPeriodicCleanup()
	MenuBar.create()
	Overlay.create()

	local currentApp = Elements.getApp()
	if
		currentApp
		and Utils.tblContains(
			Config.config.applicationGroups.exclusions,
			currentApp:name()
		)
	then
		Modes.setModeDisabled()
		Marks.clear()
	else
		Modes.setModeNormal()
		Marks.clear()
	end

	self._running = true
	Log.log.i("[M:start] Started")

	return self
end

---Stops the module
---@return Hs.Vimnav
function M:stop()
	if not self._running then
		return self
	end

	Log.log.i("[M:stop] Stopping Vimnav")

	WatcherManager.stopAll()
	EventHandler.stopEventLoop()

	MenuBar.destroy()
	Overlay.destroy()
	Marks.clear()

	Cleanup.full()

	-- reset electron cache as well
	Cache:clearElectron()

	State:resetAll()

	self._running = false
	Log.log.i("[M:stop] Vimnav stopped")

	return self
end

---Restarts the module
---@return Hs.Vimnav
function M:restart()
	Log.log.i("[M:restart] Restarting Vimnav...")
	self:stop()
	self:start()
	return self
end

---Returns current running state
---@return boolean
function M:isRunning()
	return self._running
end

---Returns state and config information
---@return table
function M:debug()
	return {
		config = Config.config,
		state = State.state,
		caches = Cache.cache,
	}
end

---Returns default config
---@return table
function M:getDefaultConfig()
	return Utils.deepCopy(DEFAULT_CONFIG)
end

return M
