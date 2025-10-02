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

M.name = "Vimnav"
M.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal modules
local Utils = {}
local Elements = {}
local MenuBar = {}
local Overlay = {}
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
local EventHandler = {}

local log

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

---@class Hs.Vimnav.Config
---@field logLevel? string Log level to show in the console
---@field hints? Hs.Vimnav.Config.Hints Settings for hints
---@field focusCheckInterval? number Focus check interval in seconds (e.g. 0.5 for 500ms)
---@field mapping? Hs.Vimnav.Config.Mapping Mappings to use
---@field scroll? Hs.Vimnav.Config.Scroll Scroll settings
---@field axRoles? Hs.Vimnav.Config.AxRoles Roles to use for AXUIElement
---@field applicationGroups? Hs.Vimnav.Config.ApplicationGroups App groups to work with vimnav
---@field menubar? Hs.Vimnav.Config.Menubar Configure menubar indicator
---@field overlay? Hs.Vimnav.Config.Overlay Configure overlay indicator

---@class Hs.Vimnav.Config.ApplicationGroups
---@field exclusions? string[] Apps to exclude from Vimnav (e.g. Terminal)
---@field browsers? string[] Browsers to to detect for browser specific actions (e.g. Safari)
---@field launchers? string[] Launchers to to detect for launcher specific actions (e.g. Spotlight)

---@class Hs.Vimnav.Config.AxRoles
---@field editable? string[] Roles for detect editable inputs
---@field jumpable? string[] Roles for detect jumpable inputs (links and more)

---@class Hs.Vimnav.Config.Hints
---@field chars? string Link hint characters
---@field fontSize? number Font size for link hints
---@field depth? number Maximum depth to search for elements

---@class Hs.Vimnav.Config.Scroll
---@field scrollStep? number Scroll step in pixels
---@field scrollStepHalfPage? number Scroll step in pixels for half page
---@field scrollStepFullPage? number Scroll step in pixels for full page
---@field smoothScroll? boolean Enable/disable smooth scrolling
---@field smoothScrollFramerate? number Smooth scroll framerate in frames per second

---@class Hs.Vimnav.Config.Menubar
---@field enabled? boolean Enable menubar indicator

---@class Hs.Vimnav.Config.Overlay
---@field enabled? boolean Enable overlay mode indicator
---@field position? "top-left"|"top-center"|"top-right"|"bottom-left"|"bottom-center"|"bottom-right"|"left-top"|"left-center"|"left-bottom"|"right-top"|"right-center"|"right-bottom" Position of overlay indicator
---@field size? number Size of overlay indicator in pixels
---@field padding? number Padding of overlay indicator in pixels from the screen frame
---@field colors? Hs.Vimnav.Config.Overlay.Colors Colors of overlay indicator

---@class Hs.Vimnav.Config.Overlay.Colors
---@field disabled? string Color of disabled mode indicator
---@field normal? string Color of normal mode indicator
---@field insert? string Color of insert mode indicator
---@field insertNormal? string Color of insert normal mode indicator
---@field insertVisual? string Color of insert visual mode indicator
---@field links? string Color of links mode indicator
---@field passthrough? string Color of passthrough mode indicator

---@class Hs.Vimnav.Config.Mapping
---@field normal? table<string, string|table|function|"noop"> Normal mode mappings
---@field insertNormal? table<string, string|table|function|"noop"> Insert normal mode mappings
---@field insertVisual? table<string, string|table|function|"noop"> Insert visual mode mappings

---@class Hs.Vimnav.State
---@field mode number Vimnav mode
---@field keyCapture string|nil Multi character input
---@field marks table<number, table<string, table|nil>> Marks
---@field linkCapture string Link capture state
---@field lastEscape number Last escape key press time
---@field mappingPrefixes Hs.Vimnav.State.MappingPrefixes Mapping prefixes
---@field allCombinations string[] All combinations
---@field eventLoop table|nil Event loop
---@field canvas table|nil Canvas
---@field onClickCallback fun(any)|nil On click callback for marks
---@field cleanupTimer table|nil Cleanup timer
---@field focusCachedResult boolean Focus cached result
---@field focusLastElement table|string|nil Focus last element
---@field maxElements number Maximum elements to search for (derived from config)

---@class Hs.Vimnav.State.MappingPrefixes
---@field normal table<string, boolean> Normal mode mappings
---@field insertNormal table<string, boolean> Insert normal mode mappings
---@field insertVisual table<string, boolean> Insert visual mode mappings

---@alias Hs.Vimnav.Element table|string

---@alias Hs.Vimnav.Modifier "cmd"|"ctrl"|"alt"|"shift"|"fn"

--------------------------------------------------------------------------------
-- Constants and Configuration
--------------------------------------------------------------------------------

local MODES = {
	DISABLED = 1,
	NORMAL = 2,
	INSERT = 3,
	INSERT_NORMAL = 4,
	INSERT_VISUAL = 5,
	LINKS = 6,
	PASSTHROUGH = 7,
}

local defaultModeChars = {
	[MODES.DISABLED] = "X",
	[MODES.INSERT] = "I",
	[MODES.INSERT_NORMAL] = "IN",
	[MODES.INSERT_VISUAL] = "IV",
	[MODES.LINKS] = "L",
	[MODES.NORMAL] = "N",
	[MODES.PASSTHROUGH] = "P",
}

