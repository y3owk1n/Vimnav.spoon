---@diagnostic disable: undefined-global

local Utils = require("lib.utils")
local Log = require("lib.log")

local M = {}

---@type Hs.Vimnav.State
local defaultState = {
	mode = 1,
	keyCapture = nil,
	marks = {},
	linkCapture = "",
	lastEscape = 0,
	mappingPrefixes = {},
	allCombinations = {},
	markCanvas = nil,
	onClickCallback = nil,
	focusCachedResult = false,
	focusLastElement = nil,
	maxElements = 0,
	leaderPressed = false,
	leaderCapture = "",
	showingHelp = false,
}

---@type Hs.Vimnav.State
M.state = {}

---Creates the state
---@return nil
function M:new()
	Log.log.df("[State:new] Creating state")

	self.state = Utils.deepCopy(defaultState)
end

---Reset key capture state
---@return nil
function M:resetKeyCapture()
	Log.log.df("[State:resetKeyCapture] Resetting key capture")
	self.state.keyCapture = nil
end

---Reset leader state
---@return nil
function M:resetLeader()
	Log.log.df("[State:resetLeader] Resetting leader")
	self.state.leaderPressed = false
	self.state.leaderCapture = ""
end

---Reset marks state
---@return nil
function M:resetMarks()
	Log.log.df("[State:resetMarks] Resetting marks")
	self.state.marks = {}
end

---Reset marks canvas
---@return nil
function M:resetMarkCanvas()
	Log.log.df("[State:resetMarkCanvas] Resetting marks canvas")
	if self.state.markCanvas then
		self.state.markCanvas:delete()
		self.state.markCanvas = nil
	end
end

---Reset link capture state
---@return nil
function M:resetLinkCapture()
	Log.log.df("[State:resetLinkCapture] Resetting link capture")
	self.state.linkCapture = ""
end

---Reset focus state
---@return nil
function M:resetFocus()
	Log.log.df("[State:resetFocus] Resetting focus")
	self.state.focusCachedResult = false
	self.state.focusLastElement = nil
end

---Reset help state
---@return nil
function M:resetHelp()
	Log.log.df("[State:resetHelp] Resetting help")
	self.state.showingHelp = false
end

---Reset all input-related state (key, leader, link capture)
---@return nil
function M:resetInput()
	Log.log.df("[State:resetInput] Resetting input state")
	M:resetKeyCapture()
	M:resetLeader()
	M:resetLinkCapture()
	M:resetHelp()
end

---Reset all state completely
---@return nil
function M:resetAll()
	Log.log.df("[State:resetAll] Resetting all state")
	self.state = Utils.deepCopy(defaultState)
end

return M
