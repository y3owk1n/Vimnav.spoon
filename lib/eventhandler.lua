local Log = require("lib.log")
local Cache = require("lib.cache")
local Modes = require("lib.modes")
local State = require("lib.state")
local Config = require("lib.config")
local Commands = require("lib.commands")
local Utils = require("lib.utils")
local Marks = require("lib.marks")
local Cleanup = require("lib.cleanup")
local Actions = require("lib.actions")
local Elements = require("lib.elements")
local Whichkey = require("lib.whichkey")

local M = {}

---Handles Vim input
---@param char string
---@param opts? Hs.Vimnav.EventHandler.HandleVimInputOpts
---@return nil
function M.handleVimInput(char, opts)
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
				require("lib.marks").click(markText:lower())
				Modes.setModeNormal()
				require("lib.marks").clear()
				require("lib.cleanup").onCommandComplete()
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

		require("lib.whichkey").scheduleShow(State.state.keyCapture)

		require("lib.menubar").setTitle(
			State.state.mode,
			State.state.keyCapture
		)
		require("lib.overlay").update(State.state.mode, State.state.keyCapture)
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
		require("lib.whichkey").scheduleShow(State.state.keyCapture)
	end

	require("lib.menubar").setTitle(State.state.mode, State.state.keyCapture)
	require("lib.overlay").update(State.state.mode, State.state.keyCapture)

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

		require("lib.cleanup").onCommandComplete()
	elseif prefixes and prefixes[State.state.keyCapture] then
		Log.log.df(
			"[EventHandler.handleVimInput] Found prefix: "
				.. State.state.keyCapture
		)
		-- Continue waiting for more keys
	else
		-- No mapping or prefix found, reset
		require("lib.cleanup").onCommandComplete()
	end
end

---Checks if the key is a valid key for the given name
---@param keyCode number
---@param name string
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.isKey(keyCode, name)
	return keyCode == hs.keycodes.map[name]
end

function M.isShiftEspace(event)
	local flags = event:getFlags()
	return flags.shift and M.isKey(event:getKeyCode(), "escape")
end

function M.isEspace(event)
	return M.isKey(event:getKeyCode(), "escape")
end

---Handles disabled mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.handleDisabledMode(event)
	return false
end

---Handles passthrough mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.handlePassthroughMode(event)
	if M.isShiftEspace(event) then
		Modes.setModeNormal()
		Marks.clear()
		return true
	end

	return false
end

---Handles insert mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.handleInsertMode(event)
	if M.isShiftEspace(event) then
		if Elements.isInBrowser() then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				Modes.setModeNormal()
				Marks.clear()
			end)
		end
		return true
	end

	if M.isEspace(event) then
		Modes.setModeInsertNormal()
		Marks.clear()
		return true
	end

	return false
end

---Handles insert normal mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.handleInsertNormalMode(event)
	if M.isShiftEspace(event) then
		if Elements.isInBrowser() then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				Modes.setModeNormal()
				Marks.clear()
			end)
		end
		return true
	end

	if M.isEspace(event) then
		if State.state.leaderPressed then
			Cleanup.onEscape()
			return true
		end
	end

	return M.processVimInput(event)
end

---Handles insert visual mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.handleInsertVisualMode(event)
	if M.isShiftEspace(event) then
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

	if M.isEspace(event) then
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

	return M.processVimInput(event)
end

---Handles links mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.handleLinkMode(event)
	if M.isEspace(event) then
		Modes.setModeNormal()
		Marks.clear()
		return true
	end

	return M.processVimInput(event)
end

---Handles normal mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.handleNormalMode(event)
	if M.isEspace(event) then
		Cleanup.onEscape()
		Actions.forceDeselectTextHighlights()
		return false
	end

	return M.processVimInput(event)
end

---Handles visual mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.handleVisualMode(event)
	if M.isEspace(event) then
		Actions.forceDeselectTextHighlights()
		Modes.setModeNormal()
		Marks.clear()
		Whichkey.hide()
		return false
	end

	return M.processVimInput(event)
end

---Handles vim input
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.processVimInput(event)
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
		M.handleVimInput(leaderKey, {
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

	M.handleVimInput(char, {
		modifiers = flags,
	})

	return true
end

---Handles events
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function M.process(event)
	local eventSourceIgnoreSignature = Utils.eventSourceIgnoreSignature
	-- Ignore synthetic events from Utils.keyStroke
	if
		event:getProperty(hs.eventtap.event.properties.eventSourceUserData)
		== eventSourceIgnoreSignature
	then
		Log.log.df("[M.process] SYNTHETIC EVENT DETECTED – SKIPPING")
		return false
	end

	if Modes.isMode(Modes.MODES.DISABLED) then
		return M.handleDisabledMode(event)
	end

	if Modes.isMode(Modes.MODES.PASSTHROUGH) then
		return M.handlePassthroughMode(event)
	end

	if Modes.isMode(Modes.MODES.INSERT) then
		return M.handleInsertMode(event)
	end

	if Modes.isMode(Modes.MODES.INSERT_NORMAL) then
		return M.handleInsertNormalMode(event)
	end

	if Modes.isMode(Modes.MODES.INSERT_VISUAL) then
		return M.handleInsertVisualMode(event)
	end

	if Modes.isMode(Modes.MODES.LINKS) then
		return M.handleLinkMode(event)
	end

	if Modes.isMode(Modes.MODES.NORMAL) then
		return M.handleNormalMode(event)
	end

	if Modes.isMode(Modes.MODES.VISUAL) then
		return M.handleVisualMode(event)
	end

	return false
end

function M.startEventLoop()
	if not State.state.eventLoop then
		State.state.eventLoop = hs.eventtap
			.new({ hs.eventtap.event.types.keyDown }, M.process)
			:start()
		Log.log.df("[M.startEventLoop] Started event loop")
	end
end

function M.stopEventLoop()
	if State.state.eventLoop then
		State.state.eventLoop:stop()
		State.state.eventLoop = nil
		Log.log.df("[M.stopEventLoop] Stopped event loop")
	end
end

return M
