-- Vimnav.spoon
--
-- Think of it like vimium, but available for system wide. Probably won't work on electron apps though, I don't use them.
--
-- This module is originated and credits to `dzirtuss` at `https://github.com/dzirtusss/vifari`
-- I had made lots of modifications to the original code including performance and supporting for system wide instead
-- of just within Safari. In my opinion, there are too many changes that made it hard to contribute back to the original
-- project, and Vifari is meant for only for Safari, not system wide.

---@diagnostic disable: undefined-global

---@class Hs.Vimnav
local M = {}

M.__index = M

M.name = "vimnav"

local Utils = {}
local Elements = {}
local MenuBar = {}
local ModeManager = {}
local Actions = {}
local ElementFinder = {}
local Marks = {}
local Commands = {}
local State = {}
local SpatialIndex = {}
local AsyncTraversal = {}
local RoleMaps = {}
local MarkPool = {}
local CanvasCache = {}

local log

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

---@class Hs.Vimnav.Config
---@field logLevel? string Log level to show in the console
---@field linkHintChars? string Link hint characters
---@field doublePressDelay? number Double press delay in seconds (e.g. 0.3 for 300ms)
---@field focusCheckInterval? number Focus check interval in seconds (e.g. 0.5 for 500ms)
---@field mapping? table<string, string|table> Mappings to use
---@field scrollStep? number Scroll step in pixels
---@field scrollStepHalfPage? number Scroll step in pixels for half page
---@field scrollStepFullPage? number Scroll step in pixels for full page
---@field smoothScroll? boolean Enable/disable smooth scrolling
---@field smoothScrollFramerate? number Smooth scroll framerate in frames per second
---@field depth? number Maximum depth to search for elements
---@field axEditableRoles? string[] Roles for detect editable inputs
---@field axJumpableRoles? string[] Roles for detect jumpable inputs (links and more)
---@field excludedApps? string[] Apps to exclude from Vimnav (e.g. Terminal)
---@field browsers? string[] Browsers to to detect for browser specific actions (e.g. Safari)
---@field launchers? string[] Launchers to to detect for launcher specific actions (e.g. Spotlight)
---@field enterEditableCallback? fun() Callback to run when in editable control
---@field exitEditableCallback? fun() Callback to run when out of editable control
---@field forceUnfocusCallback? fun() Callback to run when force unfocusing

---@class Hs.Vimnav.State
---@field mode number Vimnav mode
---@field multi string|nil Multi character input
---@field marks table<number, table<string, table|nil>> Marks
---@field linkCapture string Link capture state
---@field lastEscape number Last escape key press time
---@field mappingPrefixes table<string, boolean> Mapping prefixes
---@field allCombinations string[] All combinations
---@field eventLoop table|nil Event loop
---@field canvas table|nil Canvas
---@field onClickCallback fun(any)|nil On click callback for marks
---@field cleanupTimer table|nil Cleanup timer
---@field focusLastCheck number Focus last check time
---@field focusCachedResult boolean Focus cached result
---@field focusLastElement table|string|nil Focus last element
---@field maxElements number Maximum elements to search for (derived from config)

---@alias Hs.Vimnav.Element table|string

---@alias Hs.Vimnav.Modifier "cmd"|"ctrl"|"alt"|"shift"|"fn"

--------------------------------------------------------------------------------
-- Constants and Configuration
--------------------------------------------------------------------------------

local MODES = {
	DISABLED = 1,
	NORMAL = 2,
	INSERT = 3,
	MULTI = 4,
	LINKS = 5,
	PASSTHROUGH = 6,
}

local DEFAULT_MAPPING = {
	["i"] = "cmdPassthroughMode",
	-- movements
	["h"] = "cmdScrollLeft",
	["j"] = "cmdScrollDown",
	["k"] = "cmdScrollUp",
	["l"] = "cmdScrollRight",
	["C-d"] = "cmdScrollHalfPageDown",
	["C-u"] = "cmdScrollHalfPageUp",
	["G"] = "cmdScrollToBottom",
	["gg"] = "cmdScrollToTop",
	["H"] = { "cmd", "[" }, -- history back
	["L"] = { "cmd", "]" }, -- history forward
	["f"] = "cmdGotoLink",
	["r"] = "cmdRightClick",
	["F"] = "cmdGotoLinkNewTab",
	["di"] = "cmdDownloadImage",
	["gf"] = "cmdMoveMouseToLink",
	["gi"] = "cmdGotoInput",
	["zz"] = "cmdMoveMouseToCenter",
	["yy"] = "cmdCopyPageUrlToClipboard",
	["yf"] = "cmdCopyLinkUrlToClipboard",
	["]]"] = "cmdNextPage",
	["[["] = "cmdPrevPage",
}

---@type Hs.Vimnav.Config
local DEFAULT_CONFIG = {
	logLevel = "warning",
	linkHintChars = "abcdefghijklmnopqrstuvwxyz",
	doublePressDelay = 0.3,
	focusCheckInterval = 0.1,
	mapping = DEFAULT_MAPPING,
	scrollStep = 50,
	scrollStepHalfPage = 500,
	scrollStepFullPage = 1e6,
	smoothScroll = true,
	smoothScrollFramerate = 120,
	depth = 20,
	axEditableRoles = {
		"AXTextField",
		"AXComboBox",
		"AXTextArea",
		"AXSearchField",
	},
	axJumpableRoles = {
		"AXLink",
		"AXButton",
		"AXPopUpButton",
		"AXComboBox",
		"AXTextField",
		"AXTextArea",
		"AXCheckBox",
		"AXRadioButton",
		"AXDisclosureTriangle",
		"AXMenuButton",
		"AXMenuBarItem", -- To support top menu bar
		"AXMenuItem",
		"AXRow", -- To support Mail.app without using "AXStaticText"
		-- "AXColorWell", -- Macos Color Picker
		-- "AXCell", -- This can help with showing marks on Calendar.app
		-- "AXGroup", -- This can help with lots of MacOS apps, but creates lot of noise!
		-- "AXStaticText",
		-- "AXMenu",
		-- "AXToolbar",
		-- "AXToolbarButton",
		-- "AXTabGroup",
		-- "AXTab",
		-- "AXSlider",
		-- "AXIncrementor",
		-- "AXDecrementor",
	},
	excludedApps = { "Terminal", "Alacritty", "iTerm2", "Kitty", "Ghostty" },
	browsers = {
		"Safari",
		"Google Chrome",
		"Firefox",
		"Microsoft Edge",
		"Brave Browser",
		"Zen",
	},
	launchers = { "Spotlight", "Raycast", "Alfred" },
}

--------------------------------------------------------------------------------
-- State Management
--------------------------------------------------------------------------------

---@type Hs.Vimnav.State
State = {
	mode = MODES.DISABLED,
	multi = nil,
	marks = {},
	linkCapture = "",
	lastEscape = hs.timer.absoluteTime(),
	mappingPrefixes = {},
	allCombinations = {},
	eventLoop = nil,
	canvas = nil,
	onClickCallback = nil,
	cleanupTimer = nil,
	focusLastCheck = 0,
	focusCachedResult = false,
	focusLastElement = nil,
	maxElements = 0,
}

-- Element cache with weak references for garbage collection
local elementCache = setmetatable({}, { __mode = "k" })

