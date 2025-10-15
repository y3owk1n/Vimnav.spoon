local Timer = require("lib.timer")
local Elements = require("lib.elements")
local Modes = require("lib.modes")
local Marks = require("lib.marks")
local Log = require("lib.log")
local State = require("lib.state")
local Config = require("lib.config")
local Cleanup = require("lib.cleanup")
local EventHandler = require("lib.eventhandler")
local Utils = require("lib.utils")
local Overlay = require("lib.overlay")
local MenuBar = require("lib.menubar")

local M = {}

---Starts the app watcher
---@return nil
function M.startAppWatcher()
	M.stopAppWatcher()

	Timer.startFocusCheck()
	Elements.enableEnhancedUIForChrome()
	Elements.enableAccessibilityForElectron()

	State.state.appWatcher = hs.application.watcher.new(
		function(appName, eventType)
			Log.log.df(
				"[M.startAppWatcher] App event: %s - %s",
				appName,
				eventType
			)

			if eventType == hs.application.watcher.activated then
				Log.log.df("[M.startAppWatcher] App activated: %s", appName)

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
						"[M.startAppWatcher] Disabled mode for excluded app: %s",
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

	Log.log.df("[M.startAppWatcher] App watcher started")
end

function M.stopAppWatcher()
	if State.state.appWatcher then
		State.state.appWatcher:stop()
		State.state.appWatcher = nil
		Log.log.df("[M.stopAppWatcher] Stopped app watcher")
	end
end

function M.startLaunchersWatcher()
	local launchers = Config.config.applicationGroups.launchers

	if not launchers or #launchers == 0 then
		return
	end

	for _, launcher in ipairs(launchers) do
		M.stopLauncherWatcher(launcher)

		State.state.launcherWatcher[launcher] = hs.window.filter
			.new(false)
			:setAppFilter(launcher, { visible = true })

		State.state.launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowCreated,
			function()
				Log.log.df(
					"[M.startLaunchersWatcher] Launcher opened: %s",
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
					"[M.startLaunchersWatcher] Launcher closed: %s",
					launcher
				)
				Modes.setModeNormal()
				Marks.clear()
			end
		)
	end
end

function M.stopLauncherWatcher(launcher)
	if
		State.state.launcherWatcher and State.state.launcherWatcher[launcher]
	then
		State.state.launcherWatcher[launcher]:unsubscribeAll()
		State.state.launcherWatcher[launcher] = nil
		Log.log.df(
			"[M.stopLauncherWatcher] Stopped launcher watcher: %s",
			launcher
		)
	end
end

function M.stopLaunchersWatcher()
	if State.state.launcherWatcher then
		for _, launcher in pairs(State.state.launcherWatcher) do
			if launcher then
				launcher:unsubscribeAll()
				launcher = nil
			end
		end
		State.state.launcherWatcher = {}
		Log.log.df("[M.stopLaunchersWatcher] Stopped launcher watcher")
	end
end

function M.startScreenWatcher()
	M.stopScreenWatcher()
	State.state.screenWatcher =
		hs.screen.watcher.new(Cleanup.onScreenChange):start()
	Log.log.df("[M.startScreenWatcher] Screen watcher started")
end

function M.stopScreenWatcher()
	if State.state.screenWatcher then
		State.state.screenWatcher:stop()
		State.state.screenWatcher = nil
		Log.log.df("[M.stopScreenWatcher] Stopped screen watcher")
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
			if
				not State.state.eventLoop
				or not State.state.eventLoop:isEnabled()
			then
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

function M.startCaffeineWatcher()
	M.stopCaffeineWatcher()
	State.state.caffeineWatcher =
		hs.caffeinate.watcher.new(handleCaffeineEvent):start()
	Log.log.df("[M.startCaffeineWatcher] Caffeine watcher started")
end

function M.stopCaffeineWatcher()
	if State.state.caffeineWatcher then
		State.state.caffeineWatcher:stop()
		State.state.caffeineWatcher = nil
		Log.log.df("[M.stopCaffeineWatcher] Stopped caffeine watcher")
	end
end

---Clean up timers and watchers
---@return nil
function M.stopAll()
	Timer.stopAll()
	M.stopAppWatcher()
	M.stopLaunchersWatcher()
	M.stopScreenWatcher()
	M.stopCaffeineWatcher()
end

return M