local DEFAULT_MAPPING = {
	normal = {
		-- modes
		["i"] = "enterPassthroughMode",
		-- scrolls
		["h"] = "scrollLeft",
		["j"] = "scrollDown",
		["k"] = "scrollUp",
		["l"] = "scrollRight",
		["C-d"] = "scrollHalfPageDown",
		["C-u"] = "scrollHalfPageUp",
		["G"] = "scrollToBottom",
		["gg"] = "scrollToTop",
		-- go back/forward
		["H"] = { "cmd", "[" },
		["L"] = { "cmd", "]" },
		-- hints click
		["f"] = "gotoLink",
		["r"] = "rightClick",
		["F"] = "gotoLinkNewTab",
		["di"] = "downloadImage",
		["gi"] = "gotoInput",
		["yf"] = "copyLinkUrlToClipboard",
		["gf"] = "moveMouseToLink",
		-- move mouse
		["zz"] = "moveMouseToCenter",
		-- copy page url
		["yy"] = "copyPageUrlToClipboard",
		-- next/prev page
		["]]"] = "gotoNextPage",
		["[["] = "gotoPrevPage",
		-- searches
		["/"] = { "cmd", "f" },
		["n"] = { "cmd", "g" },
		["N"] = { { "cmd", "shift" }, "g" },
	},
	insertNormal = {
		-- movements
		["h"] = { {}, "left" },
		["j"] = { {}, "down" },
		["k"] = { {}, "up" },
		["l"] = { {}, "right" },
		["e"] = { "alt", "right" },
		["b"] = { "alt", "left" },
		["0"] = { "cmd", "left" },
		["$"] = { "cmd", "right" },
		["gg"] = { "cmd", "up" },
		["G"] = { "cmd", "down" },
		-- edits
		["diw"] = "deleteWord",
		["ciw"] = "changeWord",
		["yiw"] = "yankWord",
		["dd"] = "deleteLine",
		["cc"] = "changeLine",
		-- yank and paste
		["yy"] = "yankLine",
		["p"] = { "cmd", "v" },
		-- undo/redo
		["u"] = { "cmd", "z" },
		["C-r"] = { { "cmd", "shift" }, "z" },
		-- modes
		["i"] = "enterInsertMode",
		["o"] = "enterInsertModeNewLineBelow",
		["O"] = "enterInsertModeNewLineAbove",
		["A"] = "enterInsertModeEndOfLine",
		["I"] = "enterInsertModeStartLine",
		["v"] = "enterInsertVisualMode",
		["V"] = "enterInsertVisualLineMode",
	},
	insertVisual = {
		-- movements
		["h"] = { { "shift" }, "left" },
		["j"] = { { "shift" }, "down" },
		["k"] = { { "shift" }, "up" },
		["l"] = { { "shift" }, "right" },
		["e"] = { { "shift", "alt" }, "right" },
		["b"] = { { "shift", "alt" }, "left" },
		["0"] = { { "shift", "cmd" }, "left" },
		["$"] = { { "shift", "cmd" }, "right" },
		["gg"] = { { "shift", "cmd" }, "up" },
		["G"] = { { "shift", "cmd" }, "down" },
		-- edits
		["d"] = "deleteHighlighted",
		["c"] = "changeHighlighted",
		-- yank
		["y"] = "yankHighlighted",
	},
}