local attributeCache = setmetatable({}, { __mode = "k" })

--------------------------------------------------------------------------------
-- Spatial Indexing
--------------------------------------------------------------------------------

---Quad-tree like spatial indexing for viewport culling
---@return table|nil
function SpatialIndex.createViewportRegions()
	local fullArea = Elements.getFullArea()
	if not fullArea then
		return nil
	end

	return {
		x = fullArea.x,
		y = fullArea.y,
		w = fullArea.w,
		h = fullArea.h,
		centerX = fullArea.x + fullArea.w / 2,
		centerY = fullArea.y + fullArea.h / 2,
	}
end

---@class Hs.Vimnav.SpatialIndex.IsInViewportOpts
---@field fx number
---@field fy number
---@field fw number
---@field fh number
---@field viewport table

---Checks if the element is in the viewport
---@param opts Hs.Vimnav.SpatialIndex.IsInViewportOpts
---@return boolean
function SpatialIndex.isInViewport(opts)
	local fx = opts.fx
	local fy = opts.fy
	local fw = opts.fw
	local fh = opts.fh
	local viewport = opts.viewport

	return fx < viewport.x + viewport.w
		and fx + fw > viewport.x
		and fy < viewport.y + viewport.h
		and fy + fh > viewport.y
		and fw > 2
		and fh > 2 -- Skip tiny elements
end

--------------------------------------------------------------------------------
-- Coroutine-based Async Traversal
--------------------------------------------------------------------------------

---@class Hs.Vimnav.AsyncTraversal.TraversalOpts
---@field matcher fun(element: table): boolean
---@field callback fun(results: table)
---@field maxResults number

