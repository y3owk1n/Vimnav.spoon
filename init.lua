-- Vimnav.spoon
--
-- Think of it like vimium, but available for system wide. Probably won't work on electron apps though, I don't use them.
--
-- This module is originated and credits to `dzirtuss` at `https://github.com/dzirtusss/vifari`
-- I had made lots of modifications to the original code including performance and supporting for system wide instead
-- of just within Safari. In my opinion, there are too many changes that made it hard to contribute back to the original
-- project, and Vifari is meant for only for Safari, not system wide.

---@diagnostic disable: undefined-global

local Config = dofile(hs.spoons.resourcePath("./lib/config.lua"))
local State = dofile(hs.spoons.resourcePath("./lib/state.lua"))
local Utils = dofile(hs.spoons.resourcePath("./lib/utils.lua"))
local Cache = dofile(hs.spoons.resourcePath("./lib/cache.lua"))
local Elements = dofile(hs.spoons.resourcePath("./lib/elements.lua"))
local RoleMaps = dofile(hs.spoons.resourcePath("./lib/rolemaps.lua"))
local MarkPool = dofile(hs.spoons.resourcePath("./lib/marks.lua"))
local Constants = dofile(hs.spoons.resourcePath("./lib/constants.lua"))
local MenuBar = dofile(hs.spoons.resourcePath("./lib/menubar.lua"))

---@class Hs.Vimnav
local M = {}

M.__index = M

M.name = "Vimnav"
M.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal modules
local Overlay = {}
local ModeManager = {}
local Actions = {}
local ElementFinder = {}
local Marks = {}
local Commands = {}
local CanvasCache = {}
local EventHandler = {}
local Whichkey = {}
local CleanupManager = {}
local CacheManager = {}
local TimerManager = {}
local WatcherManager = {}

--------------------------------------------------------------------------------
-- Canvas Element Caching
--------------------------------------------------------------------------------

---Returns the mark template
---@param vimnav Hs.Vimnav
---@return table
function CanvasCache.getMarkTemplate(vimnav)
	if CanvasCache.template then
		return CanvasCache.template
	end

	local gradientFrom =
		Utils.hexToRgb(vimnav.config.hints.colors.from or "#FFF585")
	local gradientTo =
		Utils.hexToRgb(vimnav.config.hints.colors.to or "#FFC442")
	local gradientAngle = vimnav.config.hints.colors.angle or 0
	local borderColor =
		Utils.hexToRgb(vimnav.config.hints.colors.border or "#000000")
	local borderWidth = vimnav.config.hints.colors.borderWidth or 1

	local textColor =
		Utils.hexToRgb(vimnav.config.hints.colors.textColor or "#000000")

	CanvasCache.template = {
		background = {
			action = "fill",
			type = "segments",
			fillGradient = "linear",
			fillGradientColors = {
				gradientFrom,
				gradientTo,
			},
			fillGradientAngle = gradientAngle,
			closed = true,
		},
		text = {
			type = "text",
			textAlignment = "center",
			textColor = textColor,
			textSize = vimnav.config.hints.fontSize,
			textFont = vimnav.config.hints.textFont
				or ".AppleSystemUIFontHeavy",
		},
	}

	if borderWidth > 0 then
		CanvasCache.template.background.action = "strokeAndFill"
		CanvasCache.template.background.strokeColor = borderColor
		CanvasCache.template.background.strokeWidth = borderWidth
	end

	return CanvasCache.template
end

--------------------------------------------------------------------------------
-- Overlay Indicator
--------------------------------------------------------------------------------

---Creates the overlay indicator
---@param vimnav Hs.Vimnav
---@return nil
function Overlay.create(vimnav)
	if not vimnav.config.overlay.enabled then
		return
	end

	Overlay.destroy(vimnav)

	local screen = hs.screen.mainScreen()
	local frame = screen:fullFrame()
	local height = vimnav.config.overlay.size or 30
	local position = vimnav.config.overlay.position or "top-center"

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

	local padding = vimnav.config.overlay.padding

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

	vimnav.state.overlayCanvas = hs.canvas.new(overlayFrame)
	vimnav.state.overlayCanvas:level("overlay")
	vimnav.state.overlayCanvas:behavior("canJoinAllSpaces")

	vimnav.log.df("[Overlay.create] Created overlay indicator at " .. position)
end

---Get color for mode
---@param vimnav Hs.Vimnav
---@param mode number
---@return table
function Overlay.getModeColor(vimnav, mode)
	local colors = {
		[Constants.MODES.DISABLED] = Utils.hexToRgb(
			vimnav.config.overlay.colors.disabled or "#5a5672"
		),
		[Constants.MODES.NORMAL] = Utils.hexToRgb(
			vimnav.config.overlay.colors.normal or "#80b8e8"
		),
		[Constants.MODES.INSERT] = Utils.hexToRgb(
			vimnav.config.overlay.colors.insert or "#abe9b3"
		),
		[Constants.MODES.VISUAL] = Utils.hexToRgb(
			vimnav.config.overlay.colors.visual or "#c9a0e9"
		),
		[Constants.MODES.INSERT_NORMAL] = Utils.hexToRgb(
			vimnav.config.overlay.colors.insertNormal or "#f9e2af"
		),
		[Constants.MODES.INSERT_VISUAL] = Utils.hexToRgb(
			vimnav.config.overlay.colors.insertVisual or "#c9a0e9"
		),
		[Constants.MODES.LINKS] = Utils.hexToRgb(
			vimnav.config.overlay.colors.links or "#f8bd96"
		),
		[Constants.MODES.PASSTHROUGH] = Utils.hexToRgb(
			vimnav.config.overlay.colors.passthrough or "#f28fad"
		),
	}
	return colors[mode]
		or Utils.hexToRgb(vimnav.config.overlay.colors.disabled or "#5a5672")
end

---Updates the overlay indicator
---@param vimnav Hs.Vimnav
---@param mode number
---@param keys? string|nil
---@return nil
function Overlay.update(vimnav, mode, keys)
	if not vimnav.config.overlay.enabled or not vimnav.state.overlayCanvas then
		return
	end

	local color = Overlay.getModeColor(vimnav, mode)
	local modeChar = Constants.defaultModeChars[mode] or "?"
	local fontSize = vimnav.config.overlay.size / 2

	-- Build display text
	local displayText = modeChar
	if keys then
		displayText = string.format("%s [%s]", modeChar, keys)
	end

	local textWidth = #displayText * fontSize
	local height = vimnav.config.overlay.size or 30
	local newWidth = textWidth < height and height or textWidth

	-- Get current frame
	local currentFrame = vimnav.state.overlayCanvas:frame()
	local screen = hs.screen.mainScreen()
	local screenFrame = screen:fullFrame()
	local position = vimnav.config.overlay.position or "top-center"

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
	vimnav.state.overlayCanvas:frame({
		x = newX,
		y = currentFrame.y,
		w = newWidth,
		h = height,
	})

	-- Apply alpha to color
	color.alpha = 0.2
	local textColor = Overlay.getModeColor(vimnav, mode)

	vimnav.state.overlayCanvas:replaceElements({
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
			textFont = vimnav.config.overlay.textFont
				or ".AppleSystemUIFontBold",
			frame = {
				x = 0,
				y = (height - fontSize) / 2 - 2,
				w = newWidth,
				h = fontSize + 4,
			},
		},
	})
	vimnav.state.overlayCanvas:show()
end

---Destroys the overlay indicator
---@param vimnav Hs.Vimnav
---@return nil
function Overlay.destroy(vimnav)
	State.resetOverlayCanvas(vimnav)
end

--------------------------------------------------------------------------------
-- Whichkey
--------------------------------------------------------------------------------

---Get available mappings for current prefix
---@param prefix string Current key capture
---@param mapping table Mode mapping table
---@return table Available mappings
function Whichkey.getAvailableMappings(prefix, mapping)
	local available = {}
	local prefixLen = #prefix

	for key, command in pairs(mapping) do
		if command.action ~= "noop" then
			-- If prefix is empty, show all top-level keys
			if prefixLen == 0 then
				-- Extract first character or full key if it's a special combo
				local displayKey
				if key:match("^C%-") then
					displayKey = key:match("^(C%-.)")
				else
					displayKey = key
				end

				if displayKey and not available[displayKey] then
					-- For root level, show the first matching command for each prefix
					available[displayKey] = {
						key = displayKey,
						fullKey = key,
						command = command.action,
						description = command.description,
					}
				end
			-- Check if this key starts with our prefix and is longer
			elseif key:sub(1, prefixLen) == prefix and #key > prefixLen then
				local remaining = key:sub(prefixLen + 1)

				local displayKey

				-- Handle special keys like C- prefix
				if remaining:match("^C%-") then
					displayKey = remaining:match("^(C%-.)") or remaining
				else
					-- Get first character or full remaining if short
					displayKey = remaining:match("^.") or remaining
				end

				if displayKey and not available[displayKey] then
					available[displayKey] = {
						key = displayKey,
						fullKey = key,
						command = command.action,
						description = #remaining > 1 and "+more"
							or command.description,
					}
				end
			end
		end
	end

	return available
end

