-- Vimnav.spoon
--
-- Think of it like vimium, but available for system wide. Probably won't work on electron apps though, I don't use them.
--
-- This module is originated and credits to `dzirtuss` at `https://github.com/dzirtusss/vifari`
-- I had made lots of modifications to the original code including performance and supporting for system wide instead
-- of just within Safari. In my opinion, there are too many changes that made it hard to contribute back to the original
-- project, and Vifari is meant for only for Safari, not system wide.

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- Spoon path initialization (required to make spoon works with `require` import)
--------------------------------------------------------------------------------

local spoonPath = hs.spoons.scriptPath()
package.path = package.path
	.. ";"
	.. spoonPath
	.. "?.lua;"
	.. spoonPath
	.. "?/init.lua;"
	.. spoonPath
	.. "lib/?.lua"

--------------------------------------------------------------------------------
-- Imports
--------------------------------------------------------------------------------

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
local Timer = require("lib.timer")
local EventHandler = require("lib.eventhandler")
local Watchers = require("lib.watchers")

--------------------------------------------------------------------------------
-- Module definition
--------------------------------------------------------------------------------

---@class Hs.Vimnav
local M = {}

M.__index = M

M.name = "Vimnav"
M.license = "MIT - https://opensource.org/licenses/MIT"

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
	Log.log.i("[init] Initialized")

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

	Log.log.i("[configure] Configured config")

	return self
end

---Starts the module
---@return Hs.Vimnav
function M:start()
	if self._running then
		Log.log.w("[start] Vimnav already running")
		return self
	end

	if not Config.config or not next(Config.config) then
		Log.log.w("[start] No config found, using defaults")
		self:configure({})
	end

	Cache:new()
	State:new()
	EventHandler:new()

	Mappings:fetchMappingPrefixes()
	Mappings:generateCombinations()

	Roles:new() -- Initialize role maps for performance

	Watchers:startAll()

	Timer:stopAll()
	Timer:startPeriodicCleanup()
	MenuBar:create()
	Overlay:create()

	local currentApp = Elements.getApp()
	if
		currentApp
		and Utils.tblContains(
			Config.config.applicationGroups.exclusions,
			currentApp:name()
		)
	then
		Modes.setModeDisabled()
		Marks:clear()
	else
		Modes.setModeNormal()
		Marks:clear()
	end

	self._running = true
	Log.log.i("[start] Started")

	return self
end

---Stops the module
---@return Hs.Vimnav
function M:stop()
	if not self._running then
		return self
	end

	Log.log.i("[stop] Stopping Vimnav")

	Timer:stopAll()
	Watchers:stopAll()
	EventHandler:stop()

	MenuBar:destroy()
	Overlay:destroy()
	Marks:clear()

	Cleanup.full()

	-- reset electron cache as well
	Cache:clearElectron()

	State:resetAll()

	self._running = false
	Log.log.i("[stop] Vimnav stopped")

	return self
end

---Restarts the module
---@return Hs.Vimnav
function M:restart()
	Log.log.i("[restart] Restarting Vimnav...")
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