---Process elements in background coroutine to avoid UI blocking
---@param element table
---@param opts Hs.Vimnav.AsyncTraversal.TraversalOpts
---@return nil
function AsyncTraversal.traverseAsync(element, opts)
	local matcher = opts.matcher
	local callback = opts.callback
	local maxResults = opts.maxResults

	local results = {}
	local viewport = SpatialIndex.createViewportRegions()

	if not viewport then
		callback({})
		return
	end

	local traverseCoroutine = coroutine.create(function()
		AsyncTraversal.walkElement(element, {
			depth = 0,
			matcher = matcher,
			callback = function(el)
				results[#results + 1] = el
				return #results >= maxResults
			end,
			viewport = viewport,
		})
	end)

	-- Resume coroutine in chunks
	local function resumeWork()
		if coroutine.status(traverseCoroutine) == "dead" then
			callback(results)
			return
		end

		local success, shouldStop = coroutine.resume(traverseCoroutine)
		if success and not shouldStop then
			hs.timer.doAfter(0.001, resumeWork) -- 1ms pause
		else
			callback(results)
		end
	end

	resumeWork()
end

---@class Hs.Vimnav.AsyncTraversal.WalkElementOpts
---@field depth number
---@field matcher fun(element: table): boolean
---@field callback fun(element: table): boolean
---@field viewport table

---Walks an element with a matcher
---@param element table
---@param opts Hs.Vimnav.AsyncTraversal.WalkElementOpts
---@return boolean|nil
function AsyncTraversal.walkElement(element, opts)
	local depth = opts.depth
	local matcher = opts.matcher
	local callback = opts.callback
	local viewport = opts.viewport

	if depth > M.config.depth then
		return
	end -- Hard depth limit

	local batchSize = 0
	local function processElement(el)
		batchSize = batchSize + 1

		-- Batch yield every 30 elements to stay responsive
		if batchSize % 30 == 0 then
			coroutine.yield(false) -- Don't stop, just yield
		end

		-- Get frame once, reuse everywhere
		local frame = Utils.getAttribute(el, "AXFrame")
		if not frame then
			return
		end

		-- Viewport check
		if
			not SpatialIndex.isInViewport({
				fx = frame.x,
				fy = frame.y,
				fw = frame.w,
				fh = frame.h,
				viewport = viewport,
			})
		then
			return
		end

		-- Test element
		if matcher(el) then
			if callback(el) then -- callback returns true to stop
				return true
			end
		end

		-- Process children
		local children = Utils.getAttribute(el, "AXVisibleChildren")
			or Utils.getAttribute(el, "AXChildren")
			or {}

		for i = 1, #children do
			local matched = AsyncTraversal.walkElement(children[i], {
				depth = depth + 1,
				matcher = matcher,
				callback = callback,
				viewport = viewport,
			})

			if matched then
				return true
			end
		end
	end

	local role = Utils.getAttribute(element, "AXRole")
	if role == "AXApplication" then
		local children = Utils.getAttribute(element, "AXChildren") or {}
		for i = 1, #children do
			if processElement(children[i]) then
				return true
			end
		end
	else
		return processElement(element)
	end
end

--------------------------------------------------------------------------------
-- Pre-computed Role Maps and Lookup Tables
--------------------------------------------------------------------------------

---Pre-compute role sets as hash maps for O(1) lookup
---@return nil
function RoleMaps.init()
	RoleMaps.jumpableSet = {}
	for _, role in ipairs(M.config.axJumpableRoles) do
		RoleMaps.jumpableSet[role] = true
	end

	RoleMaps.editableSet = {}
	for _, role in ipairs(M.config.axEditableRoles) do
		RoleMaps.editableSet[role] = true
	end

	RoleMaps.skipSet = {
		AXGenericElement = true,
		AXUnknown = true,
		AXSeparator = true,
		AXSplitter = true,
		AXProgressIndicator = true,
		AXValueIndicator = true,
		AXLayoutArea = true,
		AXLayoutItem = true,
		AXStaticText = true, -- Usually not interactive
	}
	log.df("Initialized role maps")
end

---Checks if the role is jumpable
---@param role string
---@return boolean
function RoleMaps.isJumpable(role)
	return RoleMaps.jumpableSet and RoleMaps.jumpableSet[role] == true
end

---Checks if the role is editable
---@param role string
---@return boolean
function RoleMaps.isEditable(role)
	return RoleMaps.editableSet and RoleMaps.editableSet[role] == true
end

---Checks if the role should be skipped
---@param role string
---@return boolean
function RoleMaps.shouldSkip(role)
	return RoleMaps.skipSet and RoleMaps.skipSet[role] == true
end

--------------------------------------------------------------------------------
-- Memory Pool for Mark Elements
--------------------------------------------------------------------------------

MarkPool.pool = {}
MarkPool.active = {}

---Reuse mark objects to avoid GC pressure
---@return table
function MarkPool.getMark()
	local mark = table.remove(MarkPool.pool)
	if not mark then
		mark = { element = nil, frame = nil, role = nil }
	end
	MarkPool.active[#MarkPool.active + 1] = mark
	return mark
end

---Release all marks
---@return nil
function MarkPool.releaseAll()
	for i = 1, #MarkPool.active do
		local mark = MarkPool.active[i]
		mark.element = nil
		mark.frame = nil
		mark.role = nil
		MarkPool.pool[#MarkPool.pool + 1] = mark
	end
	MarkPool.active = {}
end

--------------------------------------------------------------------------------
-- Canvas Element Caching
--------------------------------------------------------------------------------

---Returns the mark template
---@return table
function CanvasCache.getMarkTemplate()
	if CanvasCache.template then
		return CanvasCache.template
	end

	CanvasCache.template = {
		background = {
			type = "segments",
			fillGradient = "linear",
			fillGradientColors = {
				{ red = 1, green = 0.96, blue = 0.52, alpha = 1 },
				{
					red = 1,
					green = 0.77,
					blue = 0.26,
					alpha = 1,
				},
			},
			strokeColor = { red = 0, green = 0, blue = 0, alpha = 1 },
			strokeWidth = 1,
			closed = true,
		},
		text = {
			type = "text",
			textAlignment = "center",
			textColor = { red = 0, green = 0, blue = 0, alpha = 1 },
			textSize = 10,
			textFont = ".AppleSystemUIFontHeavy",
		},
	}

	return CanvasCache.template
end

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

---Helper function to check if something is a "list-like" table
---@param t table
---@return boolean
function Utils.isList(t)
	if type(t) ~= "table" then
		return false
	end
	local count = 0
	for k, _ in pairs(t) do
		count = count + 1
		if type(k) ~= "number" or k <= 0 or k > count then
			return false
		end
	end
	return true
end

---Helper function to deep copy a value
---@param obj table
---@return table
function Utils.deepCopy(obj)
	if type(obj) ~= "table" then
		return obj
	end

	local copy = {}
	for k, v in pairs(obj) do
		copy[k] = Utils.deepCopy(v)
	end
	return copy
end

---@param behavior "error"|"keep"|"force"
---@param ... table
---@return table
function Utils.tblDeepExtend(behavior, ...)
	if select("#", ...) < 2 then
		error("tblDeepExtend expects at least 2 tables")
	end

	local ret = {}

	-- Handle the behavior parameter
	local validBehaviors = {
		error = true,
		keep = true,
		force = true,
	}

	if not validBehaviors[behavior] then
		error("invalid behavior: " .. tostring(behavior))
	end

	-- Process each table argument
	for i = 1, select("#", ...) do
		local t = select(i, ...)

		if type(t) ~= "table" then
			error("expected table, got " .. type(t))
		end

		for k, v in pairs(t) do
			if ret[k] == nil then
				-- Key doesn't exist, just copy it
				ret[k] = Utils.deepCopy(v)
			elseif
				type(ret[k]) == "table"
				and type(v) == "table"
				and not Utils.isList(ret[k])
				and not Utils.isList(v)
			then
				-- Both are non-list tables, merge recursively
				ret[k] = Utils.tblDeepExtend(behavior, ret[k], v)
			else
				-- Handle conflicts based on behavior
				if behavior == "error" then
					error("key '" .. tostring(k) .. "' is already present")
				elseif behavior == "keep" then
				-- Keep existing value, do nothing
				elseif behavior == "force" then
					-- Overwrite with new value
					ret[k] = Utils.deepCopy(v)
				end
			end
		end
	end

	return ret
end

---Checks if a table contains a value
---@param tbl table
---@param val any
---@return boolean
function Utils.tblContains(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

---@param mods "cmd"|"ctrl"|"alt"|"shift"|"fn"|("cmd"|"ctrl"|"alt"|"shift"|"fn")[]
---@param key string
---@param delay? number
---@param application? table
---@return nil
function Utils.keyStroke(mods, key, delay, application)
	if type(mods) == "string" then
		mods = { mods }
	end
	hs.eventtap.keyStroke(mods, key, delay or 0, application)
end

---Gets an element from the cache
---@param key string
---@param factory fun(): Hs.Vimnav.Element|nil
---@return Hs.Vimnav.Element|nil
function Utils.getCachedElement(key, factory)
	if
		elementCache[key]
		and pcall(function()
			return elementCache[key]:isValid()
		end)
		and elementCache[key]:isValid()
	then
		return elementCache[key]
	end

	local element = factory()
	if element then
		elementCache[key] = element
	end
	return element
end

---Clears the element cache
---@return nil
function Utils.clearCache()
	elementCache = setmetatable({}, { __mode = "k" })
	attributeCache = setmetatable({}, { __mode = "k" })
end

---Gets an attribute from an element
---@param element Hs.Vimnav.Element
---@param attributeName string
---@return Hs.Vimnav.Element|nil
function Utils.getAttribute(element, attributeName)
	if not element then
		return nil
	end

	local cacheKey = tostring(element) .. ":" .. attributeName
	local cached = attributeCache[cacheKey]

	if cached ~= nil then
		return cached == "NIL_VALUE" and nil or cached
	end

	local success, result = pcall(function()
		return element:attributeValue(attributeName)
	end)

	result = success and result or nil

	-- Store nil as a special marker to distinguish from uncached
	attributeCache[cacheKey] = result == nil and "NIL_VALUE" or result
	return result
end

---Generates all combinations of letters
---@return nil
function Utils.generateCombinations()
	if #State.allCombinations > 0 then
		log.df("Already generated combinations")
		return
	end -- Already generated

	local chars = M.config.linkHintChars

	if not chars then
		log.ef("No link hint characters configured")
		return
	end

	State.maxElements = #chars * #chars

	for i = 1, #chars do
		for j = 1, #chars do
			table.insert(
				State.allCombinations,
				chars:sub(i, i) .. chars:sub(j, j)
			)
			if #State.allCombinations >= State.maxElements then
				return
			end
		end
	end
	log.df("Generated " .. #State.allCombinations .. " combinations")
end

---Fetches all mapping prefixes
---@return nil
function Utils.fetchMappingPrefixes()
	State.mappingPrefixes = {}
	for k, _ in pairs(M.config.mapping) do
		if #k == 2 then
			State.mappingPrefixes[string.sub(k, 1, 1)] = true
		end
	end
	log.df("Fetched mapping prefixes")
end

---Checks if the current application is excluded
---@return boolean
function Utils.isExcludedApp()
	local app = Elements.getApp()
	return app and Utils.tblContains(M.config.excludedApps, app:name()) or false
end

---Checks if the launcher is active
---@return boolean
---@return string|nil
function Utils.isLauncherActive()
	for _, launcher in ipairs(M.config.launchers) do
		local app = hs.application.get(launcher)
		if app then
			local appElement = hs.axuielement.applicationElement(app)
			if appElement then
				local windows = Utils.getAttribute(appElement, "AXWindows")
					or {}
				if #windows > 0 then
					return true, launcher
				end
			end
		end
	end
	return false
end

---Checks if the application is in the browser list
---@return boolean
function Utils.isInBrowser()
	local app = Elements.getApp()
	return app and Utils.tblContains(M.config.browsers, app:name()) or false
end

--------------------------------------------------------------------------------
-- Element Access
--------------------------------------------------------------------------------

---Returns the application element
---@return Hs.Vimnav.Element|nil
function Elements.getApp()
	return Utils.getCachedElement("app", function()
		return hs.application.frontmostApplication()
	end)
end

---Returns the application element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxApp()
	return Utils.getCachedElement("axApp", function()
		local app = Elements.getApp()
		return app and hs.axuielement.applicationElement(app)
	end)
end

---Returns the window element
---@return Hs.Vimnav.Element|nil
function Elements.getWindow()
	return Utils.getCachedElement("window", function()
		local app = Elements.getApp()
		return app and app:focusedWindow()
	end)
end

---Returns the window element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxWindow()
	return Utils.getCachedElement("axWindow", function()
		local window = Elements.getWindow()
		return window and hs.axuielement.windowElement(window)
	end)
end

---Returns the focused element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxFocusedElement()
	return Utils.getCachedElement("axFocusedElement", function()
		local axApp = Elements.getAxApp()
		return axApp and Utils.getAttribute(axApp, "AXFocusedUIElement")
	end)
end

---Returns the web area element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxWebArea()
	return Utils.getCachedElement("axWebArea", function()
		local axWindow = Elements.getAxWindow()
		return axWindow and Elements.findAxRole(axWindow, "AXWebArea")
	end)
end

---Returns the menu bar element for AXUIElement
---@return Hs.Vimnav.Element|nil
function Elements.getAxMenuBar()
	return Utils.getCachedElement("axMenuBar", function()
		local axApp = Elements.getAxApp()
		return axApp and Utils.getAttribute(axApp, "AXMenuBar")
	end)
end

---Returns the full area element
---@return Hs.Vimnav.Element|nil
function Elements.getFullArea()
	return Utils.getCachedElement("fullArea", function()
		local axWin = Elements.getAxWindow()
		local axMenuBar = Elements.getAxMenuBar()

		if not axWin or not axMenuBar then
			return nil
		end

		local winFrame = Utils.getAttribute(axWin, "AXFrame") or {}
		local menuBarFrame = Utils.getAttribute(axMenuBar, "AXFrame") or {}

		return {
			x = 0,
			y = 0,
			w = menuBarFrame.w,
			h = winFrame.h + winFrame.y + menuBarFrame.h,
		}
	end)
end

---Finds an element with a specific AXRole
---@param rootElement Hs.Vimnav.Element
---@param role string
---@return Hs.Vimnav.Element|nil
function Elements.findAxRole(rootElement, role)
	if not rootElement then
		return nil
	end

	local axRole = Utils.getAttribute(rootElement, "AXRole")
	if axRole == role then
		return rootElement
	end

	local axChildren = Utils.getAttribute(rootElement, "AXChildren") or {}

	if type(axChildren) == "string" then
		return nil
	end

	for _, child in ipairs(axChildren) do
		local result = Elements.findAxRole(child, role)
		if result then
			return result
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- Menu Bar
--------------------------------------------------------------------------------

---Creates the menu bar item
---@return nil
function MenuBar.create()
	if MenuBar.item then
		MenuBar.destroy()
	end
	MenuBar.item = hs.menubar.new()
	MenuBar.item:setTitle("N")
	log.df("Created menu bar item")
end

---Destroys the menu bar item
---@return nil
function MenuBar.destroy()
	if MenuBar.item then
		MenuBar.item:delete()
		MenuBar.item = nil
		log.df("Destroyed menu bar item")
	end
end

--------------------------------------------------------------------------------
-- Mode Management
--------------------------------------------------------------------------------

---Sets the mode
---@param mode number
---@param char string|nil
---@return nil
function ModeManager.setMode(mode, char)
	local defaultModeChars = {
		[MODES.DISABLED] = "X",
		[MODES.INSERT] = "I",
		[MODES.LINKS] = "L",
		[MODES.MULTI] = "M",
		[MODES.NORMAL] = "N",
		[MODES.PASSTHROUGH] = "IP",
	}

	local previousMode = State.mode
	State.mode = mode

	if mode == MODES.LINKS and previousMode ~= MODES.LINKS then
		State.linkCapture = ""
		Marks.clear()
	elseif previousMode == MODES.LINKS and mode ~= MODES.LINKS then
		hs.timer.doAfter(0, Marks.clear)
	end

	if mode == MODES.MULTI then
		State.multi = char
	else
		State.multi = nil
	end

	if MenuBar.item then
		local modeChar = char or defaultModeChars[mode] or "?"
		MenuBar.item:setTitle(modeChar)
	end

	log.df(string.format("Mode changed: %s -> %s", previousMode, mode))
end

--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------

---@class Hs.Vimnav.Actions.SmoothScrollOpts
---@field x? number|nil
---@field y? number|nil
---@field smooth? boolean

---Performs a smooth scroll
---@param opts Hs.Vimnav.Actions.SmoothScrollOpts
---@return nil
function Actions.smoothScroll(opts)
	local x = opts.x or 0
	local y = opts.y or 0
	local smooth = opts.smooth or M.config.smoothScroll

	if not smooth then
		hs.eventtap.event.newScrollEvent({ x, y }, {}, "pixel"):post()
		return
	end

	local steps = 5
	local dx = x and (x / steps) or 0
	local dy = y and (y / steps) or 0
	local frame = 0
	local interval = 1 / M.config.smoothScrollFramerate

	local function animate()
		frame = frame + 1
		if frame > steps then
			return
		end

		local factor = frame <= steps / 2 and 2 or 0.5
		hs.eventtap.event
			.newScrollEvent({ dx * factor, dy * factor }, {}, "pixel")
			:post()
		hs.timer.doAfter(interval, animate)
	end

	animate()
end

---Opens a URL in a new tab
---@param url string
---@return nil
function Actions.openUrlInNewTab(url)
	if not url then
		return
	end

	local browserScripts = {
		Safari = 'tell application "Safari" to tell window 1 to set current tab to (make new tab with properties {URL:"%s"})',
		["Google Chrome"] = 'tell application "Google Chrome" to tell window 1 to make new tab with properties {URL:"%s"}',
		Firefox = 'tell application "Firefox" to tell window 1 to open location "%s"',
		["Microsoft Edge"] = 'tell application "Microsoft Edge" to tell window 1 to make new tab with properties {URL:"%s"}',
		["Brave Browser"] = 'tell application "Brave Browser" to tell window 1 to make new tab with properties {URL:"%s"}',
		Zen = 'tell application "Zen" to open location "%s"',
	}

	local currentApp = Elements.getApp()
	if not currentApp then
		return
	end

	local appName = currentApp:name()
	local script = browserScripts[appName] or browserScripts["Safari"]

	hs.osascript.applescript(string.format(script, url))
end

---Sets the clipboard contents
---@param contents string
---@return nil
function Actions.setClipboardContents(contents)
	if not contents then
		hs.alert.show("Nothing to copy", nil, nil, 2)
		return
	end

	if hs.pasteboard.setContents(contents) then
		hs.alert.show(
			"Copied: "
				.. contents:sub(1, 50)
				.. (contents:len() > 50 and "..." or ""),
			nil,
			nil,
			2
		)
	else
		hs.alert.show("Failed to copy to clipboard", nil, nil, 2)
	end
end

---Force unfocus
---@return nil
function Actions.forceUnfocus()
	if State.focusLastElement then
		State.focusLastElement:setAttributeValue("AXFocused", false)
		hs.alert.show("Force unfocused!")

		-- Reset focus state
		State.focusLastCheck = 0
		State.focusCachedResult = false
		State.focusLastElement = nil
	end

	if
		M.config.forceUnfocusCallback
		and type(M.config.forceUnfocusCallback) == "function"
	then
		log.df("called forceUnfocusCallback()")
		M.config.forceUnfocusCallback()
	end
end

---@class Hs.Vimnav.Actions.TryClickOpts
---@field type? string "left"|"right"

---Tries to click on a frame
---@param frame table
---@param opts? Hs.Vimnav.Actions.TryClickOpts
---@return nil
function Actions.tryClick(frame, opts)
	opts = opts or {}
	local type = opts.type or "left"

	local clickX, clickY = frame.x + frame.w / 2, frame.y + frame.h / 2
	local originalPos = hs.mouse.absolutePosition()
	hs.mouse.absolutePosition({ x = clickX, y = clickY })
	if type == "left" then
		hs.eventtap.leftClick({ x = clickX, y = clickY })
	elseif type == "right" then
		hs.eventtap.rightClick({ x = clickX, y = clickY })
	end
	hs.timer.doAfter(0.1, function()
		hs.mouse.absolutePosition(originalPos)
	end)
end

--------------------------------------------------------------------------------
-- Element Finders
--------------------------------------------------------------------------------

---@class Hs.Vimnav.ElementFinder.FindElementsOpts
---@field callback fun(elements: table)

---@class Hs.Vimnav.ElementFinder.FindClickableElementsOpts: Hs.Vimnav.ElementFinder.FindElementsOpts
---@field withUrls boolean

---Finds clickable elements
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindClickableElementsOpts
---@return nil
function ElementFinder.findClickableElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback
	local withUrls = opts.withUrls

	local function _matcher(element)
		local role = Utils.getAttribute(element, "AXRole")

		if withUrls then
			local url = Utils.getAttribute(element, "AXURL")
			return url ~= nil
		end

		-- Role check
		if
			not role
			or type(role) ~= "string"
			or not RoleMaps.isJumpable(role)
		then
			return false
		end

		-- Skip obviously non-interactive elements quickly
		if RoleMaps.shouldSkip(role) then
			return false
		end

		return true
	end

	AsyncTraversal.traverseAsync(axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = State.maxElements,
	})
end

---Finds input elements
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindElementsOpts
---@return nil
function ElementFinder.findInputElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Utils.getAttribute(element, "AXRole")
		return (role and type(role) == "string" and RoleMaps.isEditable(role))
			or false
	end

	local function _callback(results)
		-- Auto-click if single input found
		if #results == 1 then
			State.onClickCallback({
				element = results[1],
				frame = Utils.getAttribute(results[1], "AXFrame"),
			})
			Commands.cmdNormalMode()
		else
			callback(results)
		end
	end

	AsyncTraversal.traverseAsync(axApp, {
		matcher = _matcher,
		callback = _callback,
		maxResults = 10,
	})
end

---Finds image elements
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindElementsOpts
---@return nil
function ElementFinder.findImageElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Utils.getAttribute(element, "AXRole")
		local url = Utils.getAttribute(element, "AXURL")
		return role == "AXImage" and url ~= nil
	end

	AsyncTraversal.traverseAsync(axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 100,
	})
end

---Finds next button elemets
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindElementsOpts
---@return nil
function ElementFinder.findNextButtonElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Utils.getAttribute(element, "AXRole")
		local title = Utils.getAttribute(element, "AXTitle")

		if
			(role == "AXLink" or role == "AXButton")
			and title
			and type(title) == "string"
		then
			return title:lower():find("next") ~= nil
		end
		return false
	end

	AsyncTraversal.traverseAsync(axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 5,
	})
end

---Finds previous button elemets
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindElementsOpts
---@return nil
function ElementFinder.findPrevButtonElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Utils.getAttribute(element, "AXRole")
		local title = Utils.getAttribute(element, "AXTitle")

		if
			(role == "AXLink" or role == "AXButton")
			and title
			and type(title) == "string"
		then
			return title:lower():find("prev") ~= nil
				or title:lower():find("previous") ~= nil
				or false
		end
		return false
	end

	AsyncTraversal.traverseAsync(axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 5,
	})
end

--------------------------------------------------------------------------------
-- Marks System
--------------------------------------------------------------------------------

---Clears the marks
---@return nil
function Marks.clear()
	if State.canvas then
		State.canvas:delete()
		State.canvas = nil
	end
	State.marks = {}
	State.linkCapture = ""
	MarkPool.releaseAll()
	log.df("Cleared marks")
end

---Adds a mark to the list
---@param element table
---@return nil
function Marks.add(element)
	if #State.marks >= State.maxElements then
		return
	end

	local frame = Utils.getAttribute(element, "AXFrame")
	if not frame or frame.w <= 2 or frame.h <= 2 then
		return
	end

	local mark = MarkPool.getMark()
	mark.element = element
	mark.frame = frame
	mark.role = Utils.getAttribute(element, "AXRole")

	State.marks[#State.marks + 1] = mark
end

---@class Hs.Vimnav.Marks.ShowOpts
---@field withUrls? boolean
---@field elementType "link"|"input"|"image"

---Show marks
---@param opts Hs.Vimnav.Marks.ShowOpts
---@return nil
function Marks.show(opts)
	local axApp = Elements.getAxApp()
	if not axApp then
		return
	end

	local withUrls = opts.withUrls or false
	local elementType = opts.elementType

	Marks.clear()
	State.marks = {}
	MarkPool.releaseAll()

	if elementType == "link" then
		local function _callback(elements)
			-- Convert to marks
			for i = 1, math.min(#elements, State.maxElements) do
				Marks.add(elements[i])
			end

			if #State.marks > 0 then
				Marks.draw()
			else
				hs.alert.show("No links found", nil, nil, 1)
				Commands.cmdNormalMode()
			end
		end
		ElementFinder.findClickableElements(axApp, {
			withUrls = withUrls,
			callback = _callback,
		})
	elseif elementType == "input" then
		local function _callback(elements)
			for i = 1, #elements do
				Marks.add(elements[i])
			end
			if #State.marks > 0 then
				Marks.draw()
			else
				hs.alert.show("No inputs found", nil, nil, 1)
				Commands.cmdNormalMode()
			end
		end
		ElementFinder.findInputElements(axApp, {
			callback = _callback,
		})
	elseif elementType == "image" then
		local function _callback(elements)
			for i = 1, #elements do
				Marks.add(elements[i])
			end
			if #State.marks > 0 then
				Marks.draw()
			else
				hs.alert.show("No images found", nil, nil, 1)
				Commands.cmdNormalMode()
			end
		end
		ElementFinder.findImageElements(axApp, {
			callback = _callback,
		})
	end
end

---Draws the marks
---@return nil
function Marks.draw()
	if not State.canvas then
		local frame = Elements.getFullArea()
		if not frame then
			return
		end
		State.canvas = hs.canvas.new(frame)
	end

	local captureLen = #State.linkCapture
	local elementsToDraw = {}
	local template = CanvasCache.getMarkTemplate()

	local count = 0
	for i = 1, #State.marks do
		if count >= #State.allCombinations then
			break
		end

		local mark = State.marks[i]
		local markText = State.allCombinations[i]:upper()

		if
			captureLen == 0
			or markText:sub(1, captureLen) == State.linkCapture
		then
			-- Clone template and update coordinates
			local bg = {}
			local text = {}

			for k, v in pairs(template.background) do
				bg[k] = v
			end
			for k, v in pairs(template.text) do
				text[k] = v
			end

			-- Quick coordinate calculation
			local frame = mark.frame
			if frame then
				local padding = 2
				local fontSize = 10
				local textWidth = #markText * (fontSize * 1.1)
				local textHeight = fontSize * 1.1
				local containerWidth = textWidth + (padding * 2)
				local containerHeight = textHeight + (padding * 2)

				local arrowHeight = 3
				local arrowWidth = 6
				local cornerRadius = 2

				local bgRect = hs.geometry.rect(
					frame.x + (frame.w / 2) - (containerWidth / 2),
					frame.y + (frame.h / 3 * 2) + arrowHeight,
					containerWidth,
					containerHeight
				)

				local rx = bgRect.x
				local ry = bgRect.y
				local rw = bgRect.w
				local rh = bgRect.h

				local arrowLeft = rx + (rw / 2) - (arrowWidth / 2)
				local arrowRight = arrowLeft + arrowWidth
				local arrowTop = ry - arrowHeight
				local arrowBottom = ry
				local arrowMiddle = arrowLeft + (arrowWidth / 2)

				bg.coordinates = {
					-- Draw arrow
					{ x = arrowLeft, y = arrowBottom },
					{ x = arrowMiddle, y = arrowTop },
					{ x = arrowRight, y = arrowBottom },
					-- Top right corner
					{
						x = rx + rw - cornerRadius,
						y = ry,
						c1x = rx + rw - cornerRadius,
						c1y = ry,
						c2x = rx + rw,
						c2y = ry,
					},
					{
						x = rx + rw,
						y = ry + cornerRadius,
						c1x = rx + rw,
						c1y = ry,
						c2x = rx + rw,
						c2y = ry + cornerRadius,
					},
					-- Bottom right corner
					{
						x = rx + rw,
						y = ry + rh - cornerRadius,
						c1x = rx + rw,
						c1y = ry + rh - cornerRadius,
						c2x = rx + rw,
						c2y = ry + rh,
					},
					{
						x = rx + rw - cornerRadius,
						y = ry + rh,
						c1x = rx + rw,
						c1y = ry + rh,
						c2x = rx + rw - cornerRadius,
						c2y = ry + rh,
					},
					-- Bottom left corner
					{
						x = rx + cornerRadius,
						y = ry + rh,
						c1x = rx + cornerRadius,
						c1y = ry + rh,
						c2x = rx,
						c2y = ry + rh,
					},
					{
						x = rx,
						y = ry + rh - cornerRadius,
						c1x = rx,
						c1y = ry + rh,
						c2x = rx,
						c2y = ry + rh - cornerRadius,
					},
					-- Top left corner
					{
						x = rx,
						y = ry + cornerRadius,
						c1x = rx,
						c1y = ry + cornerRadius,
						c2x = rx,
						c2y = ry,
					},
					{
						x = rx + cornerRadius,
						y = ry,
						c1x = rx,
						c1y = ry,
						c2x = rx + cornerRadius,
						c2y = ry,
					},
					-- Back to start
					{ x = arrowLeft, y = arrowBottom },
				}
				text.text = markText
				text.frame = {
					x = rx,
					y = ry - (arrowHeight / 2) + ((rh - textHeight) / 2), -- Vertically center
					w = rw,
					h = textHeight,
				}

				elementsToDraw[#elementsToDraw + 1] = bg
				elementsToDraw[#elementsToDraw + 1] = text
				count = count + 1
			end
		end
	end

	State.canvas:replaceElements(elementsToDraw)
	State.canvas:show()
end

---Clicks a mark
---@param combination string
---@return nil
function Marks.click(combination)
	for i, c in ipairs(State.allCombinations) do
		if c == combination and State.marks[i] and State.onClickCallback then
			local success, err = pcall(State.onClickCallback, State.marks[i])
			if not success then
				log.ef("Error clicking element: " .. tostring(err))
			end
			break
		end
	end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

---Scrolls left
---@return nil
function Commands.cmdScrollLeft()
	Actions.smoothScroll({ x = M.config.scrollStep })
end

---Scrolls right
---@return nil
function Commands.cmdScrollRight()
	Actions.smoothScroll({ x = -M.config.scrollStep })
end

---Scrolls up
---@return nil
function Commands.cmdScrollUp()
	Actions.smoothScroll({ y = M.config.scrollStep })
end

---Scrolls down
---@return nil
function Commands.cmdScrollDown()
	Actions.smoothScroll({ y = -M.config.scrollStep })
end

---Scrolls half page down
---@return nil
function Commands.cmdScrollHalfPageDown()
	Actions.smoothScroll({ y = -M.config.scrollStepHalfPage })
end

---Scrolls half page up
---@return nil
function Commands.cmdScrollHalfPageUp()
	Actions.smoothScroll({ y = M.config.scrollStepHalfPage })
end

---Scrolls to top
---@return nil
function Commands.cmdScrollToTop()
	Actions.smoothScroll({ y = M.config.scrollStepFullPage })
end

---Scrolls to bottom
---@return nil
function Commands.cmdScrollToBottom()
	Actions.smoothScroll({ y = -M.config.scrollStepFullPage })
end

---Switches to passthrough mode
---@return nil
function Commands.cmdPassthroughMode()
	local prevMode = State.mode

	if prevMode == MODES.PASSTHROUGH then
		return
	end

	ModeManager.setMode(MODES.PASSTHROUGH)
end

---Switches to insert mode
---@return nil
function Commands.cmdInsertMode()
	local prevMode = State.mode

	if prevMode == MODES.INSERT then
		return
	end

	ModeManager.setMode(MODES.INSERT)

	if
		prevMode == MODES.NORMAL
		and M.config.enterEditableCallback
		and type(M.config.enterEditableCallback) == "function"
	then
		log.df("called enterEditableCallback()")
		M.config.enterEditableCallback()
	end
end

---Switches to normal mode
---@return nil
function Commands.cmdNormalMode()
	local prevMode = State.mode

	if prevMode == MODES.NORMAL then
		return
	end

	ModeManager.setMode(MODES.NORMAL)

	if
		prevMode == MODES.INSERT
		and M.config.exitEditableCallback
		and type(M.config.exitEditableCallback) == "function"
	then
		log.df("called exitEditableCallback()")
		M.config.exitEditableCallback()
	end
end

---Switches to links mode
---@return nil
function Commands.cmdGotoLink()
	ModeManager.setMode(MODES.LINKS)
	State.onClickCallback = function(mark)
		local element = mark.element

		local pressOk = element:performAction("AXPress")

		if not pressOk then
			local frame = mark.frame
			if frame then
				Actions.tryClick(frame)
			end
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show({ elementType = "link" })
	end)
end

---Go to input mode
---@return nil
function Commands.cmdGotoInput()
	ModeManager.setMode(MODES.LINKS)
	State.onClickCallback = function(mark)
		local element = mark.element

		local pressOk = element:performAction("AXPress")

		if pressOk then
			local focused = Utils.getAttribute(element, "AXFocused")
			if not focused then
				Actions.tryClick(mark.frame)
				return
			end
		end

		Actions.tryClick(mark.frame)
	end
	hs.timer.doAfter(0, function()
		Marks.show({ elementType = "input" })
	end)
end

---Right click
---@return nil
function Commands.cmdRightClick()
	ModeManager.setMode(MODES.LINKS)
	State.onClickCallback = function(mark)
		local element = mark.element

		local pressOk = element:performAction("AXShowMenu")

		if not pressOk then
			local frame = mark.frame
			if frame then
				Actions.tryClick(frame, { type = "right" })
			end
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show({ elementType = "link" })
	end)
end

---Go to link in new tab
---@return nil
function Commands.cmdGotoLinkNewTab()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	ModeManager.setMode(MODES.LINKS)
	State.onClickCallback = function(mark)
		local url = Utils.getAttribute(mark.element, "AXURL")
		if url then
			Actions.openUrlInNewTab(url.url)
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show({ elementType = "link", withUrls = true })
	end)
end

---Download image
---@return nil
function Commands.cmdDownloadImage()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	ModeManager.setMode(MODES.LINKS)
	State.onClickCallback = function(mark)
		local element = mark.element
		local role = Utils.getAttribute(element, "AXRole")

		if role == "AXImage" then
			local description = Utils.getAttribute(element, "AXDescription")
				or "image"

			local downloadUrlAttr = Utils.getAttribute(element, "AXURL")

			if downloadUrlAttr then
				local url = downloadUrlAttr.url

				if url and url:match("^data:image/") then
					-- Handle base64 images
					local base64Data =
						url:match("^data:image/[^;]+;base64,(.+)$")
					if base64Data then
						local decodedData = hs.base64.decode(base64Data)
						---@diagnostic disable-next-line: param-type-mismatch
						local fileName = description:gsub("%W+", "_") .. ".jpg"
						local filePath = os.getenv("HOME")
							.. "/Downloads/"
							.. fileName

						local file = io.open(filePath, "wb")
						if file then
							file:write(decodedData)
							file:close()
							hs.alert.show(
								"Image saved: " .. fileName,
								nil,
								nil,
								2
							)
						end
					end
				else
					-- Handle regular URLs
					hs.http.asyncGet(url, nil, function(status, body, headers)
						if status == 200 then
							local contentType = headers["Content-Type"] or ""
							if contentType:match("^image/") then
								local fileName = url:match("^.+/(.+)$")
									or "image.jpg"
								if not fileName:match("%.%w+$") then
									fileName = fileName .. ".jpg"
								end

								local filePath = os.getenv("HOME")
									.. "/Downloads/"
									.. fileName
								local file = io.open(filePath, "wb")
								if file then
									file:write(body)
									file:close()
									hs.alert.show(
										"Image downloaded: " .. fileName,
										nil,
										nil,
										2
									)
								end
							end
						end
					end)
				end
			end
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show({ elementType = "image" })
	end)
end

---Move mouse to link
---@return nil
function Commands.cmdMoveMouseToLink()
	ModeManager.setMode(MODES.LINKS)
	State.onClickCallback = function(mark)
		local frame = mark.frame
		if frame then
			hs.mouse.absolutePosition({
				x = frame.x + frame.w / 2,
				y = frame.y + frame.h / 2,
			})
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show({ elementType = "link" })
	end)