---Show which-key popup
---@param vimnav Hs.Vimnav
---@param prefix string Current key capture
---@return nil
function Whichkey.show(vimnav, prefix)
	if not vimnav.config.whichkey.enabled then
		return
	end

	Whichkey.hide(vimnav)

	local mapping
	if ModeManager.isMode(vimnav, Constants.MODES.NORMAL) then
		mapping = vimnav.config.mapping.normal
	elseif ModeManager.isMode(vimnav, Constants.MODES.VISUAL) then
		mapping = vimnav.config.mapping.visual
	elseif ModeManager.isMode(vimnav, Constants.MODES.INSERT_NORMAL) then
		mapping = vimnav.config.mapping.insertNormal
	elseif ModeManager.isMode(vimnav, Constants.MODES.INSERT_VISUAL) then
		mapping = vimnav.config.mapping.insertVisual
	else
		return
	end

	local available = Whichkey.getAvailableMappings(prefix, mapping)

	-- Convert to sorted array
	local items = {}
	for _, v in pairs(available) do
		table.insert(items, v)
	end

	table.sort(items, function(a, b)
		return a.key < b.key
	end)

	if #items == 0 then
		return
	end

	-- Calculate popup dimensions
	local fontSize = vimnav.config.whichkey.fontSize or 14
	local textFont = vimnav.config.whichkey.textFont
		or ".AppleSystemUIFontHeavy"
	local padding = 10
	local lineHeight = fontSize * 1.3

	local maxKeyLen = 0
	local maxDescLen = 0
	for _, it in ipairs(items) do
		maxKeyLen = math.max(maxKeyLen, utf8.len(it.key))
		maxDescLen = math.max(maxDescLen, utf8.len(it.description))
	end

	local keyWidth = maxKeyLen * fontSize
	local separatorWidth = 30
	local descWidth = maxDescLen * fontSize
	local colSpacing = 20 -- gap between columns
	local colWidth = keyWidth + separatorWidth + descWidth

	-- Get screen dimensions
	local screen = hs.screen.mainScreen()
	local screenFrame = screen:fullFrame()
	local usableWidth = screenFrame.w * 0.90 -- 90 % of screen
	local maxCols =
		math.max(1, math.floor(usableWidth / (colWidth + colSpacing)))

	local totalItems = #items
	local minRowsPerCol = vimnav.config.whichkey.minRowsPerCol or 8
	local cols2 = math.min(maxCols, math.ceil(totalItems / minRowsPerCol))
	local rowsPerCol = math.ceil(totalItems / cols2)

	local columns = {}
	for col = 1, maxCols do
		local start = (col - 1) * rowsPerCol + 1
		local finish = math.min(col * rowsPerCol, totalItems)
		if start > finish then
			break
		end
		columns[col] = { table.unpack(items, start, finish) }
	end
	local actualCols = cols2

	local popupWidth = actualCols * colWidth
		+ (actualCols - 1) * colSpacing
		+ 2 * padding
	local popupHeight = rowsPerCol * lineHeight + fontSize + 6 + 2 * padding + 6 -- title + slack
	local popupX = screenFrame.x + (screenFrame.w - popupWidth) / 2
	local popupY = screenFrame.y + screenFrame.h - popupHeight - 50

	-- Position at bottom center
	local popupFrame = {
		x = popupX,
		y = popupY,
		w = popupWidth,
		h = popupHeight,
	}

	-- Create canvas
	vimnav.state.whichkeyCanvas = hs.canvas.new(popupFrame)
	vimnav.state.whichkeyCanvas:level("overlay")
	vimnav.state.whichkeyCanvas:behavior("canJoinAllSpaces")

	-- Build canvas elements
	local elements = {}

	-- Background
	local bgColor =
		Utils.hexToRgb(vimnav.config.whichkey.colors.background or "#1e1e2e")
	bgColor.alpha = vimnav.config.whichkey.colors.backgroundAlpha or 0.8
	local borderColor =
		Utils.hexToRgb(vimnav.config.whichkey.colors.border or "#1e1e2e")

	table.insert(elements, {
		type = "rectangle",
		action = "strokeAndFill",
		fillColor = bgColor,
		strokeColor = borderColor,
		strokeWidth = 2,
		roundedRectRadii = { xRadius = 8, yRadius = 8 },
	})

	-- Title
	local keyColor =
		Utils.hexToRgb(vimnav.config.whichkey.colors.key or "#f9e2af")
	local titleText = prefix == "" and "All Keys" or "Which Key: " .. prefix
	table.insert(elements, {
		type = "text",
		text = titleText,
		textColor = keyColor,
		textSize = fontSize,
		textFont = textFont,
		frame = {
			x = padding,
			y = padding,
			w = popupWidth - padding * 2,
			h = fontSize + 4,
		},
	})

	-- Items
	local separatorColor =
		Utils.hexToRgb(vimnav.config.whichkey.colors.separator or "#6c7086")
	local descColor =
		Utils.hexToRgb(vimnav.config.whichkey.colors.description or "#cdd6f4")

	for colIdx, col in ipairs(columns) do
		local colX = padding + (colIdx - 1) * (colWidth + colSpacing)
		for rowIdx, item in ipairs(col) do
			local yOffset = padding + fontSize + 6 + (rowIdx - 1) * lineHeight

			-- Key
			table.insert(elements, {
				type = "text",
				text = item.key,
				textColor = keyColor,
				textSize = fontSize,
				textFont = textFont,
				frame = {
					x = colX,
					y = yOffset,
					w = keyWidth,
					h = lineHeight,
				},
			})

			-- Separator
			table.insert(elements, {
				type = "text",
				text = "→",
				textColor = separatorColor,
				textSize = fontSize,
				textFont = textFont,
				frame = {
					x = colX + keyWidth,
					y = yOffset,
					w = separatorWidth,
					h = lineHeight,
				},
			})

			-- Description
			table.insert(elements, {
				type = "text",
				text = item.description,
				textColor = descColor,
				textSize = fontSize,
				textFont = textFont,
				frame = {
					x = colX + keyWidth + separatorWidth,
					y = yOffset,
					w = descWidth,
					h = lineHeight,
				},
			})
		end
	end

	vimnav.state.whichkeyCanvas:replaceElements(elements)
	vimnav.state.whichkeyCanvas:show()

	vimnav.log.df(
		"[Whichkey.show] Which-key popup shown for prefix: " .. prefix
	)
end

---Hide which-key popup
---@param vimnav Hs.Vimnav
---@return nil
function Whichkey.hide(vimnav)
	State.resetWhichkeyCanvas(vimnav)
	TimerManager.stopWhichkey(vimnav)
end

---Schedule which-key popup to show after delay
---@param vimnav Hs.Vimnav
---@param prefix string Current key capture
---@return nil
function Whichkey.scheduleShow(vimnav, prefix)
	if not vimnav.config.whichkey.enabled then
		return
	end

	Whichkey.hide(vimnav)

	local delay = vimnav.config.whichkey.delay or 0.5
	vimnav.state.whichkeyTimer = hs.timer.doAfter(delay, function()
		Whichkey.show(vimnav, prefix)
	end)
end

--------------------------------------------------------------------------------
-- Mode Management
--------------------------------------------------------------------------------

---Sets the mode
---@param vimnav Hs.Vimnav
---@param mode number
---@return boolean success Whether the mode was set
---@return number|nil prevMode The previous mode
function ModeManager.setMode(vimnav, mode)
	if mode == vimnav.state.mode then
		vimnav.log.df(
			"[ModeManager.setMode] Mode already set to %s... abort",
			mode
		)
		return false
	end

	local previousMode = vimnav.state.mode

	vimnav.state.mode = mode

	CleanupManager.onModeChange(vimnav, previousMode, mode)

	MenuBar.setTitle(vimnav, mode)
	Overlay.update(vimnav, mode)

	vimnav.log.df(
		"[ModeManager.setMode] Mode changed: %s -> %s",
		previousMode,
		mode
	)

	return true, previousMode
end

---Checks if the current mode is the given mode
---@param vimnav Hs.Vimnav
---@param mode number
---@return boolean
function ModeManager.isMode(vimnav, mode)
	return vimnav.state.mode == mode
end

---Set mode to disabled
---@param vimnav Hs.Vimnav
---@return boolean
function ModeManager.setModeDisabled(vimnav)
	return ModeManager.setMode(vimnav, Constants.MODES.DISABLED)
end

---Set mode to passthrough
---@param vimnav Hs.Vimnav
---@return boolean
function ModeManager.setModePassthrough(vimnav)
	local ok = ModeManager.setMode(vimnav, Constants.MODES.PASSTHROUGH)

	if not ok then
		return false
	end

	if ok then
		Marks.clear(vimnav)
	end

	return true
end

---Set mode to links
---@param vimnav Hs.Vimnav
---@return boolean
function ModeManager.setModeLink(vimnav)
	local ok = ModeManager.setMode(vimnav, Constants.MODES.LINKS)

	if not ok then
		return false
	end

	Marks.clear(vimnav)

	return true
end

---Set mode to insert
---@param vimnav Hs.Vimnav
---@return boolean
function ModeManager.setModeInsert(vimnav)
	local ok = ModeManager.setMode(vimnav, Constants.MODES.INSERT)

	if not ok then
		return false
	end

	Marks.clear(vimnav)

	return true
end

---Set mode to insert normal
---@param vimnav Hs.Vimnav
---@return boolean
function ModeManager.setModeInsertNormal(vimnav)
	local ok = ModeManager.setMode(vimnav, Constants.MODES.INSERT_NORMAL)

	if not ok then
		return false
	end

	Marks.clear(vimnav)

	return true
end

---Set mode to insert visual
---@param vimnav Hs.Vimnav
---@return boolean
function ModeManager.setModeInsertVisual(vimnav)
	local ok = ModeManager.setMode(vimnav, Constants.MODES.INSERT_VISUAL)

	if not ok then
		return false
	end

	Marks.clear(vimnav)

	return true
