local Utils = dofile(hs.spoons.resourcePath("./utils.lua"))

local M = {}

local DEFAULT_STATE = {
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

function M:new()
	local state = {}
	state = Utils.deepCopy(DEFAULT_STATE)
	return state
end

function M:getDefaultState()
	return Utils.deepCopy(DEFAULT_STATE)
end

---Reset key capture state
---@param vimnav Hs.Vimnav
function M.resetKeyCapture(vimnav)
	vimnav.state.keyCapture = nil
	vimnav.log.df("[M.resetKeyCapture] Reset")
end

---Reset leader state
---@param vimnav Hs.Vimnav
function M.resetLeader(vimnav)
	vimnav.state.leaderPressed = false
	vimnav.state.leaderCapture = ""
	vimnav.log.df("[M.resetLeader] Reset")
end

---Reset marks state
---@param vimnav Hs.Vimnav
function M.resetMarks(vimnav)
	vimnav.state.marks = {}
	vimnav.log.df("[M.resetMarks] Reset")
end

---Reset marks canvas
---@param vimnav Hs.Vimnav
function M.resetMarkCanvas(vimnav)
	if vimnav.state.markCanvas then
		vimnav.state.markCanvas:delete()
		vimnav.state.markCanvas = nil
	end
	vimnav.log.df("[M.resetMarkCanvas] Reset")
end

---Reset whichkey canvas
---@param vimnav Hs.Vimnav
function M.resetWhichkeyCanvas(vimnav)
	if vimnav.state.whichkeyCanvas then
		vimnav.state.whichkeyCanvas:delete()
		vimnav.state.whichkeyCanvas = nil
	end
	vimnav.log.df("[M.resetWhichkeyCanvas] Reset")
end

---Reset overlay canvas
---@param vimnav Hs.Vimnav
function M.resetOverlayCanvas(vimnav)
	if vimnav.state.overlayCanvas then
		vimnav.state.overlayCanvas:delete()
		vimnav.state.overlayCanvas = nil
	end
	vimnav.log.df("[M.resetOverlayCanvas] Reset")
end

---Reset menubar item
---@param vimnav Hs.Vimnav
function M.resetMenubarItem(vimnav)
	if vimnav.state.menubarItem then
		vimnav.state.menubarItem:delete()
		vimnav.state.menubarItem = nil
	end
	vimnav.log.df("[M.resetMenubarItem] Reset")
end

---Reset link capture state
---@param vimnav Hs.Vimnav
function M.resetLinkCapture(vimnav)
	vimnav.state.linkCapture = ""
	vimnav.log.df("[M.resetLinkCapture] Reset")
end

---Reset focus state
---@param vimnav Hs.Vimnav
function M.resetFocus(vimnav)
	vimnav.state.focusCachedResult = false
	vimnav.state.focusLastElement = nil
	vimnav.log.df("[M.resetFocus] Reset")
end

---Reset help state
---@param vimnav Hs.Vimnav
function M.resetHelp(vimnav)
	vimnav.state.showingHelp = false
	vimnav.log.df("[M.resetHelp] Reset")
end

---Reset all input-related state (key, leader, link capture)
---@param vimnav Hs.Vimnav
function M.resetInput(vimnav)
	M.resetKeyCapture(vimnav)
	M.resetLeader(vimnav)
	M.resetLinkCapture(vimnav)
	M.resetHelp(vimnav)
	vimnav.log.df("[M.resetInput] All input state reset")
end

---Reset all state completely
---@param vimnav Hs.Vimnav
function M.resetAll(vimnav)
	vimnav.state = Utils.deepCopy(M:getDefaultState())
	vimnav.log.df("[M.resetAll] Complete state reset")
end

return M