end

---Copy link URL to clipboard
---@return nil
function Commands.cmdCopyLinkUrlToClipboard()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	ModeManager.setMode(MODES.LINKS)
	State.onClickCallback = function(mark)
		local url = Utils.getAttribute(mark.element, "AXURL")
		if url then
			Actions.setClipboardContents(url.url)
		else
			hs.alert.show("No URL found", nil, nil, 2)
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show({ elementType = "link", withUrls = true })
	end)
end

---Next page
---@return nil
function Commands.cmdNextPage()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local axWindow = Elements.getAxWindow()
	if not axWindow then
		return
	end

	local function _callback(elements)
		if #elements > 0 then
			elements[1]:performAction("AXPress")
		else
			hs.alert.show("No next button found", nil, nil, 2)
		end
	end

	ElementFinder.findNextButtonElements(axWindow, {
		callback = _callback,
	})
end

---Prev page
---@return nil
function Commands.cmdPrevPage()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local axWindow = Elements.getAxWindow()
	if not axWindow then
		return
	end

	local function _callback(elements)
		if #elements > 0 then
			elements[1]:performAction("AXPress")
		else
			hs.alert.show("No previous button found", nil, nil, 2)
		end
	end

	ElementFinder.findPrevButtonElements(axWindow, { callback = _callback })
