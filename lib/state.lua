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
	eventLoop = nil,
	markCanvas = nil,
	onClickCallback = nil,
	cleanupTimer = nil,
	focusCachedResult = false,
	focusLastElement = nil,
	maxElements = 0,
	leaderPressed = false,
	leaderCapture = "",
	whichKeyTimer = nil,
	whichKeyCanvas = nil,
	showingHelp = false,
	appWatcher = nil,
	launcherWatcher = {},
	screenWatcher = nil,
	caffeineWatcher = nil,
	focusCheckTimer = nil,
	menubarItem = nil,
	overlayCanvas = nil,
}

---@type Hs.Vimnav.State
M.state = {}

function M:new()
	Log.log.df("[State:new] Creating state")

	self.state = Utils.deepCopy(defaultState)
end

---Reset key capture state
function M:resetKeyCapture()
	Log.log.df("[State:resetKeyCapture] Resetting key capture")
	self.state.keyCapture = nil
end

---Reset leader state
function M:resetLeader()
	Log.log.df("[State:resetLeader] Resetting leader")
	self.state.leaderPressed = false
	self.state.leaderCapture = ""
end

---Reset marks state
function M:resetMarks()
	Log.log.df("[State:resetMarks] Resetting marks")
	self.state.marks = {}
end

---Reset marks canvas
function M:resetMarkCanvas()
	Log.log.df("[State:resetMarkCanvas] Resetting marks canvas")
	if self.state.markCanvas then
		self.state.markCanvas:delete()
		self.state.markCanvas = nil
	end
end

---Reset whichkey canvas
function M:resetWhichkeyCanvas()
	Log.log.df("[State:resetWhichkeyCanvas] Resetting whichkey canvas")
	if self.state.whichkeyCanvas then
		self.state.whichkeyCanvas:delete()
		self.state.whichkeyCanvas = nil
	end
end

---Reset overlay canvas
function M:resetOverlayCanvas()
	Log.log.df("[State:resetOverlayCanvas] Resetting overlay canvas")
	if self.state.overlayCanvas then
		self.state.overlayCanvas:delete()
		self.state.overlayCanvas = nil
	end
end

---Reset menubar item
function M:resetMenubarItem()
	Log.log.df("[State:resetMenubarItem] Resetting menubar item")
	if self.state.menubarItem then
		self.state.menubarItem:delete()
		self.state.menubarItem = nil
	end
end

---Reset link capture state
function M:resetLinkCapture()
	Log.log.df("[State:resetLinkCapture] Resetting link capture")
	self.state.linkCapture = ""
end

---Reset focus state
function M:resetFocus()
	Log.log.df("[State:resetFocus] Resetting focus")
	self.state.focusCachedResult = false
	self.state.focusLastElement = nil
end

---Reset help state
function M:resetHelp()
	Log.log.df("[State:resetHelp] Resetting help")
	self.state.showingHelp = false
end

---Reset all input-related state (key, leader, link capture)
function M:resetInput()
	Log.log.df("[State:resetInput] Resetting input state")
	M:resetKeyCapture()
	M:resetLeader()
	M:resetLinkCapture()
	M:resetHelp()
end

---Reset all state completely
function M:resetAll()
	Log.log.df("[State:resetAll] Resetting all state")
	self.state = Utils.deepCopy(defaultState)
end

return M
