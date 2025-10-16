---@diagnostic disable: undefined-global

local Log = require("lib.log")
local Cache = require("lib.cache")
local Modes = require("lib.modes")
local Config = require("lib.config")
local Commands = require("lib.commands")
local Utils = require("lib.utils")
local Marks = require("lib.marks")
local Cleanup = require("lib.cleanup")
local Actions = require("lib.actions")
local Elements = require("lib.elements")
local Whichkey = require("lib.whichkey")
local Mappings = require("lib.mappings")

local M = {}

---@type string|nil
M.keyCapture = nil

---@type string
M.linkCapture = ""

---@type string
M.leaderCapture = ""

---@type boolean
M.leaderPressed = false

---Reset key capture state
---@return nil
function M:resetKeyCapture()
	Log.log.df("[EventHandler:resetKeyCapture] Resetting key capture")
	self.keyCapture = nil
end

---Reset link capture state
---@return nil
function M:resetLinkCapture()
	Log.log.df("[EventHandler:resetLinkCapture] Resetting link capture")
	self.linkCapture = ""
end

---Reset leader state
---@return nil
function M:resetLeader()
	Log.log.df("[EventHandler:resetLeader] Resetting leader")
	self.leaderPressed = false
	self.leaderCapture = ""
end

---Reset all input-related state (key, leader, link capture)
---@return nil
function M:resetAllCaptures()
	Log.log.df("[EventHandler:resetInput] Resetting input state")
	self:resetKeyCapture()
	self:resetLinkCapture()
	self:resetLeader()
end

---Handles Vim input
---@param char string Character to handle
---@param opts? Hs.Vimnav.EventHandler.HandleVimInputOpts Opts for handling Vim input
---@return nil
function M:handleVimInput(char, opts)
	opts = opts or {}
	local modifiers = opts.modifiers

	-- Clear element cache on every input
	Cache:clearElements()

	-- handle link capture first
	if Modes:isMode(Modes.MODES.LINKS) then
		Log.log.df("[EventHandler.handleVimInput] Links mode")

		self.linkCapture = self.linkCapture .. char:upper()
		for i, _ in ipairs(require("lib.marks").marks) do
			if i > #Mappings.allCombinations then
				break
			end

			local markText = Mappings.allCombinations[i]:upper()
			if markText == self.linkCapture then
				Log.log.df(
					"[EventHandler.handleVimInput] Clicking mark: %s",
					markText
				)

				require("lib.marks"):click(markText:lower())
				Modes:setModeNormal()
				require("lib.marks"):clear()
				require("lib.cleanup").onCommandComplete()
				return
			end
		end
	end

	-- Check if this is the leader key being pressed
	local leaderKey = Config.config.leader.key
	if char == leaderKey and not self.leaderPressed then
		Log.log.df("[EventHandler.handleVimInput] Leader key pressed")

		self.leaderPressed = true
		self.leaderCapture = ""
		self.keyCapture = "<leader>"

		Whichkey:scheduleShow(self.keyCapture)

		require("lib.menubar"):setTitle(Modes.mode, self.keyCapture)
		require("lib.overlay"):update(Modes.mode, self.keyCapture)
		return
	end

	-- Build key combination
	local keyCombo = ""

	-- make "space" into " "
	if char == "space" then
		char = " "
	end

	-- Handle leader key sequences (including multi-char)
	if self.leaderPressed then
		self.leaderCapture = self.leaderCapture .. char
		keyCombo = "<leader>" .. self.leaderCapture
	else
		if modifiers and modifiers.ctrl then
			keyCombo = "C-"
		end
		keyCombo = keyCombo .. char

		if self.keyCapture then
			self.keyCapture = self.keyCapture .. keyCombo
		end
	end

	if not self.keyCapture or self.leaderPressed then
		self.keyCapture = keyCombo
	end

	if self.keyCapture and #self.keyCapture > 0 then
		Whichkey:scheduleShow(self.keyCapture)
	end

	require("lib.menubar"):setTitle(Modes.mode, self.keyCapture)
	require("lib.overlay"):update(Modes.mode, self.keyCapture)

	-- Execute mapping
	local mapping
	local prefixes

	if Modes:isMode(Modes.MODES.NORMAL) then
		mapping = Config.config.mapping.normal[self.keyCapture]
		prefixes = Mappings.mappingPrefixes.normal
	end

	if Modes:isMode(Modes.MODES.INSERT_NORMAL) then
		mapping = Config.config.mapping.insertNormal[self.keyCapture]
		prefixes = Mappings.mappingPrefixes.insertNormal
	end

	if Modes:isMode(Modes.MODES.INSERT_VISUAL) then
		mapping = Config.config.mapping.insertVisual[self.keyCapture]
		prefixes = Mappings.mappingPrefixes.insertVisual
	end

	if Modes:isMode(Modes.MODES.VISUAL) then
		mapping = Config.config.mapping.visual[self.keyCapture]
		prefixes = Mappings.mappingPrefixes.visual
	end

	if mapping and type(mapping) == "table" then
		local action = mapping.action
		-- Found a complete mapping, execute it
		if type(action) == "string" then
			if action == "noop" then
				Log.log.df("[EventHandler.handleVimInput] No mapping")
			else
				local cmd = Utils.getCmd(action, Commands)
				if cmd then
					cmd()
					Log.log.df("[EventHandler.handleVimInput] Executed command")
				else
					Log.log.wf(
						"[EventHandler.handleVimInput] Unknown command: "
							.. mapping
					)
				end
			end
		elseif type(action) == "table" then
			Utils.keyStroke(action[1], action[2])
			Log.log.df("[EventHandler.handleVimInput] Executed keyStroke")
		elseif type(action) == "function" then
			action()
			Log.log.df("[EventHandler.handleVimInput] Executed function")
		end

		require("lib.cleanup").onCommandComplete()
	elseif prefixes and prefixes[self.keyCapture] then
		Log.log.df(
			"[EventHandler.handleVimInput] Found prefix: " .. self.keyCapture
		)
		-- Continue waiting for more keys
	else
		-- No mapping or prefix found, reset
		Log.log.df("[EventHandler.handleVimInput] No mapping or prefix found")
		require("lib.cleanup").onCommandComplete()
	end