end

---Copy page URL to clipboard
---@return nil
function Commands.cmdCopyPageUrlToClipboard()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local axWebArea = Elements.getAxWebArea()
	local url = axWebArea and Utils.getAttribute(axWebArea, "AXURL")
	if url then
		Actions.setClipboardContents(url.url)
	end
end

---Move mouse to center
---@return nil
function Commands.cmdMoveMouseToCenter()
	local window = Elements.getWindow()
	if not window then
		return
	end

	local frame = window:frame()
	hs.mouse.absolutePosition({
		x = frame.x + frame.w / 2,
		y = frame.y + frame.h / 2,
	})
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

---@class Hs.Vimnav.EventHandler.HandleVimInputOpts
---@field modifiers? table

---Handles Vim input
---@param char string
---@param opts? Hs.Vimnav.EventHandler.HandleVimInputOpts
---@return nil
local function handleVimInput(char, opts)
	opts = opts or {}
	local modifiers = opts.modifiers

	log.df(
		"handleVimInput: " .. char .. " modifiers: " .. hs.inspect(modifiers)
	)

	Utils.clearCache()

	if State.mode == MODES.LINKS then
		if char == "backspace" then
			if #State.linkCapture > 0 then
				State.linkCapture = State.linkCapture:sub(1, -2)
				Marks.draw()
			end
			return
		end

		State.linkCapture = State.linkCapture .. char:upper()

		-- Check for exact match
		for i, _ in ipairs(State.marks) do
			if i > #State.allCombinations then
				break
			end

			local markText = State.allCombinations[i]:upper()
			if markText == State.linkCapture then
				Marks.click(markText:lower())
				Commands.cmdNormalMode()
				return
			end
		end

		-- Check for partial matches
		local hasPartialMatches = false
		for i, _ in ipairs(State.marks) do
			if i > #State.allCombinations then
				break
			end

			local markText = State.allCombinations[i]:upper()
			if markText:sub(1, #State.linkCapture) == State.linkCapture then
				hasPartialMatches = true
				break
			end
		end

		if not hasPartialMatches then
			State.linkCapture = ""
		end

		Marks.draw()
		return
	end

	-- Build key combination
	local keyCombo = ""
	if modifiers and modifiers.ctrl then
		keyCombo = "C-"
	end
	keyCombo = keyCombo .. char

	if State.mode == MODES.MULTI then
		keyCombo = State.multi .. keyCombo
	end

	-- Execute mapping
	local mapping = M.config.mapping[keyCombo]
	if mapping then
		Commands.cmdNormalMode()

		if type(mapping) == "string" then
			local cmd = Commands[mapping]
			if cmd then
				cmd()
			else
				log.wf("Unknown command: " .. mapping)
			end
		elseif type(mapping) == "table" then
			Utils.keyStroke(mapping[1], mapping[2])
		end
	elseif State.mappingPrefixes[keyCombo] then
		ModeManager.setMode(MODES.MULTI, keyCombo)
	end
end

---Handles events
---@param event table
---@return boolean
local function eventHandler(event)
	local keyCode = event:getKeyCode()

	if
		State.mode == MODES.PASSTHROUGH
		and keyCode ~= hs.keycodes.map["escape"]
	then
		log.df("Skipping event handler in passthrough mode")
		return false
	end

	if State.mode == MODES.INSERT and keyCode ~= hs.keycodes.map["escape"] then
		log.df("Skipping event handler in insert mode")
		return false
	end

	-- Skip if on places that it shouldn't run
	-- - At configured exclusions
	-- - During launchers
	if Utils.isExcludedApp() or Utils.isLauncherActive() then
		log.df("Skipping event handler on excluded app or launcher")
		return false
	end

	-- Handle single and double escape key
	if keyCode == hs.keycodes.map["escape"] then
		local delaySinceLastEscape = (
			hs.timer.absoluteTime() - State.lastEscape
		) / 1e9
		State.lastEscape = hs.timer.absoluteTime()

		-- Double escape key
		if
			Utils.isInBrowser()
			and delaySinceLastEscape < M.config.doublePressDelay
		then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				Commands.cmdNormalMode()
			end)
			return true
		end

		-- Single escape key
		-- Do not allow escape on normal mode and insert mode, the rest should go through
		if State.mode ~= MODES.NORMAL and State.mode ~= MODES.INSERT then
			Commands.cmdNormalMode()
			return true
		end

		return false
	end

	local flags = event:getFlags()

	-- Handle backspace in LINKS mode
	if State.mode == MODES.LINKS and keyCode == hs.keycodes.map["delete"] then
		handleVimInput("backspace")
		return true
	end

	for key, modifier in pairs(flags) do
		if modifier and key ~= "shift" and key ~= "ctrl" then
			return false
		end
	end

	local char = hs.keycodes.map[keyCode]

	if flags.shift then
		char = event:getCharacters()
	end

	-- Only handle single alphanumeric characters and some symbols
	if not char:match("[%a%d%[%]%$]") or #char ~= 1 then
		return false
	end

	if flags.ctrl then
		local filteredMappings = {}

		for _key, _ in pairs(M.config.mapping) do
			if _key:sub(1, 2) == "C-" then
				table.insert(filteredMappings, _key:sub(3))
			end
		end

		if Utils.tblContains(filteredMappings, char) == false then
			return false
		end
	end

	handleVimInput(char, {
		modifiers = flags,
	})

	return true