---@type Hs.Vimnav.Config
local DEFAULT_CONFIG = {
	logLevel = "warning",
	hints = {
		chars = "abcdefghijklmnopqrstuvwxyz",
		fontSize = 12,
		depth = 20,
	},
	focusCheckInterval = 0.1,
	mapping = DEFAULT_MAPPING,
	scroll = {
		scrollStep = 50,
		scrollStepHalfPage = 500,
		scrollStepFullPage = 1e6,
		smoothScroll = true,
		smoothScrollFramerate = 120,
	},
	axRoles = {
		editable = {
			"AXTextField",
			"AXComboBox",
			"AXTextArea",
			"AXSearchField",
		},
		jumpable = {
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
	},
	applicationGroups = {
		exclusions = {
			"Terminal",
			"Alacritty",
			"iTerm2",
			"Kitty",
			"Ghostty",
		},
		browsers = {
			"Safari",
			"Google Chrome",
			"Firefox",
			"Microsoft Edge",
			"Brave Browser",
			"Zen",
		},
		launchers = { "Spotlight", "Raycast", "Alfred" },
	},
	menubar = {
		enabled = true,
	},
	overlay = {
		enabled = false,
		position = "top-center",
		size = 25,
		padding = 2,
		colors = {
			disabled = "#5a5672",
			normal = "#80b8e8",
			insert = "#abe9b3",
			insertNormal = "#f9e2af",
			insertVisual = "#c9a0e9",
			links = "#f8bd96",
			passthrough = "#f28fad",
		},
	},
}

--------------------------------------------------------------------------------
-- State Management
--------------------------------------------------------------------------------

---@type Hs.Vimnav.State
local defaultState = {
	mode = MODES.DISABLED,
	keyCapture = nil,
	marks = {},
	linkCapture = "",
	lastEscape = 0,
	mappingPrefixes = {},
	allCombinations = {},
	eventLoop = nil,
	canvas = nil,
	onClickCallback = nil,
	cleanupTimer = nil,
	focusCachedResult = false,
	focusLastElement = nil,
	maxElements = 0,
}

---@type Hs.Vimnav.State
---@diagnostic disable-next-line: missing-fields
State = {}

local function resetState()
	State = defaultState
end

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

	if depth > M.config.hints.depth then
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
	for _, role in ipairs(M.config.axRoles.jumpable) do
		RoleMaps.jumpableSet[role] = true
	end

	RoleMaps.editableSet = {}
	for _, role in ipairs(M.config.axRoles.editable) do
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
			textSize = M.config.hints.fontSize,
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

---Merges two tables with optional array extension
---@param base table Base table
---@param overlay table Table to merge into base
---@param extendArrays boolean If true, arrays are merged; if false, arrays are replaced
---@return table Merged result
function Utils.tblMerge(base, overlay, extendArrays)
	local result = Utils.deepCopy(base)

	for key, value in pairs(overlay) do
		local baseValue = result[key]
		local isOverlayArray = type(value) == "table" and Utils.isList(value)
		local isBaseArray = type(baseValue) == "table"
			and Utils.isList(baseValue)

		if extendArrays and isOverlayArray and isBaseArray then
			-- both are arrays: merge without duplicates
			for _, v in ipairs(value) do
				if not Utils.tblContains(baseValue, v) then
					table.insert(baseValue, v)
				end
			end
		elseif type(value) == "table" and type(baseValue) == "table" then
			-- both are tables (objects or mixed): recurse
			result[key] = Utils.tblMerge(baseValue, value, extendArrays)
		else
			-- plain value or type mismatch: replace
			result[key] = Utils.deepCopy(value)
		end
	end

	return result
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

	local chars = M.config.hints.chars

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
	State.mappingPrefixes.normal = {}
	State.mappingPrefixes.insertNormal = {}
	State.mappingPrefixes.insertVisual = {}

	for k, v in pairs(M.config.mapping.normal) do
		if v == "noop" then
			goto continue
		end
		if #k == 2 then
			State.mappingPrefixes.normal[string.sub(k, 1, 1)] = true
		end
		::continue::
	end

	for k, v in pairs(M.config.mapping.insertNormal) do
		if v == "noop" then
			goto continue
		end
		if #k == 2 then
			State.mappingPrefixes.insertNormal[string.sub(k, 1, 1)] = true
		end
		if #k == 3 then
			State.mappingPrefixes.insertNormal[string.sub(k, 1, 1)] = true
			State.mappingPrefixes.insertNormal[string.sub(k, 1, 2)] = true
		end
		::continue::
	end

	for k, _ in pairs(M.config.mapping.insertVisual) do
		if v == "noop" then
			goto continue
		end
		if #k == 2 then
			State.mappingPrefixes.insertVisual[string.sub(k, 1, 1)] = true
		end
		::continue::
	end

	log.df("Fetched mapping prefixes")
end

---Checks if the application is in the browser list
---@return boolean
function Utils.isInBrowser()
	local app = Elements.getApp()
	return app
			and Utils.tblContains(
				M.config.applicationGroups.browsers,
				app:name()
			)
		or false
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
	if not M.config.menubar.enabled then
		return
	end

	if MenuBar.item then
		MenuBar.destroy()
	end
	MenuBar.item = hs.menubar.new()
	MenuBar.item:setTitle(defaultModeChars[MODES.NORMAL])
	log.df("Created menu bar item")
end

---Set the menubar title
---@param mode number
---@param keys string|nil
function MenuBar.setTitle(mode, keys)
	if not M.config.menubar.enabled or not MenuBar.item then
		return
	end

	local modeChar = defaultModeChars[mode] or "?"

	local toDisplayModeChar = modeChar

	if keys then
		toDisplayModeChar = string.format("%s [%s]", modeChar, keys)
	end

	MenuBar.item:setTitle(toDisplayModeChar)
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
-- Overlay Indicator
--------------------------------------------------------------------------------

---Creates the overlay indicator
---@return nil
function Overlay.create()
	if not M.config.overlay.enabled then
		return
	end

	if Overlay.canvas then
		Overlay.destroy()
	end

	local screen = hs.screen.mainScreen()
	local frame = screen:fullFrame()
	local height = M.config.overlay.size or 30
	local position = M.config.overlay.position or "top-center"

	-- Start with a default width, will be adjusted when text is set
	local initialWidth = height * 2

	local overlayFrame

	-- Parse position string
	local parts = {}
	for part in position:gmatch("[^-]+") do
		table.insert(parts, part)
	end

	local edge = parts[1] -- top, bottom, left, right
	local alignment = parts[2] -- left, center, right, top, bottom

	local padding = M.config.overlay.padding

	if edge == "top" then
		if alignment == "left" then
			overlayFrame = {
				x = frame.x + padding,
				y = frame.y + padding,
				w = initialWidth,
				h = height,
			}
		elseif alignment == "center" then
			overlayFrame = {
				x = frame.x + (frame.w / 2) - (initialWidth / 2),
				y = frame.y + padding,
				w = initialWidth,
				h = height,
			}
		elseif alignment == "right" then
			overlayFrame = {
				x = frame.x + frame.w - initialWidth - padding,
				y = frame.y + padding,
				w = initialWidth,
				h = height,
			}
		end
	elseif edge == "bottom" then
		if alignment == "left" then
			overlayFrame = {
				x = frame.x + padding,
				y = frame.y + frame.h - height - padding,
				w = initialWidth,
				h = height,
			}
		elseif alignment == "center" then
			overlayFrame = {
				x = frame.x + (frame.w / 2) - (initialWidth / 2),
				y = frame.y + frame.h - height - padding,
				w = initialWidth,
				h = height,
			}
		elseif alignment == "right" then
			overlayFrame = {
				x = frame.x + frame.w - initialWidth - padding,
				y = frame.y + frame.h - height - padding,
				w = initialWidth,
				h = height,
			}
		end
	elseif edge == "left" then
		if alignment == "top" then
			overlayFrame = {
				x = frame.x + padding,
				y = frame.y + padding,
				w = initialWidth,
				h = height,
			}
		elseif alignment == "center" then
			overlayFrame = {
				x = frame.x + padding,
				y = frame.y + (frame.h / 2) - (height / 2),
				w = initialWidth,
				h = height,
			}
		elseif alignment == "bottom" then
			overlayFrame = {
				x = frame.x + padding,
				y = frame.y + frame.h - height - padding,
				w = initialWidth,
				h = height,
			}
		end
	elseif edge == "right" then
		if alignment == "top" then
			overlayFrame = {
				x = frame.x + frame.w - initialWidth - padding,
				y = frame.y + padding,
				w = initialWidth,
				h = height,
			}
		elseif alignment == "center" then
			overlayFrame = {
				x = frame.x + frame.w - initialWidth - padding,
				y = frame.y + (frame.h / 2) - (height / 2),
				w = initialWidth,
				h = height,
			}
		elseif alignment == "bottom" then
			overlayFrame = {
				x = frame.x + frame.w - initialWidth - padding,
				y = frame.y + frame.h - height - padding,
				w = initialWidth,
				h = height,
			}
		end
	end

	Overlay.canvas = hs.canvas.new(overlayFrame)
	Overlay.canvas:level("overlay")
	Overlay.canvas:behavior("canJoinAllSpaces")

	log.df("Created overlay indicator at " .. position)
end

---Convert hex to RGB table
---@param hex string
---@return table
local function hexToRgb(hex)
	hex = hex:gsub("#", "")
	return {
		red = tonumber("0x" .. hex:sub(1, 2)) / 255,
		green = tonumber("0x" .. hex:sub(3, 4)) / 255,
		blue = tonumber("0x" .. hex:sub(5, 6)) / 255,
	}
end

---Get color for mode
---@param mode number
---@return table
function Overlay.getModeColor(mode)
	local colors = {
		[MODES.DISABLED] = hexToRgb(
			M.config.overlay.colors.disabled or "#5a5672"
		),
		[MODES.NORMAL] = hexToRgb(M.config.overlay.colors.normal or "#80b8e8"),
		[MODES.INSERT] = hexToRgb(M.config.overlay.colors.insert or "#abe9b3"),
		[MODES.INSERT_NORMAL] = hexToRgb(
			M.config.overlay.colors.insertNormal or "#f9e2af"
		),
		[MODES.INSERT_VISUAL] = hexToRgb(
			M.config.overlay.colors.insertVisual or "#c9a0e9"
		),
		[MODES.LINKS] = hexToRgb(M.config.overlay.colors.links or "#f8bd96"),
		[MODES.PASSTHROUGH] = hexToRgb(
			M.config.overlay.colors.passthrough or "#f28fad"
		),
	}
	return colors[mode]
		or hexToRgb(M.config.overlay.colors.disabled or "#5a5672")
end

---Updates the overlay indicator
---@param mode number
---@param keys? string|nil
---@return nil
function Overlay.update(mode, keys)
	if not M.config.overlay.enabled or not Overlay.canvas then
		return
	end

	local color = Overlay.getModeColor(mode)
	local modeChar = defaultModeChars[mode] or "?"
	local fontSize = M.config.overlay.size / 2
	local padding = 0

	-- Build display text
	local displayText = modeChar
	if keys then
		displayText = string.format("%s [%s]", modeChar, keys)
	end

	-- Calculate text width (approximate)
	local charWidth = fontSize * 0.65
	local textWidth = #displayText * charWidth
	local newWidth = textWidth + (padding * 2)

	local height = M.config.overlay.size or 30

	if newWidth < height then
		newWidth = height
	end

	-- Get current frame
	local currentFrame = Overlay.canvas:frame()
	local screen = hs.screen.mainScreen()
	local screenFrame = screen:fullFrame()
	local position = M.config.overlay.position or "top-center"

	-- Parse position
	local parts = {}
	for part in position:gmatch("[^-]+") do
		table.insert(parts, part)
	end
	local edge = parts[1]
	local alignment = parts[2]

	-- Calculate new X position based on alignment
	local newX = currentFrame.x
	if edge == "top" or edge == "bottom" then
		if alignment == "center" then
			newX = screenFrame.x + (screenFrame.w / 2) - (newWidth / 2)
		elseif alignment == "right" then
			newX = screenFrame.x + screenFrame.w - newWidth - 10
		end
	elseif edge == "left" or edge == "right" then
		if edge == "right" then
			newX = screenFrame.x + screenFrame.w - newWidth - 10
		end
	end

	-- Update canvas frame
	Overlay.canvas:frame({
		x = newX,
		y = currentFrame.y,
		w = newWidth,
		h = height,
	})

	-- Apply alpha to color
	color.alpha = 0.2
	local textColor = Overlay.getModeColor(mode)

	Overlay.canvas:replaceElements({
		{
			type = "rectangle",
			action = "fill",
			fillColor = color,
			roundedRectRadii = { xRadius = 8, yRadius = 8 },
		},
		{
			type = "text",
			text = displayText,
			textAlignment = "center",
			textColor = textColor,
			textSize = fontSize,
			textFont = ".AppleSystemUIFontBold",
			frame = {
				x = 0,
				y = (height - fontSize) / 2 - 2,
				w = newWidth,
				h = fontSize + 4,
			},
		},
	})
	Overlay.canvas:show()
end

---Destroys the overlay indicator
---@return nil
function Overlay.destroy()
	if Overlay.canvas then
		Overlay.canvas:delete()
		Overlay.canvas = nil
		log.df("Destroyed overlay indicator")
	end
end

--------------------------------------------------------------------------------
-- Mode Management
--------------------------------------------------------------------------------

---Sets the mode
---@param mode number
---@return boolean success Whether the mode was set
---@return number|nil prevMode The previous mode
function ModeManager.setMode(mode)
	if mode == State.mode then
		log.df("Mode already set to %s... abort", mode)
		return false
	end

	local previousMode = State.mode

	State.mode = mode

	MenuBar.setTitle(mode)
	Overlay.update(mode)

	log.df(string.format("Mode changed: %s -> %s", previousMode, mode))

	return true, previousMode
end

---Checks if the current mode is the given mode
---@param mode number
---@return boolean
function ModeManager.isMode(mode)
	return State.mode == mode
end

---Set mode to disabled
---@return boolean
function ModeManager.setModeDisabled()
	return ModeManager.setMode(MODES.DISABLED)
end

---Set mode to passthrough
---@return boolean
function ModeManager.setModePassthrough()
	local ok = ModeManager.setMode(MODES.PASSTHROUGH)

	if not ok then
		return false
	end

	if ok then
		hs.timer.doAfter(0, Marks.clear)
	end

	return true
end

---Set mode to links
---@return boolean
function ModeManager.setModeLink()
	local ok = ModeManager.setMode(MODES.LINKS)

	if not ok then
		return false
	end

	State.linkCapture = ""
	Marks.clear()

	return true
end

---Set mode to insert
---@return boolean
function ModeManager.setModeInsert()
	local ok = ModeManager.setMode(MODES.INSERT)

	if not ok then
		return false
	end

	hs.timer.doAfter(0, Marks.clear)

	return true
end

---Set mode to insert normal
---@return boolean
function ModeManager.setModeInsertNormal()
	local ok = ModeManager.setMode(MODES.INSERT_NORMAL)

	if not ok then
		return false
	end

	hs.timer.doAfter(0, Marks.clear)

	return true
end

---Set mode to insert visual
---@return boolean
function ModeManager.setModeInsertVisual()
	local ok = ModeManager.setMode(MODES.INSERT_VISUAL)

	if not ok then
		return false
	end

	hs.timer.doAfter(0, Marks.clear)

	return true
end

---Set mode to normal
---@return boolean
function ModeManager.setModeNormal()
	local ok = ModeManager.setMode(MODES.NORMAL)

	if not ok then
		return false
	end

	hs.timer.doAfter(0, Marks.clear)

	return true
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
	local smooth = opts.smooth or M.config.scroll.smoothScroll

	if not smooth then
		hs.eventtap.event.newScrollEvent({ x, y }, {}, "pixel"):post()
		return
	end

	local steps = 5
	local dx = x and (x / steps) or 0
	local dy = y and (y / steps) or 0
	local frame = 0
	local interval = 1 / M.config.scroll.smoothScrollFramerate

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
		State.focusCachedResult = false
		State.focusLastElement = nil
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
			ModeManager.setModeNormal()
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
				ModeManager.setModeNormal()
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
				ModeManager.setModeNormal()
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
				ModeManager.setModeNormal()
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
				local fontSize = M.config.hints.fontSize
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
				text.textSize = fontSize
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
function Commands.scrollLeft()
	Actions.smoothScroll({ x = M.config.scroll.scrollStep })
end

---Scrolls right
---@return nil
function Commands.scrollRight()
	Actions.smoothScroll({ x = -M.config.scroll.scrollStep })
end

---Scrolls up
---@return nil
function Commands.scrollUp()
	Actions.smoothScroll({ y = M.config.scroll.scrollStep })
end

---Scrolls down
---@return nil
function Commands.scrollDown()
	Actions.smoothScroll({ y = -M.config.scroll.scrollStep })
end

---Scrolls half page down
---@return nil
function Commands.scrollHalfPageDown()
	Actions.smoothScroll({ y = -M.config.scroll.scrollStepHalfPage })
end

---Scrolls half page up
---@return nil
function Commands.scrollHalfPageUp()
	Actions.smoothScroll({ y = M.config.scroll.scrollStepHalfPage })
end

---Scrolls to top
---@return nil
function Commands.scrollToTop()
	Actions.smoothScroll({ y = M.config.scroll.scrollStepFullPage })
end

---Scrolls to bottom
---@return nil
function Commands.scrollToBottom()
	Actions.smoothScroll({ y = -M.config.scroll.scrollStepFullPage })
end

---Switches to passthrough mode
---@return boolean
function Commands.enterPassthroughMode()
	return ModeManager.setModePassthrough()
end

---Switches to insert mode
---@return boolean
function Commands.enterInsertMode()
	return ModeManager.setModeInsert()
end

---Switches to insert mode and make a new line above
---@return boolean
function Commands.enterInsertModeNewLineAbove()
	Utils.keyStroke({}, "up")
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return ModeManager.setModeInsert()
end

---Switches to insert mode and make a new line below
---@return boolean
function Commands.enterInsertModeNewLineBelow()
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return ModeManager.setModeInsert()
end

---Switches to insert mode and put cursor at the end of the line
---@return boolean
function Commands.enterInsertModeEndOfLine()
	Utils.keyStroke("cmd", "right")
	return ModeManager.setModeInsert()
end

---Switches to insert mode and put cursor at the start of the line
---@return boolean
function Commands.enterInsertModeStartLine()
	Utils.keyStroke("cmd", "left")
	return ModeManager.setModeInsert()
end

---Switches to insert visual mode
---@return boolean
function Commands.enterInsertVisualMode()
	return ModeManager.setModeInsertVisual()
end

---Switches to insert visual mode with line selection
---@return boolean
function Commands.enterInsertVisualLineMode()
	Utils.keyStroke("cmd", "left")
	Utils.keyStroke({ "shift", "cmd" }, "right")

	return ModeManager.setModeInsertVisual()
end

---Switches to links mode
---@return nil
function Commands.gotoLink()
	local ok = ModeManager.setModeLink()

	if not ok then
		return
	end

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
function Commands.gotoInput()
	local ok = ModeManager.setModeLink()

	if not ok then
		return
	end

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
function Commands.rightClick()
	local ok = ModeManager.setModeLink()

	if not ok then
		return
	end

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
function Commands.gotoLinkNewTab()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = ModeManager.setModeLink()

	if not ok then
		return
	end

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
function Commands.downloadImage()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = ModeManager.setModeLink()

	if not ok then
		return
	end

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
function Commands.moveMouseToLink()
	local ok = ModeManager.setModeLink()

	if not ok then
		return
	end

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
function Commands.copyLinkUrlToClipboard()
	if not Utils.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = ModeManager.setModeLink()

	if not ok then
		return
	end

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
function Commands.gotoNextPage()
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
function Commands.gotoPrevPage()
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
function Commands.copyPageUrlToClipboard()
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
function Commands.moveMouseToCenter()
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

function Commands.deleteWord()
	Utils.keyStroke("alt", "right")
	Utils.keyStroke("alt", "delete")
end

function Commands.changeWord()
	Commands.cmdDeleteWord()
	ModeManager.setModeInsert()
end

function Commands.yankWord()
	Utils.keyStroke("alt", "right")
	Utils.keyStroke({ "shift", "alt" }, "left")
	Utils.keyStroke("cmd", "c")
	Utils.keyStroke({}, "right")
end

function Commands.deleteLine()
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("cmd", "delete")
end

function Commands.changeLine()
	Commands.cmdDeleteLine()
	ModeManager.setModeInsert()
end

function Commands.yankLine()
	Utils.keyStroke("cmd", "left")
	Utils.keyStroke({ "shift", "cmd" }, "right")
	Utils.keyStroke("cmd", "c")
	Utils.keyStroke({}, "right")
end

function Commands.deleteHighlighted()
	Utils.keyStroke({}, "delete")
end

function Commands.changeHighlighted()
	Commands.cmdDeleteHighlighted()
	ModeManager.setModeInsert()
end

function Commands.yankHighlighted()
	Utils.keyStroke("cmd", "c")
	Utils.keyStroke({}, "right")
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
function EventHandler.handleVimInput(char, opts)
	opts = opts or {}
	local modifiers = opts.modifiers

	log.df(
		"handleVimInput: " .. char .. " modifiers: " .. hs.inspect(modifiers)
	)

	Utils.clearCache()

	-- handle link capture first
	if ModeManager.isMode(MODES.LINKS) then
		State.linkCapture = State.linkCapture .. char:upper()
		for i, _ in ipairs(State.marks) do
			if i > #State.allCombinations then
				break
			end

			local markText = State.allCombinations[i]:upper()
			if markText == State.linkCapture then
				Marks.click(markText:lower())
				ModeManager.setModeNormal()
				State.keyCapture = nil
				return
			end
		end
	end

	-- Build key combination
	local keyCombo = ""
	if modifiers and modifiers.ctrl then
		keyCombo = "C-"
	end
	keyCombo = keyCombo .. char

	if State.keyCapture then
		State.keyCapture = State.keyCapture .. keyCombo
	else
		State.keyCapture = keyCombo
	end

	MenuBar.setTitle(State.mode, State.keyCapture)
	Overlay.update(State.mode, State.keyCapture)

	-- Execute mapping
	local mapping
	local prefixes

	if ModeManager.isMode(MODES.NORMAL) then
		mapping = M.config.mapping.normal[State.keyCapture]
		prefixes = State.mappingPrefixes.normal
	end

	if ModeManager.isMode(MODES.INSERT_NORMAL) then
		mapping = M.config.mapping.insertNormal[State.keyCapture]
		prefixes = State.mappingPrefixes.insertNormal
	end

	if ModeManager.isMode(MODES.INSERT_VISUAL) then
		mapping = M.config.mapping.insertVisual[State.keyCapture]
		prefixes = State.mappingPrefixes.insertVisual
	end

	if mapping then
		if type(mapping) == "string" then
			if mapping == "noop" then
				log.df("No mapping")
			else
				local cmd = Commands[mapping]
				if cmd then
					cmd()
				else
					log.wf("Unknown command: " .. mapping)
				end
			end
		elseif type(mapping) == "table" then
			Utils.keyStroke(mapping[1], mapping[2])
		elseif type(mapping) == "function" then
			mapping()
		end
		State.keyCapture = nil
	elseif prefixes and prefixes[State.keyCapture] then
		log.df("Found prefix: " .. State.keyCapture)
	else
		State.keyCapture = nil
	end
end

---Checks if the key is a valid key for the given name
---@param keyCode number
---@param name string
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.isKey(keyCode, name)
	return keyCode == hs.keycodes.map[name]
end

function EventHandler.isShiftEspace(event)
	local flags = event:getFlags()
	return flags.shift and EventHandler.isKey(event:getKeyCode(), "escape")
end

function EventHandler.isEspace(event)
	return EventHandler.isKey(event:getKeyCode(), "escape")
end

---Handles disabled mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleDisabledMode(event)
	return false
end

---Handles passthrough mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handlePassthroughMode(event)
	if EventHandler.isShiftEspace(event) then
		ModeManager.setModeNormal()
		return true
	end

	return false
end

---Handles insert mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertMode(event)
	if EventHandler.isShiftEspace(event) then
		if Utils.isInBrowser() then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				ModeManager.setModeNormal()
			end)
		end
		return true
	end

	if EventHandler.isEspace(event) then
		ModeManager.setModeInsertNormal()
		return true
	end

	return false
