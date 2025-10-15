---@diagnostic disable: undefined-global

local Timer = require("lib.timer")
local Elements = require("lib.elements")
local Modes = require("lib.modes")
local Marks = require("lib.marks")
local Log = require("lib.log")
local Config = require("lib.config")
local Cleanup = require("lib.cleanup")
local EventHandler = require("lib.eventhandler")
local Utils = require("lib.utils")
local Overlay = require("lib.overlay")
local MenuBar = require("lib.menubar")

local M = {}

--------------------------------------------------------------------------------
-- App Watcher
--------------------------------------------------------------------------------

M.appWatcher = nil

---Starts the app watcher
---@return nil
function M:startAppWatcher()
	Log.log.df("[Watchers.startAppWatcher] Starting app watcher")

	self:stopAppWatcher()

	Timer:startFocusCheck()
	Elements.enableEnhancedUIForChrome()
	Elements.enableAccessibilityForElectron()

	self.appWatcher = hs.application.watcher.new(function(appName, eventType)
		Log.log.df(
			"[Watchers.startAppWatcher] App event: %s - %s",
			appName,
			eventType
		)

		if eventType == hs.application.watcher.activated then
			Log.log.df("[Watchers.startAppWatcher] App activated: %s", appName)

			Cleanup.onAppSwitch()
			Timer:startFocusCheck()
			Elements.enableEnhancedUIForChrome()
			Elements.enableAccessibilityForElectron()
			EventHandler:start()

			if
				Utils.tblContains(
					Config.config.applicationGroups.exclusions,
					appName
				)
			then
				Modes:setModeDisabled()
				Marks:clear()
				Log.log.df(
					"[Watchers.startAppWatcher] Disabled mode for excluded app: %s",
					appName
				)
			else
				Modes:setModeNormal()
				Marks:clear()
				Log.log.df(
					"[Watchers.startAppWatcher] Enabled mode for app: %s",
					appName
				)
			end
		end
	end)

	self.appWatcher:start()
end

---Stops the app watcher
---@return nil
function M:stopAppWatcher()
	Log.log.df("[Watchers.stopAppWatcher] Stopped app watcher")

	if self.appWatcher then
		self.appWatcher:stop()
		self.appWatcher = nil
	end
end

--------------------------------------------------------------------------------
-- Launcher Watcher
--------------------------------------------------------------------------------

M.launcherWatcher = {}

---Starts the launcher watcher
---@return nil
function M:startLaunchersWatcher()
	Log.log.df("[Watchers.startLaunchersWatcher] Starting launcher watcher")

	local launchers = Config.config.applicationGroups.launchers

	if not launchers or #launchers == 0 then
		Log.log.df("[Watchers.startLaunchersWatcher] No launchers found")
		return
	end

	for _, launcher in ipairs(launchers) do
		Log.log.df(
			"[Watchers.startLaunchersWatcher] Starting watcher for %s",
			launcher
		)

		self:stopLauncherWatcher(launcher)

		self.launcherWatcher[launcher] = hs.window.filter
			.new(false)
			:setAppFilter(launcher, { visible = true })

		self.launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowCreated,
			function()
				Log.log.df(
					"[Watchers.startLaunchersWatcher] Launcher opened: %s",
					launcher
				)
				Modes:setModeDisabled()
				Marks:clear()
			end
		)

		self.launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowDestroyed,
			function()
				Log.log.df(
					"[Watchers.startLaunchersWatcher] Launcher closed: %s",
					launcher
				)
				Modes:setModeNormal()
				Marks:clear()
			end
		)
	end
end

---Stops one launcher watcher
---@param launcher string Launcher to stop
---@return nil
function M:stopLauncherWatcher(launcher)
	Log.log.df(
		"[Watchers.stopLauncherWatcher] Stopping launcher watcher: %s",
		launcher
	)

	if self.launcherWatcher and self.launcherWatcher[launcher] then
		Log.log.df(
			"[Watchers.stopLauncherWatcher] Stopping watcher for %s",
			launcher
		)
		self.launcherWatcher[launcher]:unsubscribeAll()
		self.launcherWatcher[launcher] = nil
		Log.log.df(
			"[M.stopLauncherWatcher] Stopped launcher watcher: %s",
			launcher
		)
	end
end