end

--------------------------------------------------------------------------------
-- Watchers
--------------------------------------------------------------------------------

---Clears all caches and state when switching apps
---@return nil
local function cleanupOnAppSwitch()
	-- Clear all element caches
	Utils.clearCache()

	-- Clear any active marks and canvas
	Marks.clear()

	-- Reset link capture state
	State.linkCapture = ""

	-- Reset focus state
	State.focusLastCheck = 0
	State.focusCachedResult = false
	State.focusLastElement = nil

	-- Force garbage collection to free up memory
	collectgarbage("collect")

	log.df("Cleaned up caches and state for app switch")
end

local focusCheckTimer = nil

---Updates focus state (called by timer)
---@return nil
local function updateFocusState()
	Utils.clearCache()

	local focusedElement = Elements.getAxFocusedElement()

	-- Quick check: if same element, skip
	if focusedElement == State.focusLastElement then
		return
	end

	State.focusLastElement = focusedElement

	if focusedElement then
		local role = Utils.getAttribute(focusedElement, "AXRole")
		local isEditable = role and RoleMaps.isEditable(role) or false

		if isEditable ~= State.focusCachedResult then
			State.focusCachedResult = isEditable

			-- Update mode based on focus change
			if isEditable and State.mode == MODES.NORMAL then
				Commands.cmdInsertMode()
			elseif not isEditable and State.mode == MODES.INSERT then
				Commands.cmdNormalMode()
			end

			log.df(
				"Focus changed: editable="
					.. tostring(isEditable)
					.. ", role="
					.. tostring(role)
			)
		end
	else
		if State.focusCachedResult then
			State.focusCachedResult = false
			if State.mode == MODES.INSERT then
				Commands.cmdNormalMode()
			end
		end
	end