end

---Handles insert normal mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertNormalMode(event)
	if EventHandler.isShiftEspace(event) then
		if Utils.isInBrowser() then
			Actions.forceUnfocus()
			hs.timer.doAfter(0.1, function()
				ModeManager.setModeNormal()
			end)
		end
		return true
	end

	return EventHandler.processVimInput(event)
end

---Handles insert visual mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertVisualMode(event)
	if EventHandler.isShiftEspace(event) then
		if Utils.isInBrowser() then
			Utils.keyStroke({}, "left")
			hs.timer.doAfter(0.1, function()
				Actions.forceUnfocus()
			end)
			hs.timer.doAfter(0.1, function()
				ModeManager.setModeNormal()
			end)
		end
		return true
	end

	if EventHandler.isEspace(event) then
		Utils.keyStroke({}, "right")
		ModeManager.setModeInsertNormal()
		return true
	end

	return EventHandler.processVimInput(event)
end

---Handles links mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleLinkMode(event)
	if EventHandler.isEspace(event) then
		ModeManager.setModeNormal()
		return true
	end

	return EventHandler.processVimInput(event)
end

---Handles normal mode
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleNormalMode(event)
	if EventHandler.isEspace(event) then
		State.keyCapture = nil
		MenuBar.setTitle(State.mode)
		return false
	end

	return EventHandler.processVimInput(event)