end

---Checks if the key is a valid key for the given name
---@param keyCode number Key code to check
---@param name string Name of the key
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:isKey(keyCode, name)
	local isKey = keyCode == hs.keycodes.map[name]

	Log.log.df(
		"[EventHandler.isKey] isKey=%s, keyCode=%d, name=%s",
		tostring(isKey),
		keyCode,
		name
	)

	return isKey
end

---Checks if the event is a shift-escape
---@param event table Event to check
---@return boolean isShiftEspace True if the event is a shift-escape, false otherwise
function M:isShiftEspace(event)
	local flags = event:getFlags()
	local isShiftEspace = flags.shift and M:isKey(event:getKeyCode(), "escape")

	Log.log.df(
		"[EventHandler.isShiftEspace] isShiftEspace=%s",
		tostring(isShiftEspace)
	)

	return isShiftEspace
end

---Checks if the event is an escape
---@param event table Event to check
---@return boolean isEspace True if the event is an escape, false otherwise
function M:isEspace(event)
	local isEspace = M:isKey(event:getKeyCode(), "escape")

	Log.log.df("[EventHandler.isEspace] isEspace=%s", tostring(isEspace))

	return isEspace
end

---Handles disabled mode
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:handleDisabledMode(event)
	Log.log.df("[EventHandler.handleDisabledMode] Handling disabled mode")

	return false
end

---Handles passthrough mode
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:handlePassthroughMode(event)
	Log.log.df("[EventHandler.handlePassthroughMode] Handling passthrough mode")

	if M:isShiftEspace(event) then
		Modes:setModeNormal()
		Marks:clear()
		return true
	end

	return false
end

---Handles insert mode
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:handleInsertMode(event)
	Log.log.df("[EventHandler.handleInsertMode] Handling insert mode")

	if M:isShiftEspace(event) then
		if Elements.isInBrowser() then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				Modes:setModeNormal()
				Marks:clear()
			end)
		end
		return true
	end

	if M:isEspace(event) then
		Modes:setModeInsertNormal()
		Marks:clear()
		return true
	end

	return false
end

---Handles insert normal mode
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:handleInsertNormalMode(event)
	Log.log.df(
		"[EventHandler.handleInsertNormalMode] Handling insert normal mode"
	)

	if M:isShiftEspace(event) then
		if Elements.isInBrowser() then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				Modes:setModeNormal()
				Marks:clear()
			end)
		end
		return true
	end

	if M:isEspace(event) then
		if self.leaderPressed then
			Cleanup.onEscape()
			return true
		end
	end

	return self:processVimInput(event)
end

---Handles insert visual mode
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:handleInsertVisualMode(event)
	Log.log.df(
		"[EventHandler.handleInsertVisualMode] Handling insert visual mode"
	)

	if M:isShiftEspace(event) then
		if Elements.isInBrowser() then
			Utils.keyStroke({}, "left")
			hs.timer.doAfter(0.1, function()
				Actions.forceUnfocus()
			end)
			hs.timer.doAfter(0.1, function()
				Modes:setModeNormal()
				Marks:clear()
			end)
		end
		return true
	end

	if M:isEspace(event) then
		if self.leaderPressed then
			Cleanup.onEscape()
			return true
		else
			Utils.keyStroke({}, "right")
			Modes:setModeInsertNormal()
			Marks:clear()
			return true
		end
	end

	return self:processVimInput(event)
end