end

---Starts focus polling
---@return nil
local function startFocusPolling()
	if focusCheckTimer then
		focusCheckTimer:stop()
		focusCheckTimer = nil
	end

	focusCheckTimer = hs.timer
		.new(M.config.focusCheckInterval or 0.1, function()
			pcall(updateFocusState)
		end)
		:start()

	log.df("Focus polling started")
end

local appWatcher = nil

---Starts the app watcher
---@return nil
local function startAppWatcher()
	if appWatcher then
		appWatcher:stop()
		appWatcher = nil
	end

	startFocusPolling()

	appWatcher = hs.application.watcher.new(function(appName, eventType)
		log.df(string.format("App event: %s - %s", appName, eventType))

		if eventType == hs.application.watcher.activated then
			log.df(string.format("App activated: %s", appName))

			cleanupOnAppSwitch()

			startFocusPolling()

			if not State.eventLoop then
				State.eventLoop = hs.eventtap
					.new({ hs.eventtap.event.types.keyDown }, eventHandler)
					:start()
				log.df("Started event loop")
			end

			if Utils.tblContains(M.config.excludedApps, appName) then
				ModeManager.setMode(MODES.DISABLED)
				log.df("Disabled mode for excluded app: " .. appName)
			else
				Commands.cmdNormalMode()
			end
		end
	end)

	appWatcher:start()

	log.df("App watcher started")