end

---Handles vim input
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.processVimInput(event)
	local keyCode = event:getKeyCode()
	local flags = event:getFlags()

	for key, modifier in pairs(flags) do
		if modifier and key ~= "shift" and key ~= "ctrl" then
			return false
		end
	end

	local char = hs.keycodes.map[keyCode]

	if not char:match("[%a%d%[%]%$/]") or #char ~= 1 then
		return false
	end

	if flags.shift then
		char = event:getCharacters()
	end

	if flags.ctrl then
		local filteredMappings = {}

		local modeMapping

		if ModeManager.isMode(MODES.NORMAL) then
			modeMapping = M.config.mapping.normal
		end

		if ModeManager.isMode(MODES.INSERT_NORMAL) then
			modeMapping = M.config.mapping.insertNormal
		end

		if ModeManager.isMode(MODES.INSERT_VISUAL) then
			modeMapping = M.config.mapping.insertVisual
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

	EventHandler.handleVimInput(char, {
		modifiers = flags,
	})

	return true
end

---Handles events
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.process(event)
	if ModeManager.isMode(MODES.DISABLED) then
		return EventHandler.handleDisabledMode(event)
	end

	if ModeManager.isMode(MODES.PASSTHROUGH) then
		return EventHandler.handlePassthroughMode(event)
	end

	if ModeManager.isMode(MODES.INSERT) then
		return EventHandler.handleInsertMode(event)
	end

	if ModeManager.isMode(MODES.INSERT_NORMAL) then
		return EventHandler.handleInsertNormalMode(event)
	end

	if ModeManager.isMode(MODES.INSERT_VISUAL) then
		return EventHandler.handleInsertVisualMode(event)
	end

	if ModeManager.isMode(MODES.LINKS) then
		return EventHandler.handleLinkMode(event)
	end

	if ModeManager.isMode(MODES.NORMAL) then
		return EventHandler.handleNormalMode(event)
	end

	return false
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
			if isEditable and ModeManager.isMode(MODES.NORMAL) then
				ModeManager.setModeInsert()
			elseif not isEditable then
				if
					ModeManager.isMode(MODES.INSERT)
					or ModeManager.isMode(MODES.INSERT_NORMAL)
					or ModeManager.isMode(MODES.INSERT_VISUAL)
				then
					ModeManager.setModeNormal()
				end
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
			if
				ModeManager.isMode(MODES.INSERT)
				or ModeManager.isMode(MODES.INSERT_NORMAL)
				or ModeManager.isMode(MODES.INSERT_VISUAL)
			then
				ModeManager.setModeNormal()
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
					.new({ hs.eventtap.event.types.keyDown }, EventHandler.process)
					:start()
				log.df("Started event loop")
			end

			if
				Utils.tblContains(
					M.config.applicationGroups.exclusions,
					appName
				)
			then
				ModeManager.setModeDisabled()
				log.df("Disabled mode for excluded app: " .. appName)
			else
				ModeManager.setModeNormal()
			end
		end
	end)

	appWatcher:start()

	log.df("App watcher started")