---Handles links mode
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:handleLinkMode(event)
	Log.log.df("[EventHandler.handleLinkMode] Handling link mode")

	if M:isEspace(event) then
		Modes:setModeNormal()
		Marks:clear()
		return true
	end

	return self:processVimInput(event)
end

---Handles normal mode
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:handleNormalMode(event)
	Log.log.df("[EventHandler.handleNormalMode] Handling normal mode")

	if M:isEspace(event) then
		Cleanup.onEscape()
		Actions.forceDeselectTextHighlights()
		return false
	end

	return self:processVimInput(event)
end

---Handles visual mode
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:handleVisualMode(event)
	Log.log.df("[EventHandler.handleVisualMode] Handling visual mode")

	if M:isEspace(event) then
		Actions.forceDeselectTextHighlights()
		Modes:setModeNormal()
		Marks:clear()
		Whichkey:hide()
		return false
	end

	return self:processVimInput(event)
end

---Handles vim input
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:processVimInput(event)
	Log.log.df("[EventHandler.processVimInput] Processing Vim input")

	local keyCode = event:getKeyCode()
	local flags = event:getFlags()

	for key, modifier in pairs(flags) do
		if modifier and key ~= "shift" and key ~= "ctrl" then
			Log.log.df(
				"[EventHandler.processVimInput] Found modifiers, not shift or ctrl"
			)
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
		Log.log.df(
			"[EventHandler.processVimInput] Basic validation failed, aborting..."
		)

		return false
	end

	-- Check if this is the leader key being pressed
	local leaderKey = Config.config.leader.key or " "
	if typedChar == leaderKey and not self.leaderPressed then
		Log.log.df(
			"[EventHandler.processVimInput] Leader key detected, handling..."
		)

		self:handleVimInput(leaderKey, {
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

		if Modes:isMode(Modes.MODES.NORMAL) then
			modeMapping = Config.config.mapping.normal
		end

		if Modes:isMode(Modes.MODES.INSERT_NORMAL) then
			modeMapping = Config.config.mapping.insertNormal
		end

		if Modes:isMode(Modes.MODES.INSERT_VISUAL) then
			modeMapping = Config.config.mapping.insertVisual
		end

		if Modes:isMode(Modes.MODES.VISUAL) then
			modeMapping = Config.config.mapping.visual
		end

		if modeMapping then
			for _key, _ in pairs(modeMapping) do
				if _key:sub(1, 2) == "C-" then
					table.insert(filteredMappings, _key:sub(3))
				end
			end

			if Utils.tblContains(filteredMappings, char) == false then
				Log.log.df(
					"[EventHandler.processVimInput] No mapping found, aborting..."
				)
				return false
			end
		end
	end

	self:handleVimInput(char, {
		modifiers = flags,
	})

	return true
end

---Handles events
---@param event table Event to handle
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M:process(event)
	Log.log.df("[EventHandler.process] Processing event")

	local eventSourceIgnoreSignature = Utils.eventSourceIgnoreSignature
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

	if Modes:isMode(Modes.MODES.DISABLED) then
		return self:handleDisabledMode(event)
	end

	if Modes:isMode(Modes.MODES.PASSTHROUGH) then
		return self:handlePassthroughMode(event)
	end

	if Modes:isMode(Modes.MODES.INSERT) then
		return self:handleInsertMode(event)
	end

	if Modes:isMode(Modes.MODES.INSERT_NORMAL) then
		return self:handleInsertNormalMode(event)
	end

	if Modes:isMode(Modes.MODES.INSERT_VISUAL) then
		return self:handleInsertVisualMode(event)
	end

	if Modes:isMode(Modes.MODES.LINKS) then
		return self:handleLinkMode(event)
	end

	if Modes:isMode(Modes.MODES.NORMAL) then
		return self:handleNormalMode(event)
	end

	if Modes:isMode(Modes.MODES.VISUAL) then
		return self:handleVisualMode(event)
	end

	return false
end

M.eventLoop = nil

function M:new()
	self.eventLoop = hs.eventtap.new(
		{ hs.eventtap.event.types.keyDown },
		function(event)
			return M:process(event)
		end
	)
end

---Starts the event loop
---@return nil
function M:start()
	if not self.eventLoop or not self.eventLoop:isEnabled() then
		self.eventLoop:start()
		Log.log.df("[EventHandler.startEventLoop] Started event loop")
	else
		Log.log.df("[EventHandler.startEventLoop] Event loop already running")
	end
end

---Stops the event loop
---@return nil
function M:stop()
	if self.eventLoop and self.eventLoop:isEnabled() then
		self.eventLoop:stop()
		self.eventLoop = nil
		Log.log.df("[EventHandler.stopEventLoop] Stopped event loop")
	else
		Log.log.df("[EventHandler.stopEventLoop] Event loop not running")
	end
end

return M