end

---Periodic cache cleanup to prevent memory leaks
---@return nil
local function setupPeriodicCleanup()
	if State.cleanupTimer then
		State.cleanupTimer:stop()
	end

	State.cleanupTimer = hs.timer
		.new(30, function() -- Every 30 seconds
			-- Only clean up if we're not actively showing marks
			if State.mode ~= MODES.LINKS then
				Utils.clearCache()
				collectgarbage("collect")
				log.df("Periodic cache cleanup completed")
			end
		end)
		:start()
end

---Clean up timers and watchers
---@return nil
local function cleanupWatchers()
	if appWatcher then
		appWatcher:stop()
		appWatcher = nil
		log.df("Stopped app watcher")
	end

	if State.cleanupTimer then
		State.cleanupTimer:stop()
		State.cleanupTimer = nil
		log.df("Stopped cleanup timer")
	end

	if focusCheckTimer then
		focusCheckTimer:stop()
		focusCheckTimer = nil
		log.df("Stopped focus check timer")
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@type Hs.Vimnav.Config
---@diagnostic disable-next-line: missing-fields
M.config = {}

---Starts the module
---@param userConfig Hs.Vimnav.Config
---@return nil
function M:start(userConfig)
	print("-- Starting Vimnav...")
	M.config = Utils.tblDeepExtend("force", DEFAULT_CONFIG, userConfig or {})

	log = hs.logger.new(M.name, M.config.logLevel)

	Utils.fetchMappingPrefixes()
	Utils.generateCombinations()
	RoleMaps.init() -- Initialize role maps for performance

	cleanupWatchers()
	startAppWatcher()
	setupPeriodicCleanup()
	MenuBar.create()

	local currentApp = Elements.getApp()
	if
		currentApp
		and Utils.tblContains(M.config.excludedApps, currentApp:name())
	then
		ModeManager.setMode(MODES.DISABLED)
	else
		Commands.cmdNormalMode()
	end
end

---Stops the module
---@return nil
function M:stop()
	print("-- Stopping Vimnav...")

	cleanupWatchers()

	if State.eventLoop then
		State.eventLoop:stop()
		State.eventLoop = nil
		log.df("Stopped event loop")
	end

	MenuBar.destroy()
	Marks.clear()

	cleanupOnAppSwitch()
end

return M