end

---Set mode to visual
---@param vimnav Hs.Vimnav
---@return boolean
function ModeManager.setModeVisual(vimnav)
	local ok = ModeManager.setMode(vimnav, Constants.MODES.VISUAL)

	if not ok then
		return false
	end

	Marks.clear(vimnav)

	return true
end

---Set mode to normal
---@param vimnav Hs.Vimnav
---@return boolean
function ModeManager.setModeNormal(vimnav)
	local ok = ModeManager.setMode(vimnav, Constants.MODES.NORMAL)

	if not ok then
		return false
	end

	Marks.clear(vimnav)

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
---@param vimnav Hs.Vimnav
---@param opts Hs.Vimnav.Actions.SmoothScrollOpts
---@return nil
function Actions.smoothScroll(vimnav, opts)
	local x = opts.x or 0
	local y = opts.y or 0
	local smooth = opts.smooth or vimnav.config.scroll.smoothScroll

	if not smooth then
		hs.eventtap.event.newScrollEvent({ x, y }, {}, "pixel"):post()
		return
	end

	local steps = 5
	local dx = x and (x / steps) or 0
	local dy = y and (y / steps) or 0
	local frame = 0
	local interval = 1 / vimnav.config.scroll.smoothScrollFramerate

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
---@param vimnav Hs.Vimnav
---@param url string
---@return nil
function Actions.openUrlInNewTab(vimnav, url)
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

	local currentApp = Elements.getApp(vimnav)
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

---Download base64 image
---@param url string
---@param description string
---@return nil
function Actions.downloadBase64Image(url, description)
	local base64Data = url:match("^data:image/[^;]+;base64,(.+)$")
	if base64Data then
		local decodedData = hs.base64.decode(base64Data)
		---@diagnostic disable-next-line: param-type-mismatch
		local fileName = description:gsub("%W+", "_") .. ".jpg"
		local filePath = os.getenv("HOME") .. "/Downloads/" .. fileName

		local file = io.open(filePath, "wb")
		if file then
			file:write(decodedData)
			file:close()
			hs.alert.show("Image saved: " .. fileName, nil, nil, 2)
		end
	end
end

---Download image via http
---@param url string
---@return nil
function Actions.downloadImageViaHttp(url)
	hs.http.asyncGet(url, nil, function(status, body, headers)
		if status == 200 then
			local contentType = headers["Content-Type"] or ""
			if contentType:match("^image/") then
				local fileName = url:match("^.+/(.+)$") or "image.jpg"
				if not fileName:match("%.%w+$") then
					fileName = fileName .. ".jpg"
				end

				local filePath = os.getenv("HOME") .. "/Downloads/" .. fileName
				local file = io.open(filePath, "wb")
				if file then
					file:write(body)
					file:close()
					hs.alert.show("Image downloaded: " .. fileName, nil, nil, 2)
				end
			end
		end
	end)
end

---Force unfocus
---@param vimnav Hs.Vimnav
---@return nil
function Actions.forceUnfocus(vimnav)
	if vimnav.state.focusLastElement then
		vimnav.state.focusLastElement:setAttributeValue("AXFocused", false)
		hs.alert.show("Force unfocused!")

		-- Reset focus state
		State.resetFocus(vimnav)
	end
end

---Force deselect text highlights
---@param vimnav Hs.Vimnav
---@return nil
function Actions.forceDeselectTextHighlights(vimnav)
	local focused = Elements.getAxFocusedElement(vimnav)

	if not focused then
		return
	end

	local attrs = focused:attributeNames() or {}
	local supportsMarkers =
		hs.fnutils.contains(attrs, "AXSelectedTextMarkerRange")

	if supportsMarkers then
		local startMarker = focused:attributeValue("AXStartTextMarker")
		if not startMarker then
			vimnav.log.df(
				"[Actions.forceDeselectTextHighlights] No AXStartTextMarker found; cannot clear"
			)
			return
		end

		local emptyRange, err =
			hs.axuielement.axtextmarker.newRange(startMarker, startMarker)
		if not emptyRange then
			vimnav.log.ef(
				"[Actions.forceDeselectTextHighlights] Error creating empty range: %s",
				err
			)
			return
		end

		local ok, setErr =
			focused:setAttributeValue("AXSelectedTextMarkerRange", emptyRange)
		if ok then
			vimnav.log.df(
				"[Actions.forceDeselectTextHighlights] Text deselected via AX markers."
			)
			return
		else
			vimnav.log.ef(
				"[Actions.forceDeselectTextHighlights] Could not set AXSelectedTextMarkerRange: %s",
				setErr
			)
		end
	end

	-- Fallack with click
	local frame = focused:attributeValue("AXFrame")
	if frame then
		local center = { x = frame.x + frame.w / 2, y = frame.y + frame.h / 2 }
		hs.eventtap.leftClick(center)
		vimnav.log.df(
			"[Actions.forceDeselectTextHighlights] Text deselected via simulated click."
		)
	else
		vimnav.log.ef(
			"[Actions.forceDeselectTextHighlights] No frame available for click fallback."
		)
	end
end

---@class Hs.Vimnav.Actions.TryClickOpts
---@field type? string "left"|"right"
---@field doubleClick? boolean

---Tries to click on a frame
---@param frame table
---@param opts? Hs.Vimnav.Actions.TryClickOpts
---@return nil
function Actions.tryClick(frame, opts)
	opts = opts or {}
	local type = opts.type or "left"
	local doubleClick = opts.doubleClick or false

	local clickX, clickY = frame.x + frame.w / 2, frame.y + frame.h / 2
	local originalPos = hs.mouse.absolutePosition()
	-- hs.mouse.absolutePosition({ x = clickX, y = clickY })
	if type == "left" then
		if doubleClick then
			Utils.doubleClickAtPoint({ x = clickX, y = clickY })
		else
			hs.eventtap.leftClick({ x = clickX, y = clickY }, 0)
		end
	elseif type == "right" then
		hs.eventtap.rightClick({ x = clickX, y = clickY }, 0)
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
---@param vimnav Hs.Vimnav
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindClickableElementsOpts
---@return nil
function ElementFinder.findClickableElements(vimnav, axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback
	local withUrls = opts.withUrls

	local function _matcher(element)
		local role = Utils.getAttribute(vimnav, element, "AXRole")

		if withUrls then
			local url = Utils.getAttribute(vimnav, element, "AXURL")
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

	Elements.traverseAsync(vimnav, axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = vimnav.state.maxElements,
	})
end

