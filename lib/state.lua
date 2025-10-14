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

return M