end

local launcherWatcher = {}

local function startLaunchersWatcher()
	local launchers = M.config.applicationGroups.launchers

	if not launchers or #launchers == 0 then
		return
	end

	for _, launcher in ipairs(launchers) do
		if launcherWatcher[launcher] then
			launcherWatcher[launcher]:unsubscribeAll()
			launcherWatcher[launcher] = nil
			log.df("Stopped launcher watcher: " .. launcher)
		end

		launcherWatcher[launcher] = hs.window.filter
			.new(false)
			:setAppFilter(launcher, { visible = true })

		launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowCreated,
			function()
				log.df("Launcher opened: " .. launcher)
				ModeManager.setModeDisabled()
			end
		)

		launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowDestroyed,
			function()
				log.df("Launcher closed: " .. launcher)
				ModeManager.setModeNormal()
			end
		)
	end
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

	for _, launcher in pairs(launcherWatcher) do
		if launcher then
			launcher:unsubscribeAll()
			launcher = nil
			log.df("Stopped launcher watcher")
		end
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@type Hs.Vimnav.Config
---@diagnostic disable-next-line: missing-fields
M.config = {}

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
	log = hs.logger.new(M.name, "info")

	self._initialized = true
	log.i("Initialized")

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

	opts = opts or {}
	local extend = opts.extend
	if extend == nil then
		extend = true
	end

	-- Start with defaults
	if not M.config or not next(M.config) then
		M.config = Utils.deepCopy(DEFAULT_CONFIG)
	end

	-- Merge user config
	if userConfig then
		M.config = Utils.tblMerge(M.config, userConfig, extend)
	end

	-- Reinitialize logger with configured level
	log = hs.logger.new(M.name, M.config.logLevel)

	log.i("Configured")

	return self