---Finds input elements
---@param vimnav Hs.Vimnav
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindElementsOpts
---@return nil
function ElementFinder.findInputElements(vimnav, axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Utils.getAttribute(vimnav, element, "AXRole")
		return (role and type(role) == "string" and RoleMaps.isEditable(role))
			or false
	end

	local function _callback(results)
		-- Auto-click if single input found
		if #results == 1 then
			vimnav.state.onClickCallback({
				element = results[1],
				frame = Utils.getAttribute(vimnav, results[1], "AXFrame"),
			})
			ModeManager.setModeNormal(vimnav)
		else
			callback(results)
		end
	end

	Elements.traverseAsync(vimnav, axApp, {
		matcher = _matcher,
		callback = _callback,
		maxResults = 10,
	})
end

---Finds image elements
---@param vimnav Hs.Vimnav
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindElementsOpts
---@return nil
function ElementFinder.findImageElements(vimnav, axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Utils.getAttribute(vimnav, element, "AXRole")
		local url = Utils.getAttribute(vimnav, element, "AXURL")
		return role == "AXImage" and url ~= nil
	end

	Elements.traverseAsync(vimnav, axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 100,
	})
end

---Finds next button elemets
---@param vimnav Hs.Vimnav
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindElementsOpts
---@return nil
function ElementFinder.findNextButtonElements(vimnav, axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Utils.getAttribute(vimnav, element, "AXRole")
		local title = Utils.getAttribute(vimnav, element, "AXTitle")

		if
			(role == "AXLink" or role == "AXButton")
			and title
			and type(title) == "string"
		then
			return title:lower():find("next") ~= nil
		end
		return false
	end

	Elements.traverseAsync(vimnav, axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 5,
	})
end

---Finds previous button elemets
---@param vimnav Hs.Vimnav
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.ElementFinder.FindElementsOpts
---@return nil
function ElementFinder.findPrevButtonElements(vimnav, axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Utils.getAttribute(vimnav, element, "AXRole")
		local title = Utils.getAttribute(vimnav, element, "AXTitle")

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

	Elements.traverseAsync(vimnav, axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 5,
	})
end

--------------------------------------------------------------------------------
-- Marks System
--------------------------------------------------------------------------------

---Clears the marks
---@param vimnav Hs.Vimnav
---@return nil
function Marks.clear(vimnav)
	State.resetMarkCanvas(vimnav)
	State.resetMarks(vimnav)
	State.resetLinkCapture(vimnav)
	MarkPool.releaseAll()
	vimnav.log.df("[Marks.clear] Cleared marks")
end

---Adds a mark to the list
---@param vimnav Hs.Vimnav
---@param element table
---@return nil
function Marks.add(vimnav, element)
	if #vimnav.state.marks >= vimnav.state.maxElements then
		return
	end

	local frame = Utils.getAttribute(vimnav, element, "AXFrame")
	if not frame or frame.w <= 2 or frame.h <= 2 then
		return
	end

	local mark = MarkPool.getMark()
	mark.element = element
	mark.frame = frame
	mark.role = Utils.getAttribute(vimnav, element, "AXRole")

	vimnav.state.marks[#vimnav.state.marks + 1] = mark
end

---@class Hs.Vimnav.Marks.ShowOpts
---@field withUrls? boolean
---@field elementType "link"|"input"|"image"

---Show marks
---@param vimnav Hs.Vimnav
---@param opts Hs.Vimnav.Marks.ShowOpts
---@return nil
function Marks.show(vimnav, opts)
	local axApp = Elements.getAxApp(vimnav)
	if not axApp then
		return
	end

	local withUrls = opts.withUrls or false
	local elementType = opts.elementType

	Marks.clear(vimnav)

	if elementType == "link" then
		local function _callback(elements)
			-- Convert to marks
			for i = 1, math.min(#elements, vimnav.state.maxElements) do
				Marks.add(vimnav, elements[i])
			end

			if #vimnav.state.marks > 0 then
				Marks.draw(vimnav)
			else
				hs.alert.show("No links found", nil, nil, 1)
				ModeManager.setModeNormal(vimnav)
			end
		end
		ElementFinder.findClickableElements(vimnav, axApp, {
			withUrls = withUrls,
			callback = _callback,
		})
	elseif elementType == "input" then
		local function _callback(elements)
			for i = 1, #elements do
				Marks.add(vimnav, elements[i])
			end
			if #vimnav.state.marks > 0 then
				Marks.draw(vimnav)
			else
				hs.alert.show("No inputs found", nil, nil, 1)
				ModeManager.setModeNormal(vimnav)
			end
		end
		ElementFinder.findInputElements(vimnav, axApp, {
			callback = _callback,
		})
	elseif elementType == "image" then
		local function _callback(elements)
			for i = 1, #elements do
				Marks.add(vimnav, elements[i])
			end
			if #vimnav.state.marks > 0 then
				Marks.draw(vimnav)
			else
				hs.alert.show("No images found", nil, nil, 1)
				ModeManager.setModeNormal(vimnav)
			end
		end
		ElementFinder.findImageElements(vimnav, axApp, {
			callback = _callback,
		})
	end
end

---Draws the marks
---@param vimnav Hs.Vimnav
---@return nil
function Marks.draw(vimnav)
	if not vimnav.state.markCanvas then
		local frame = Elements.getFullArea(vimnav)
		if not frame then
			return
		end
		vimnav.state.markCanvas = hs.canvas.new(frame)
	end

	local captureLen = #vimnav.state.linkCapture
	local elementsToDraw = {}
	local template = CanvasCache.getMarkTemplate(vimnav)

	local count = 0
	for i = 1, #vimnav.state.marks do
		if count >= #vimnav.state.allCombinations then
			break
		end

		local mark = vimnav.state.marks[i]
		local markText = vimnav.state.allCombinations[i]:upper()

		if
			captureLen == 0
			or markText:sub(1, captureLen) == vimnav.state.linkCapture
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
				local fontSize = vimnav.config.hints.fontSize
				local textWidth = #markText * fontSize
				local textHeight = fontSize * 1.2
				local containerWidth = textWidth
				local containerHeight = textHeight

				local arrowWidth = containerWidth / 5
				local arrowHeight = arrowWidth / 2
				local cornerRadius = fontSize / 6

				local bgRect = hs.geometry.rect(
					frame.x + (frame.w / 2) - (containerWidth / 2),
					frame.y + (frame.h / 2) + arrowHeight,
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
					y = ry,
					w = rw,
					h = textHeight,
				}

				elementsToDraw[#elementsToDraw + 1] = bg
				elementsToDraw[#elementsToDraw + 1] = text
				count = count + 1
			end
		end
	end

	vimnav.state.markCanvas:replaceElements(elementsToDraw)
	vimnav.state.markCanvas:show()
end

---Clicks a mark
---@param vimnav Hs.Vimnav
---@param combination string
---@return nil
function Marks.click(vimnav, combination)
	for i, c in ipairs(vimnav.state.allCombinations) do
		if
			c == combination
			and vimnav.state.marks[i]
			and vimnav.state.onClickCallback
		then
			local success, err =
				pcall(vimnav.state.onClickCallback, vimnav.state.marks[i])
			if not success then
				vimnav.log.ef(
					"[Marks.click] Error clicking element: " .. tostring(err)
				)
			end
			break
		end
	end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

---Scrolls left
---@param vimnav Hs.Vimnav
---@return nil
function Commands.scrollLeft(vimnav)
	Actions.smoothScroll(vimnav, { x = vimnav.config.scroll.scrollStep })
end

---Scrolls right
---@param vimnav Hs.Vimnav
---@return nil
function Commands.scrollRight(vimnav)
	Actions.smoothScroll(vimnav, { x = -vimnav.config.scroll.scrollStep })
end

---Scrolls up
---@param vimnav Hs.Vimnav
---@return nil
function Commands.scrollUp(vimnav)
	Actions.smoothScroll(vimnav, { y = vimnav.config.scroll.scrollStep })
end

---Scrolls down
---@param vimnav Hs.Vimnav
---@return nil
function Commands.scrollDown(vimnav)
	Actions.smoothScroll(vimnav, { y = -vimnav.config.scroll.scrollStep })
end

---Scrolls half page down
---@param vimnav Hs.Vimnav
---@return nil
function Commands.scrollHalfPageDown(vimnav)
	Actions.smoothScroll(
		vimnav,
		{ y = -vimnav.config.scroll.scrollStepHalfPage }
	)
end

---Scrolls half page up
---@param vimnav Hs.Vimnav
---@return nil
function Commands.scrollHalfPageUp(vimnav)
	Actions.smoothScroll(
		vimnav,
		{ y = vimnav.config.scroll.scrollStepHalfPage }
	)
end

---Scrolls to top
---@param vimnav Hs.Vimnav
---@return nil
function Commands.scrollToTop(vimnav)
	Actions.smoothScroll(
		vimnav,
		{ y = vimnav.config.scroll.scrollStepFullPage }
	)
end

---Scrolls to bottom
---@param vimnav Hs.Vimnav
---@return nil
function Commands.scrollToBottom(vimnav)
	Actions.smoothScroll(
		vimnav,
		{ y = -vimnav.config.scroll.scrollStepFullPage }
	)
end

---@param vimnav Hs.Vimnav
function Commands.showHelp(vimnav)
	vimnav.state.showingHelp = true
	Whichkey.show(vimnav, "")
end

---Switches to passthrough mode
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterPassthroughMode(vimnav)
	return ModeManager.setModePassthrough(vimnav)
end

---Switches to insert mode
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterInsertMode(vimnav)
	return ModeManager.setModeInsert(vimnav)
end

---Switches to insert mode and make a new line above
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterInsertModeNewLineAbove(vimnav)
	Utils.keyStroke({}, "up")
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return ModeManager.setModeInsert(vimnav)
end

---Switches to insert mode and make a new line below
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterInsertModeNewLineBelow(vimnav)
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return ModeManager.setModeInsert(vimnav)
end

---Switches to insert mode and put cursor at the end of the line
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterInsertModeEndOfLine(vimnav)
	Utils.keyStroke("cmd", "right")
	return ModeManager.setModeInsert(vimnav)
end

---Switches to insert mode and put cursor at the start of the line
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterInsertModeStartLine(vimnav)
	Utils.keyStroke("cmd", "left")
	return ModeManager.setModeInsert(vimnav)
end

---Switches to insert visual mode
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterInsertVisualMode(vimnav)
	return ModeManager.setModeInsertVisual(vimnav)
end

---Switches to visual mode
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterVisualMode(vimnav)
	return ModeManager.setModeVisual(vimnav)
end

---Switches to insert visual mode with line selection
---@param vimnav Hs.Vimnav
---@return boolean
function Commands.enterInsertVisualLineMode(vimnav)
	Utils.keyStroke("cmd", "left")
	Utils.keyStroke({ "shift", "cmd" }, "right")

	return ModeManager.setModeInsertVisual(vimnav)
end

---Switches to links mode
---@param vimnav Hs.Vimnav
---@return nil
function Commands.gotoLink(vimnav)
	local ok = ModeManager.setModeLink(vimnav)

	if not ok then
		return
	end

	vimnav.state.onClickCallback = function(mark)
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
		Marks.show(vimnav, { elementType = "link" })
	end)
end

---Go to input mode
---@param vimnav Hs.Vimnav
---@return nil
function Commands.gotoInput(vimnav)
	local ok = ModeManager.setModeLink(vimnav)

	if not ok then
		return
	end

	vimnav.state.onClickCallback = function(mark)
		local element = mark.element

		local pressOk = element:performAction("AXPress")

		if pressOk then
			local focused = Utils.getAttribute(vimnav, element, "AXFocused")
			if not focused then
				Actions.tryClick(mark.frame)
				return
			end
		end

		Actions.tryClick(mark.frame)
	end
	hs.timer.doAfter(0, function()
		Marks.show(vimnav, { elementType = "input" })
	end)
end

---Double left click
---@param vimnav Hs.Vimnav
---@return nil
function Commands.doubleLeftClick(vimnav)
	local ok = ModeManager.setModeLink(vimnav)

	if not ok then
		return
	end

	vimnav.state.onClickCallback = function(mark)
		local frame = mark.frame

		Actions.tryClick(frame, { doubleClick = true })
	end
	hs.timer.doAfter(0, function()
		Marks.show(vimnav, { elementType = "link" })
	end)
end

---Right click
---@param vimnav Hs.Vimnav
---@return nil
function Commands.rightClick(vimnav)
	local ok = ModeManager.setModeLink(vimnav)

	if not ok then
		return
	end

	vimnav.state.onClickCallback = function(mark)
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
		Marks.show(vimnav, { elementType = "link" })
	end)
end

---Go to link in new tab
---@param vimnav Hs.Vimnav
---@return nil
function Commands.gotoLinkNewTab(vimnav)
	if not Elements.isInBrowser(vimnav) then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = ModeManager.setModeLink(vimnav)

	if not ok then
		return
	end

	vimnav.state.onClickCallback = function(mark)
		local url = Utils.getAttribute(vimnav, mark.element, "AXURL")
		if url then
			Actions.openUrlInNewTab(vimnav, url.url)
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show(vimnav, { elementType = "link", withUrls = true })
	end)
end

---Download image
---@param vimnav Hs.Vimnav
---@return nil
function Commands.downloadImage(vimnav)
	if not Elements.isInBrowser(vimnav) then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = ModeManager.setModeLink(vimnav)

	if not ok then
		return
	end

	vimnav.state.onClickCallback = function(mark)
		local element = mark.element
		local role = Utils.getAttribute(vimnav, element, "AXRole")

		if role == "AXImage" then
			local description = Utils.getAttribute(
				vimnav,
				element,
				"AXDescription"
			) or "image"

			local downloadUrlAttr = Utils.getAttribute(vimnav, element, "AXURL")

			if downloadUrlAttr then
				local url = downloadUrlAttr.url

				if url and url:match("^data:image/") then
					---@diagnostic disable-next-line: param-type-mismatch
					Actions.downloadBase64Image(url, description)
				else
					---@diagnostic disable-next-line: param-type-mismatch
					Actions.downloadImageViaHttp(url)
				end
			end
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show(vimnav, { elementType = "image" })
	end)
end

---Move mouse to link
---@param vimnav Hs.Vimnav
---@return nil
function Commands.moveMouseToLink(vimnav)
	local ok = ModeManager.setModeLink(vimnav)

	if not ok then
		return
	end

	vimnav.state.onClickCallback = function(mark)
		local frame = mark.frame
		if frame then
			hs.mouse.absolutePosition({
				x = frame.x + frame.w / 2,
				y = frame.y + frame.h / 2,
			})
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show(vimnav, { elementType = "link" })
	end)
