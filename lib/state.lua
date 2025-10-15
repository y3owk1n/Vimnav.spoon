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

M.state = {}

function M:new()
	self.state = Utils.deepCopy(defaultState)
end

---Reset key capture state
function M:resetKeyCapture()
	self.state.keyCapture = nil
	Log.log.df("[StateManager.resetKeyCapture] Reset")
end

---Reset leader state
function M:resetLeader()
	self.state.leaderPressed = false
	self.state.leaderCapture = ""
	Log.log.df("[StateManager.resetLeader] Reset")
end

---Reset marks state
function M:resetMarks()
	self.state.marks = {}
	Log.log.df("[StateManager.resetMarks] Reset")
end

---Reset marks canvas
function M:resetMarkCanvas()
	if self.state.markCanvas then
		self.state.markCanvas:delete()
		self.state.markCanvas = nil
	end
	Log.log.df("[StateManager.resetMarkCanvas] Reset")
end

---Reset whichkey canvas
function M:resetWhichkeyCanvas()
	if self.state.whichkeyCanvas then
		self.state.whichkeyCanvas:delete()
		self.state.whichkeyCanvas = nil
	end
	Log.log.df("[StateManager.resetWhichkeyCanvas] Reset")
end

---Reset overlay canvas
function M:resetOverlayCanvas()
	if self.state.overlayCanvas then
		self.state.overlayCanvas:delete()
		self.state.overlayCanvas = nil
	end
	Log.log.df("[StateManager.resetOverlayCanvas] Reset")
end

---Reset menubar item
function M:resetMenubarItem()
	if self.state.menubarItem then
		self.state.menubarItem:delete()
		self.state.menubarItem = nil
	end
	Log.log.df("[StateManager.resetMenubarItem] Reset")
end

---Reset link capture state
function M:resetLinkCapture()
	self.state.linkCapture = ""
	Log.log.df("[StateManager.resetLinkCapture] Reset")
end

---Reset focus state
function M:resetFocus()
	self.state.focusCachedResult = false
	self.state.focusLastElement = nil
	Log.log.df("[StateManager.resetFocus] Reset")
end

---Reset help state
function M:resetHelp()
	self.state.showingHelp = false
	Log.log.df("[StateManager.resetHelp] Reset")
end

---Reset all input-related state (key, leader, link capture)
function M:resetInput()
	M:resetKeyCapture()
	M:resetLeader()
	M:resetLinkCapture()
	M:resetHelp()
	Log.log.df("[StateManager.resetInput] All input state reset")
end

---Reset all state completely
function M:resetAll()
	self.state = Utils.deepCopy(defaultState)
	Log.log.df("[StateManager.resetAll] Complete state reset")
end

return M