---Stops all launcher watcher
---@return nil
function M:stopLaunchersWatcher()
	Log.log.df("[Watchers.stopLaunchersWatcher] Stopping all launcher watchers")

	if self.launcherWatcher then
		for _, launcher in pairs(self.launcherWatcher) do
			if launcher then
				launcher:unsubscribeAll()
				launcher = nil
			end
		end
		self.launcherWatcher = {}
	end
end

--------------------------------------------------------------------------------
-- Screen Watcher
--------------------------------------------------------------------------------

M.screenWatcher = nil

---Starts the screen watcher
---@return nil
function M:startScreenWatcher()
	Log.log.df("[Watchers.startScreenWatcher] Starting screen watcher")

	self:stopScreenWatcher()
	self.screenWatcher = hs.screen.watcher.new(Cleanup.onScreenChange):start()
end

---Stops the screen watcher
---@return nil
function M:stopScreenWatcher()
	Log.log.df("[Watchers.stopScreenWatcher] Stopping screen watcher")

	if self.screenWatcher then
		self.screenWatcher:stop()
		self.screenWatcher = nil
	end
end

--------------------------------------------------------------------------------
-- Caffeine Watcher
--------------------------------------------------------------------------------

---Handles caffeine events
---@param eventType number Event type
---@return nil
local function handleCaffeineEvent(eventType)
	Log.log.df(
		"[Watchers.handleCaffeineEvent] Handling caffeine event: %s",
		eventType
	)

	if eventType == hs.caffeinate.watcher.systemDidWake then
		Log.log.df("[Watchers.handleCaffeineEvent] System woke from sleep")

		-- Give the system time to stabilize
		hs.timer.doAfter(1.0, function()
			-- Clean up everything
			Cleanup.onWake()

			-- Recreate overlay with correct screen position
			if Config.config.overlay.enabled then
				Overlay:destroy()
				hs.timer.doAfter(0.1, function()
					Overlay:create()
					Overlay:update(Modes.mode)
				end)
			end

			-- Recreate menubar in case it got corrupted
			if Config.config.menubar.enabled then
				MenuBar:destroy()
				MenuBar:create()
				MenuBar:setTitle(Modes.mode)
			end

			-- Restart focus polling
			Timer:startFocusCheck()

			-- Restart periodic cleanup timer
			Timer:startPeriodicCleanup()

			-- Re-enable enhanced accessibility if needed
			Elements.enableEnhancedUIForChrome()
			Elements.enableAccessibilityForElectron()

			EventHandler:start()

			Log.log.df(
				"[Watchers.handleCaffeineEvent] Recovery complete after wake"
			)
		end)
	elseif eventType == hs.caffeinate.watcher.systemWillSleep then
		Log.log.df("[Watchers.handleCaffeineEvent] System going to sleep")

		Cleanup.onSleep()

		Log.log.df(
			"[Watchers.handleCaffeineEvent] Cleanup complete before sleep"
		)
	end
end

M.caffeineWatcher = nil

---Starts the caffeine watcher
---@return nil
function M:startCaffeineWatcher()
	Log.log.df("[Watchers.startCaffeineWatcher] Starting caffeine watcher")

	self:stopCaffeineWatcher()
	self.caffeineWatcher =
		hs.caffeinate.watcher.new(handleCaffeineEvent):start()
end

---Stops the caffeine watcher
---@return nil
function M:stopCaffeineWatcher()
	Log.log.df("[Watchers.stopCaffeineWatcher] Stopping caffeine watcher")

	if self.caffeineWatcher then
		self.caffeineWatcher:stop()
		self.caffeineWatcher = nil
	end
end

--------------------------------------------------------------------------------
-- Rest
--------------------------------------------------------------------------------

---Start all watchers
---@return nil
function M:startAll()
	Log.log.df("[Watchers.startAll] Starting all watchers")

	self:startAppWatcher()
	self:startLaunchersWatcher()
	self:startScreenWatcher()
	self:startCaffeineWatcher()
end

---Stop all watchers
---@return nil
function M:stopAll()
	Log.log.df("[Watchers.stopAll] Stopping all watchers")

	self:stopAppWatcher()
	self:stopLaunchersWatcher()
	self:stopScreenWatcher()
	self:stopCaffeineWatcher()
end

return M