end

---Copy link URL to clipboard
---@param vimnav Hs.Vimnav
---@return nil
function Commands.copyLinkUrlToClipboard(vimnav)
	if not Elements.isInBrowser(vimnav) then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = ModeManager.setModeLink(vimnav)

	if not ok then
		return
	end

	vimnav.state.onClickCallback = function(mark)
		local url = Utils.getAttribute(vimnav, mark.element, "AXURL")
		if url then
			Actions.setClipboardContents(url.url)
		else
			hs.alert.show("No URL found", nil, nil, 2)
		end
	end
	hs.timer.doAfter(0, function()
		Marks.show(vimnav, { elementType = "link", withUrls = true })
	end)
end

---Next page
---@param vimnav Hs.Vimnav
---@return nil
function Commands.gotoNextPage(vimnav)
	if not Elements.isInBrowser(vimnav) then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local axWindow = Elements.getAxWindow(vimnav)
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

	ElementFinder.findNextButtonElements(vimnav, axWindow, {
		callback = _callback,
	})
end

---Prev page
---@param vimnav Hs.Vimnav
---@return nil
function Commands.gotoPrevPage(vimnav)
	if not Elements.isInBrowser(vimnav) then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local axWindow = Elements.getAxWindow(vimnav)
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

	ElementFinder.findPrevButtonElements(
		vimnav,
		axWindow,
		{ callback = _callback }
	)
end

---Copy page URL to clipboard
---@param vimnav Hs.Vimnav
---@return nil
function Commands.copyPageUrlToClipboard(vimnav)
	if not Elements.isInBrowser(vimnav) then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local axWebArea = Elements.getAxWebArea(vimnav)
	local url = axWebArea and Utils.getAttribute(vimnav, axWebArea, "AXURL")
	if url then
		Actions.setClipboardContents(url.url)
	end
end

---Move mouse to center
---@return nil
function Commands.moveMouseToCenter()
	local window = Elements.getWindow(vimnav)
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

---@param vimnav Hs.Vimnav
function Commands.changeWord(vimnav)
	Commands.deleteWord()
	ModeManager.setModeInsert(vimnav)
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

---@param vimnav Hs.Vimnav
function Commands.changeLine(vimnav)
	Commands.deleteLine()
	ModeManager.setModeInsert(vimnav)
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

---@param vimnav Hs.Vimnav
function Commands.changeHighlighted(vimnav)
	Commands.deleteHighlighted()
	ModeManager.setModeInsert(vimnav)
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
---@param vimnav Hs.Vimnav
---@param char string
---@param opts? Hs.Vimnav.EventHandler.HandleVimInputOpts
---@return nil
function EventHandler.handleVimInput(vimnav, char, opts)
	opts = opts or {}
	local modifiers = opts.modifiers

	vimnav.log.df(
		"[EventHandler.handleVimInput] "
			.. char
			.. " modifiers: "
			.. hs.inspect(modifiers)
	)

	-- Clear element cache on every input
	CacheManager.clearElements(vimnav)

	-- handle link capture first
	if ModeManager.isMode(vimnav, Constants.MODES.LINKS) then
		vimnav.state.linkCapture = vimnav.state.linkCapture .. char:upper()
		for i, _ in ipairs(vimnav.state.marks) do
			if i > #vimnav.state.allCombinations then
				break
			end

			local markText = vimnav.state.allCombinations[i]:upper()
			if markText == vimnav.state.linkCapture then
				Marks.click(vimnav, markText:lower())
				ModeManager.setModeNormal(vimnav)
				CleanupManager.onCommandComplete(vimnav)
				return
			end
		end
	end

	-- Check if this is the leader key being pressed
	local leaderKey = vimnav.config.leader.key
	if char == leaderKey and not vimnav.state.leaderPressed then
		vimnav.state.leaderPressed = true
		vimnav.state.leaderCapture = ""
		vimnav.state.keyCapture = "<leader>"

		Whichkey.scheduleShow(vimnav, vimnav.state.keyCapture)
		MenuBar.setTitle(vimnav, vimnav.state.mode, vimnav.state.keyCapture)
		Overlay.update(vimnav, vimnav.state.mode, vimnav.state.keyCapture)
		vimnav.log.df("[EventHandler.handleVimInput] Leader key pressed")
		return
	end

	-- Build key combination
	local keyCombo = ""

	-- make "space" into " "
	if char == "space" then
		char = " "
	end

	-- Handle leader key sequences (including multi-char)
	if vimnav.state.leaderPressed then
		vimnav.state.leaderCapture = vimnav.state.leaderCapture .. char
		keyCombo = "<leader>" .. vimnav.state.leaderCapture
	else
		if modifiers and modifiers.ctrl then
			keyCombo = "C-"
		end
		keyCombo = keyCombo .. char

		if vimnav.state.keyCapture then
			vimnav.state.keyCapture = vimnav.state.keyCapture .. keyCombo
		end
	end

	if not vimnav.state.keyCapture or vimnav.state.leaderPressed then
		vimnav.state.keyCapture = keyCombo
	end

	if vimnav.state.keyCapture and #vimnav.state.keyCapture > 0 then
		Whichkey.scheduleShow(vimnav, vimnav.state.keyCapture)
	end

	MenuBar.setTitle(vimnav, vimnav.state.mode, vimnav.state.keyCapture)
	Overlay.update(vimnav, vimnav.state.mode, vimnav.state.keyCapture)

	-- Execute mapping
	local mapping
	local prefixes

	if ModeManager.isMode(vimnav, Constants.MODES.NORMAL) then
		mapping = vimnav.config.mapping.normal[vimnav.state.keyCapture]
		prefixes = vimnav.state.mappingPrefixes.normal
	end

	if ModeManager.isMode(vimnav, Constants.MODES.INSERT_NORMAL) then
		mapping = vimnav.config.mapping.insertNormal[vimnav.state.keyCapture]
		prefixes = vimnav.state.mappingPrefixes.insertNormal
	end

	if ModeManager.isMode(vimnav, Constants.MODES.INSERT_VISUAL) then
		mapping = vimnav.config.mapping.insertVisual[vimnav.state.keyCapture]
		prefixes = vimnav.state.mappingPrefixes.insertVisual
	end

	if ModeManager.isMode(vimnav, Constants.MODES.VISUAL) then
		mapping = vimnav.config.mapping.visual[vimnav.state.keyCapture]
		prefixes = vimnav.state.mappingPrefixes.visual
	end

	if mapping and type(mapping) == "table" then
		local action = mapping.action
		-- Found a complete mapping, execute it
		if type(action) == "string" then
			if action == "noop" then
				vimnav.log.df("[EventHandler.handleVimInput] No mapping")
			else
				local cmd = Commands[action]
				if cmd then
					cmd(vimnav)
				else
					vimnav.log.wf(
						"[EventHandler.handleVimInput] Unknown command: "
							.. mapping
					)
				end
			end
		elseif type(action) == "table" then
			Utils.keyStroke(action[1], action[2])
		elseif type(action) == "function" then
			action(vimnav)
		end

		CleanupManager.onCommandComplete(vimnav)
	elseif prefixes and prefixes[vimnav.state.keyCapture] then
		vimnav.log.df(
			"[EventHandler.handleVimInput] Found prefix: "
				.. vimnav.state.keyCapture
		)
		-- Continue waiting for more keys
	else
		-- No mapping or prefix found, reset
		CleanupManager.onCommandComplete(vimnav)
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
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handlePassthroughMode(vimnav, event)
	if EventHandler.isShiftEspace(event) then
		ModeManager.setModeNormal(vimnav)
		return true
	end

	return false