end

---Starts the module
---@return Hs.Vimnav
function M:start()
	if self._running then
		log.w("Vimnav already running")
		return self
	end

	if not M.config or not next(M.config) then
		self:configure({})
	end

	resetState()

	Utils.fetchMappingPrefixes()
	Utils.generateCombinations()
	RoleMaps.init() -- Initialize role maps for performance

	cleanupWatchers()
	startAppWatcher()
	startLaunchersWatcher()
	setupPeriodicCleanup()
	MenuBar.create()
	Overlay.create()

	local currentApp = Elements.getApp()
	if
		currentApp
		and Utils.tblContains(
			M.config.applicationGroups.exclusions,
			currentApp:name()
		)
	then
		ModeManager.setModeDisabled()
	else
		ModeManager.setModeNormal()
	end

	self._running = true
	log.i("Started")

	return self
end

---Stops the module
---@return Hs.Vimnav
function M:stop()
	if not self._running then
		return self
	end

	print("-- Stopping Vimnav...")

	cleanupWatchers()

	if State.eventLoop then
		State.eventLoop:stop()
		State.eventLoop = nil
		log.df("Stopped event loop")
	end

	MenuBar.destroy()
	Overlay.destroy()
	Marks.clear()

	cleanupOnAppSwitch()

	State = {}

	self._running = false
	log.i("Vimnav stopped")

	return self
end

---Restarts the module
---@return Hs.Vimnav
function M:restart()
	log.i("Restarting Vimnav...")
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
		config = M.config,
		state = State,
	}
end

---Returns default config
---@return table
function M:getDefaultConfig()
	return Utils.deepCopy(DEFAULT_CONFIG)
end

return M