end

---Handles insert mode
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertMode(vimnav, event)
	if EventHandler.isShiftEspace(event) then
		if Elements.isInBrowser(vimnav) then
			Actions.forceUnfocus(vimnav)
			hs.timer.doAfter(0.1, function()
				ModeManager.setModeNormal(vimnav)
			end)
		end
		return true
	end

	if EventHandler.isEspace(event) then
		ModeManager.setModeInsertNormal(vimnav)
		return true
	end

	return false
end

---Handles insert normal mode
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertNormalMode(vimnav, event)
	if EventHandler.isShiftEspace(event) then
		if Elements.isInBrowser(vimnav) then
			Actions.forceUnfocus(vimnav)
			hs.timer.doAfter(0.1, function()
				ModeManager.setModeNormal(vimnav)
			end)
		end
		return true
	end

	if EventHandler.isEspace(event) then
		if vimnav.state.leaderPressed then
			CleanupManager.onEscape(vimnav)
			return true
		end
	end

	return EventHandler.processVimInput(vimnav, event)
end

---Handles insert visual mode
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleInsertVisualMode(vimnav, event)
	if EventHandler.isShiftEspace(event) then
		if Elements.isInBrowser(vimnav) then
			Utils.keyStroke({}, "left")
			hs.timer.doAfter(0.1, function()
				Actions.forceUnfocus(vimnav)
			end)
			hs.timer.doAfter(0.1, function()
				ModeManager.setModeNormal(vimnav)
			end)
		end
		return true
	end

	if EventHandler.isEspace(event) then
		if vimnav.state.leaderPressed then
			CleanupManager.onEscape(vimnav)
			return true
		else
			Utils.keyStroke({}, "right")
			ModeManager.setModeInsertNormal(vimnav)
			return true
		end
	end

	return EventHandler.processVimInput(vimnav, event)
end

---Handles links mode
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleLinkMode(vimnav, event)
	if EventHandler.isEspace(event) then
		ModeManager.setModeNormal(vimnav)
		return true
	end

	return EventHandler.processVimInput(vimnav, event)
end

---Handles normal mode
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleNormalMode(vimnav, event)
	if EventHandler.isEspace(event) then
		CleanupManager.onEscape(vimnav)
		Actions.forceDeselectTextHighlights(vimnav)
		return false
	end

	return EventHandler.processVimInput(vimnav, event)
end

---Handles visual mode
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.handleVisualMode(vimnav, event)
	if EventHandler.isEspace(event) then
		Actions.forceDeselectTextHighlights(vimnav)
		ModeManager.setModeNormal(vimnav)
		Whichkey.hide(vimnav)
		return false
	end

	return EventHandler.processVimInput(vimnav, event)
end

---Handles vim input
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.processVimInput(vimnav, event)
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
	local leaderKey = vimnav.config.leader.key or " "
	if typedChar == leaderKey and not vimnav.state.leaderPressed then
		EventHandler.handleVimInput(vimnav, leaderKey, {
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

		if ModeManager.isMode(vimnav, Constants.MODES.NORMAL) then
			modeMapping = vimnav.config.mapping.normal
		end

		if ModeManager.isMode(vimnav, Constants.MODES.INSERT_NORMAL) then
			modeMapping = vimnav.config.mapping.insertNormal
		end

		if ModeManager.isMode(vimnav, Constants.MODES.INSERT_VISUAL) then
			modeMapping = vimnav.config.mapping.insertVisual
		end

		if ModeManager.isMode(vimnav, Constants.MODES.VISUAL) then
			modeMapping = vimnav.config.mapping.visual
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

	EventHandler.handleVimInput(vimnav, char, {
		modifiers = flags,
	})

	return true
end

---Handles events
---@param vimnav Hs.Vimnav
---@param event table
---@return boolean handled True if should intercept and not pass to the app, false wil propogate to the app
function EventHandler.process(vimnav, event)
	-- Ignore synthetic events from utils.keyStroke
	if
		event:getProperty(hs.eventtap.event.properties.eventSourceUserData)
		== eventSourceIgnoreSignature
	then
		vimnav.log.df(
			"[EventHandler.process] SYNTHETIC EVENT DETECTED – SKIPPING"
		)
		return false
	end

	if ModeManager.isMode(vimnav, Constants.MODES.DISABLED) then
		return EventHandler.handleDisabledMode(event)
	end

	if ModeManager.isMode(vimnav, Constants.MODES.PASSTHROUGH) then
		return EventHandler.handlePassthroughMode(vimnav, event)
	end

	if ModeManager.isMode(vimnav, Constants.MODES.INSERT) then
		return EventHandler.handleInsertMode(vimnav, event)
	end

	if ModeManager.isMode(vimnav, Constants.MODES.INSERT_NORMAL) then
		return EventHandler.handleInsertNormalMode(vimnav, event)
	end

	if ModeManager.isMode(vimnav, Constants.MODES.INSERT_VISUAL) then
		return EventHandler.handleInsertVisualMode(vimnav, event)
	end

	if ModeManager.isMode(vimnav, Constants.MODES.LINKS) then
		return EventHandler.handleLinkMode(vimnav, event)
	end

	if ModeManager.isMode(vimnav, Constants.MODES.NORMAL) then
		return EventHandler.handleNormalMode(vimnav, event)
	end

	if ModeManager.isMode(vimnav, Constants.MODES.VISUAL) then
		return EventHandler.handleVisualMode(vimnav, event)
	end

	return false
end

---@param vimnav Hs.Vimnav
function EventHandler.startEventLoop(vimnav)
	if not vimnav.state.eventLoop then
		vimnav.state.eventLoop = hs.eventtap
			.new({ hs.eventtap.event.types.keyDown }, function(event)
				return EventHandler.process(vimnav, event)
			end)
			:start()
		vimnav.log.df("[EventHandler.startEventLoop] Started event loop")
	end
end

---@param vimnav Hs.Vimnav
function EventHandler.stopEventLoop(vimnav)
	if vimnav.state.eventLoop then
		vimnav.state.eventLoop:stop()
		vimnav.state.eventLoop = nil
		vimnav.log.df("[EventHandler.stopEventLoop] Stopped event loop")
	end
end

--------------------------------------------------------------------------------
-- Watchers
--------------------------------------------------------------------------------

---Starts the app watcher
---@param vimnav Hs.Vimnav
---@return nil
function WatcherManager.startAppWatcher(vimnav)
	WatcherManager.stopAppWatcher(vimnav)

	TimerManager.startFocusCheck(vimnav)
	Elements.enableEnhancedUIForChrome(vimnav)
	Elements.enableAccessibilityForElectron(vimnav)

	vimnav.state.appWatcher = hs.application.watcher.new(
		function(appName, eventType)
			vimnav.log.df(
				"[WatcherManager.startAppWatcher] App event: %s - %s",
				appName,
				eventType
			)

			if eventType == hs.application.watcher.activated then
				vimnav.log.df(
					"[WatcherManager.startAppWatcher] App activated: %s",
					appName
				)

				CleanupManager.onAppSwitch(vimnav)
				TimerManager.startFocusCheck(vimnav)
				Elements.enableEnhancedUIForChrome(vimnav)
				Elements.enableAccessibilityForElectron(vimnav)
				EventHandler.startEventLoop(vimnav)

				if
					Utils.tblContains(
						vimnav.config.applicationGroups.exclusions,
						appName
					)
				then
					ModeManager.setModeDisabled(vimnav)
					vimnav.log.df(
						"[WatcherManager.startAppWatcher] Disabled mode for excluded app: %s",
						appName
					)
				else
					ModeManager.setModeNormal(vimnav)
				end
			end
		end
	)

	vimnav.state.appWatcher:start()

	vimnav.log.df("[WatcherManager.startAppWatcher] App watcher started")
end

---@param vimnav Hs.Vimnav
function WatcherManager.stopAppWatcher(vimnav)
	if vimnav.state.appWatcher then
		vimnav.state.appWatcher:stop()
		vimnav.state.appWatcher = nil
		vimnav.log.df("[WatcherManager.stopAppWatcher] Stopped app watcher")
	end
end

---@param vimnav Hs.Vimnav
function WatcherManager.startLaunchersWatcher(vimnav)
	local launchers = vimnav.config.applicationGroups.launchers

	if not launchers or #launchers == 0 then
		return
	end

	for _, launcher in ipairs(launchers) do
		WatcherManager.stopLauncherWatcher(vimnav, launcher)

		vimnav.state.launcherWatcher[launcher] = hs.window.filter
			.new(false)
			:setAppFilter(launcher, { visible = true })

		vimnav.state.launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowCreated,
			function()
				vimnav.log.df(
					"[WatcherManager.startLaunchersWatcher] Launcher opened: %s",
					launcher
				)
				ModeManager.setModeDisabled(vimnav)
			end
		)

		vimnav.state.launcherWatcher[launcher]:subscribe(
			hs.window.filter.windowDestroyed,
			function()
				vimnav.log.df(
					"[WatcherManager.startLaunchersWatcher] Launcher closed: %s",
					launcher
				)
				ModeManager.setModeNormal(vimnav)
			end
		)
	end
end

---@param vimnav Hs.Vimnav
function WatcherManager.stopLauncherWatcher(vimnav, launcher)
	if
		vimnav.state.launcherWatcher and vimnav.state.launcherWatcher[launcher]
	then
		vimnav.state.launcherWatcher[launcher]:unsubscribeAll()
		vimnav.state.launcherWatcher[launcher] = nil
		vimnav.log.df(
			"[WatcherManager.stopLauncherWatcher] Stopped launcher watcher: %s",
			launcher
		)
	end
end

---@param vimnav Hs.Vimnav
function WatcherManager.stopLaunchersWatcher(vimnav)
	if vimnav.state.launcherWatcher then
		for _, launcher in pairs(vimnav.state.launcherWatcher) do
			if launcher then
				launcher:unsubscribeAll()
				launcher = nil
			end
		end
		vimnav.state.launcherWatcher = {}
		vimnav.log.df(
			"[WatcherManager.stopLaunchersWatcher] Stopped launcher watcher"
		)
	end
end

---@param vimnav Hs.Vimnav
function WatcherManager.startScreenWatcher(vimnav)
	WatcherManager.stopScreenWatcher(vimnav)
	vimnav.state.screenWatcher =
		hs.screen.watcher.new(CleanupManager.onScreenChange):start()
	vimnav.log.df("[WatcherManager.startScreenWatcher] Screen watcher started")
end

---@param vimnav Hs.Vimnav
function WatcherManager.stopScreenWatcher(vimnav)
	if vimnav.state.screenWatcher then
		vimnav.state.screenWatcher:stop()
		vimnav.state.screenWatcher = nil
		vimnav.log.df(
			"[WatcherManager.stopScreenWatcher] Stopped screen watcher"
		)
	end
end

---@param vimnav Hs.Vimnav
local function handleCaffeineEvent(vimnav, eventType)
	if eventType == hs.caffeinate.watcher.systemDidWake then
		vimnav.log.df("[handleCaffeineEvent] System woke from sleep")

		-- Give the system time to stabilize
		hs.timer.doAfter(1.0, function()
			-- Clean up everything
			CleanupManager.onWake(vimnav)

			-- Recreate overlay with correct screen position
			if vimnav.config.overlay.enabled then
				Overlay.destroy(vimnav)
				hs.timer.doAfter(0.1, function()
					Overlay.create(vimnav)
					Overlay.update(vimnav, vimnav.state.mode)
				end)
			end

			-- Recreate menubar in case it got corrupted
			if vimnav.config.menubar.enabled then
				MenuBar.destroy(vimnav)
				MenuBar.create(vimnav)
				MenuBar.setTitle(vimnav, vimnav.state.mode)
			end

			-- Restart focus polling
			TimerManager.startFocusCheck(vimnav)

			-- Restart periodic cleanup timer
			TimerManager.startPeriodicCleanup(vimnav)

			-- Re-enable enhanced accessibility if needed
			Elements.enableEnhancedUIForChrome(vimnav)
			Elements.enableAccessibilityForElectron(vimnav)

			-- Verify event loop is still running
			if
				not vimnav.state.eventLoop
				or not vimnav.state.eventLoop:isEnabled()
			then
				vimnav.log.wf(
					"[handleCaffeineEvent] Event loop not running, restarting..."
				)
				EventHandler.stopEventLoop(vimnav)
				EventHandler.startEventLoop(vimnav)
			end

			vimnav.log.df("[handleCaffeineEvent] Recovery complete after wake")
		end)
	elseif eventType == hs.caffeinate.watcher.systemWillSleep then
		vimnav.log.df("[handleCaffeineEvent] System going to sleep")

		CleanupManager.onSleep(vimnav)

		vimnav.log.df("[handleCaffeineEvent] Cleanup complete before sleep")
	end
end

---@param vimnav Hs.Vimnav
function WatcherManager.startCaffeineWatcher(vimnav)
	WatcherManager.stopCaffeineWatcher(vimnav)
	vimnav.state.caffeineWatcher =
		hs.caffeinate.watcher.new(handleCaffeineEvent):start()
	vimnav.log.df(
		"[WatcherManager.startCaffeineWatcher] Caffeine watcher started"
	)
end

---@param vimnav Hs.Vimnav
function WatcherManager.stopCaffeineWatcher(vimnav)
	if vimnav.state.caffeineWatcher then
		vimnav.state.caffeineWatcher:stop()
		vimnav.state.caffeineWatcher = nil
		vimnav.log.df(
			"[WatcherManager.stopCaffeineWatcher] Stopped caffeine watcher"
		)
	end
end

---Clean up timers and watchers
---@param vimnav Hs.Vimnav
---@return nil
function WatcherManager.stopAll(vimnav)
	TimerManager.stopAll(vimnav)
	WatcherManager.stopAppWatcher(vimnav)
	WatcherManager.stopLaunchersWatcher(vimnav)
	WatcherManager.stopScreenWatcher(vimnav)
	WatcherManager.stopCaffeineWatcher(vimnav)
end

--------------------------------------------------------------------------------
-- Cleanup Manager
--------------------------------------------------------------------------------

---Light cleanup - resets input states
---@param vimnav Hs.Vimnav
---@return nil
function CleanupManager.light(vimnav)
	vimnav.log.df("[CleanupManager.light] Performing light cleanup")
	State.resetInput(vimnav)
end

---Medium cleanup - clears UI elements and focus state
---@param vimnav Hs.Vimnav
---@return nil
function CleanupManager.medium(vimnav)
	vimnav.log.df("[CleanupManager.medium] Performing medium cleanup")

	-- First do light cleanup
	CleanupManager.light(vimnav)

	-- Clear UI elements
	Marks.clear(vimnav)
	Whichkey.hide(vimnav)

	-- Reset focus state
	State.resetFocus(vimnav)
end

---Heavy cleanup - clears caches and forces GC
---@param vimnav Hs.Vimnav
---@return nil
function CleanupManager.heavy(vimnav)
	vimnav.log.df("[CleanupManager.heavy] Performing heavy cleanup")

	-- First do medium cleanup
	CleanupManager.medium(vimnav)

	-- Clear all caches
	CacheManager.clearAll(vimnav)
	CacheManager.collectGarbage(vimnav)
end

---Full cleanup - stops timers and performs complete reset
---@param vimnav Hs.Vimnav
---@return nil
function CleanupManager.full(vimnav)
	vimnav.log.df("[CleanupManager.full] Performing full cleanup")

	-- First do heavy cleanup
	CleanupManager.heavy(vimnav)

	-- Stop all timers
	TimerManager.stopAll(vimnav)

	-- Hide all UI elements
	if vimnav.state.markCanvas then
		pcall(function()
			vimnav.state.markCanvas:hide()
		end)
	end
	if vimnav.state.overlayCanvas then
		pcall(function()
			vimnav.state.overlayCanvas:hide()
		end)
	end
	if vimnav.state.whichkeyCanvas then
		pcall(function()
			vimnav.state.whichkeyCanvas:hide()
		end)
	end
end

---Cleanup for app switching - medium + element cache
---@param vimnav Hs.Vimnav
---@return nil
function CleanupManager.onAppSwitch(vimnav)
	vimnav.log.df("[CleanupManager.onAppSwitch] App switch cleanup")
	CleanupManager.heavy(vimnav)
end

---Cleanup before sleep - full cleanup with UI hiding
---@param vimnav Hs.Vimnav
---@return nil
function CleanupManager.onSleep(vimnav)
	vimnav.log.df("[CleanupManager.onSleep] Sleep cleanup")
	CleanupManager.full(vimnav)
end

---Cleanup on wake - just heavy, no timer stop
---@param vimnav Hs.Vimnav
function CleanupManager.onWake(vimnav)
	vimnav.log.df("[CleanupManager.onWake] Wake cleanup")
	CleanupManager.heavy(vimnav)
end

---Cleanup on mode change - light cleanup only
---@param vimnav Hs.Vimnav
---@param fromMode number
---@param toMode number
---@return nil
function CleanupManager.onModeChange(vimnav, fromMode, toMode)
	vimnav.log.df(
		"[CleanupManager.onModeChange] Mode change: %s -> %s",
		fromMode,
		toMode
	)

	-- Always do light cleanup on mode change
	CleanupManager.light(vimnav)

	-- Clear marks when leaving LINKS mode
	if fromMode == Constants.MODES.LINKS then
		Marks.clear(vimnav)
	end

	-- Clear marks when entering certain modes
	if
		toMode == Constants.MODES.NORMAL
		or toMode == Constants.MODES.PASSTHROUGH
	then
		Marks.clear(vimnav)
	end
end

---Cleanup when command execution completes
---@param vimnav Hs.Vimnav
---@return nil
function CleanupManager.onCommandComplete(vimnav)
	vimnav.log.df("[CleanupManager.onCommandComplete] Command complete cleanup")

	State.resetLeader(vimnav)
	State.resetKeyCapture(vimnav)

	if vimnav.state.showingHelp then
		State.resetHelp(vimnav)
	else
		Whichkey.hide(vimnav)
	end
end

---Cleanup when escape is pressed
---@param vimnav Hs.Vimnav
---@return nil
function CleanupManager.onEscape(vimnav)
	vimnav.log.df("[CleanupManager.onEscape] Escape cleanup")

	CleanupManager.light(vimnav)
	Whichkey.hide(vimnav)
	MenuBar.setTitle(vimnav, vimnav.state.mode)
	Overlay.update(vimnav, vimnav.state.mode)
end

---Cleanup on screen change
---@param vimnav Hs.Vimnav
function CleanupManager.onScreenChange(vimnav)
	vimnav.log.df("[CleanupManager.onScreenChange] Screen changed")

	-- Only clear element cache (positions changed)
	CacheManager.clearElements(vimnav)

	-- Recreate overlay if enabled
	if
		vimnav.config.overlay.enabled
		and vimnav.state.mode ~= Constants.MODES.DISABLED
	then
		Overlay.destroy(vimnav)
		hs.timer.doAfter(0.1, function()
			Overlay.create(vimnav)
			Overlay.update(vimnav, vimnav.state.mode)
		end)
	end

	-- Redraw marks if showing
	if vimnav.state.markCanvas and #vimnav.state.marks > 0 then
		hs.timer.doAfter(0.2, function()
			Marks.draw(vimnav)
		end)
	end
end

--------------------------------------------------------------------------------
-- Cache Manager
--------------------------------------------------------------------------------

---Clear element cache
---@param vimnav Hs.Vimnav
function CacheManager.clearElements(vimnav)
	vimnav.cache.elements = setmetatable({}, { __mode = "k" })
	vimnav.cache.attributes = setmetatable({}, { __mode = "k" })
	vimnav.log.df("[CacheManager.clearElements] Element cache cleared")
end

---Clear electron cache
---@param vimnav Hs.Vimnav
function CacheManager.clearElectron(vimnav)
	vimnav.cache.electron = setmetatable({}, { __mode = "k" })
	vimnav.log.df("[CacheManager.clearElectron] Electron cache cleared")
end

---Clear canvas template cache
---@param vimnav Hs.Vimnav
function CacheManager.clearCanvasTemplate(vimnav)
	CanvasCache.template = nil
	vimnav.log.df(
		"[CacheManager.clearCanvasTemplate] Canvas template cache cleared"
	)
end

---Clear mark pool
---@param vimnav Hs.Vimnav
function CacheManager.clearMarkPool(vimnav)
	MarkPool.releaseAll()
	vimnav.log.df("[CacheManager.clearMarkPool] Mark pool cleared")
end

---Clear all caches
---@param vimnav Hs.Vimnav
function CacheManager.clearAll(vimnav)
	CacheManager.clearElements(vimnav)
	CacheManager.clearElectron(vimnav)
	CacheManager.clearCanvasTemplate(vimnav)
	CacheManager.clearMarkPool(vimnav)
	vimnav.log.df("[CacheManager.clearAll] All caches cleared")
end

---Force garbage collection
---@param vimnav Hs.Vimnav
function CacheManager.collectGarbage(vimnav)
	collectgarbage("collect")
	vimnav.log.df("[CacheManager.collectGarbage] Garbage collected")
end

--------------------------------------------------------------------------------
-- Timer Manager
--------------------------------------------------------------------------------

---Updates focus state (called by timer)
---@param vimnav Hs.Vimnav
---@return nil
local function updateFocusState(vimnav)
	local focusedElement = Elements.getAxFocusedElement(vimnav, true)

	-- Quick check: if same element, skip
	if focusedElement == vimnav.state.focusLastElement then
		return
	end

	vimnav.state.focusLastElement = focusedElement

	if focusedElement then
		local role = Utils.getAttribute(vimnav, focusedElement, "AXRole")
		local isEditable = role and RoleMaps.isEditable(role) or false

		if isEditable ~= vimnav.state.focusCachedResult then
			vimnav.state.focusCachedResult = isEditable

			-- Update mode based on focus change
			if
				isEditable
				and ModeManager.isMode(vimnav, Constants.MODES.NORMAL)
			then
				ModeManager.setModeInsert(vimnav)
			elseif not isEditable then
				if
					ModeManager.isMode(vimnav, Constants.MODES.INSERT)
					or ModeManager.isMode(vimnav, Constants.MODES.INSERT_NORMAL)
					or ModeManager.isMode(vimnav, Constants.MODES.INSERT_VISUAL)
				then
					ModeManager.setModeNormal(vimnav)
				end
			end

			vimnav.log.df(
				"[updateFocusState] Focus changed: editable=%s, role=%s",
				tostring(isEditable),
				tostring(role)
			)
		end
	else
		if vimnav.state.focusCachedResult then
			vimnav.state.focusCachedResult = false
			if
				ModeManager.isMode(vimnav, Constants.MODES.INSERT)
				or ModeManager.isMode(vimnav, Constants.MODES.INSERT_NORMAL)
				or ModeManager.isMode(vimnav, Constants.MODES.INSERT_VISUAL)
			then
				ModeManager.setModeNormal(vimnav)
			end
		end
	end
end

---Starts focus polling
---@param vimnav Hs.Vimnav
---@return nil
function TimerManager.startFocusCheck(vimnav)
	TimerManager.stopFocusCheck(vimnav)

	vimnav.state.focusCheckTimer = hs.timer
		.new(vimnav.config.focus.checkInterval or 0.1, function()
			pcall(updateFocusState, vimnav)
		end)
		:start()

	vimnav.log.df("[TimerManager.startFocusCheck] Focus polling started")
end

---Stop focus check timer
---@param vimnav Hs.Vimnav
function TimerManager.stopFocusCheck(vimnav)
	if vimnav.state.focusCheckTimer then
		vimnav.state.focusCheckTimer:stop()
		vimnav.state.focusCheckTimer = nil
		vimnav.log.df("[TimerManager.stopFocusCheck] Stopped")
	end
end

---Start Periodic cache cleanup to prevent memory leaks
---@param vimnav Hs.Vimnav
---@return nil
function TimerManager.startPeriodicCleanup(vimnav)
	TimerManager.stopPeriodicCleanup(vimnav)

	vimnav.state.cleanupTimer = hs.timer
		.new(30, function() -- Every 30 seconds
			-- Only clean up if we're not actively showing marks
			if vimnav.state.mode ~= Constants.MODES.LINKS then
				CleanupManager.medium(vimnav)
				vimnav.log.df(
					"[TimerManager.setupPeriodicCleanup] Periodic cache cleanup completed"
				)
			end
		end)
		:start()
end

---Stop cleanup timer
---@param vimnav Hs.Vimnav
function TimerManager.stopPeriodicCleanup(vimnav)
	if vimnav.state.cleanupTimer then
		vimnav.state.cleanupTimer:stop()
		vimnav.state.cleanupTimer = nil
		vimnav.log.df("[TimerManager.stopCleanup] Stopped")
	end
end

---Stop which-key timer
---@param vimnav Hs.Vimnav
function TimerManager.stopWhichkey(vimnav)
	if vimnav.state.whichkeyTimer then
		vimnav.state.whichkeyTimer:stop()
		vimnav.state.whichkeyTimer = nil
		vimnav.log.df("[TimerManager.stopWhichkey] Stopped")
	end
end

---Stop all timers
---@param vimnav Hs.Vimnav
function TimerManager.stopAll(vimnav)
	TimerManager.stopFocusCheck(vimnav)
	TimerManager.stopPeriodicCleanup(vimnav)
	TimerManager.stopWhichkey(vimnav)
	vimnav.log.df("[TimerManager.stopAll] All timers stopped")
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@type Hs.Vimnav.Config
---@diagnostic disable-next-line: missing-fields
M.config = {}

---@type Hs.Vimnav.State
M.state = {}

M.log = nil

---@type Hs.Vimnav.Cache
M.cache = {}

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
	self.log = hs.logger.new(M.name, "info")

	self._initialized = true
	self.log.i("[M:init] Initialized")

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

	self.config = Config:new(userConfig, opts)

	-- Reinitialize logger with configured level
	self.log = hs.logger.new(M.name, self.config.logLevel)

	self.log.i("[M:configure] Configured")

	return self
end

---Starts the module
---@return Hs.Vimnav
function M:start()
	if self._running then
		self.log.w("[M:start] Vimnav already running")
		return self
	end

	if not self.config or not next(self.config) then
		self:configure({})
	end

	self.cache = Cache:new()

	self.state = State:new()

	Utils.fetchMappingPrefixes(self)
	Utils.generateCombinations(self)
	RoleMaps.init(self) -- Initialize role maps for performance

	WatcherManager.stopAll(self)
	WatcherManager.startAppWatcher(self)
	WatcherManager.startLaunchersWatcher(self)
	WatcherManager.startScreenWatcher(self)
	WatcherManager.startCaffeineWatcher(self)
	TimerManager.startPeriodicCleanup(self)
	MenuBar.create(self)
	Overlay.create(self)

	local currentApp = Elements.getApp(self)
	if
		currentApp
		and Utils.tblContains(
			self.config.applicationGroups.exclusions,
			currentApp:name()
		)
	then
		ModeManager.setModeDisabled(self)
	else
		ModeManager.setModeNormal(self)
	end

	self._running = true
	self.log.i("[M:start] Started")

	return self
end

---Stops the module
---@return Hs.Vimnav
function M:stop()
	if not self._running then
		return self
	end

	self.log.i("[M:stop] Stopping Vimnav")

	WatcherManager.stopAll(self)
	EventHandler.stopEventLoop(self)

	MenuBar.destroy(self)
	Overlay.destroy(self)
	Marks.clear(self)

	CleanupManager.full(self)

	-- reset electron cache as well
	CacheManager.clearElectron(vimnav)

	State.resetAll(self)

	self._running = false
	self.log.i("[M:stop] Vimnav stopped")

	return self
end

---Restarts the module
---@return Hs.Vimnav
function M:restart()
	self.log.i("[M:restart] Restarting Vimnav...")
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
		config = self.config,
		state = self.state,
		caches = self.cache,
	}
end

---Returns default config
---@return table
function M:getDefaultConfig()
	return Config:getDefaultConfig()
end

return M
