---@diagnostic disable: undefined-global

local Config = require("lib.config")
local Modes = require("lib.modes")
local State = require("lib.state")
local Utils = require("lib.utils")
local Log = require("lib.log")

local M = {}

-- This timer is just to used to cancel the popup if it's no longer needed
-- Don't need to put it in timer module
M.whichkeyTimer = nil

---Get available mappings for current prefix
---@param prefix string Current key capture
---@param mapping table Mode mapping table
---@return table Available mappings
function M:getAvailableMappings(prefix, mapping)
	Log.log.df("[Whichkey.getAvailableMappings] Getting available mappings")

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
---@param prefix string Current key capture
---@return nil
function M:show(prefix)
	Log.log.df("[Whichkey.show] Showing which-key popup for prefix: %s", prefix)

	if not Config.config.whichkey.enabled then
		Log.log.df("[Whichkey.show] Which-key disabled")
		return
	end

	M:hide()

	local mapping
	if Modes.isMode(Modes.MODES.NORMAL) then
		mapping = Config.config.mapping.normal
	elseif Modes.isMode(Modes.MODES.VISUAL) then
		mapping = Config.config.mapping.visual
	elseif Modes.isMode(Modes.MODES.INSERT_NORMAL) then
		mapping = Config.config.mapping.insertNormal
	elseif Modes.isMode(Modes.MODES.INSERT_VISUAL) then
		mapping = Config.config.mapping.insertVisual
	else
		return
	end

	local available = M:getAvailableMappings(prefix, mapping)

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
	local fontSize = Config.config.whichkey.fontSize or 14
	local textFont = Config.config.whichkey.textFont
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
	local minRowsPerCol = Config.config.whichkey.minRowsPerCol or 8
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
	State.state.whichkeyCanvas = hs.canvas.new(popupFrame)
	State.state.whichkeyCanvas:level("overlay")
	State.state.whichkeyCanvas:behavior("canJoinAllSpaces")

	-- Build canvas elements
	local elements = {}

	-- Background
	local bgColor =
		Utils.hexToRgb(Config.config.whichkey.colors.background or "#1e1e2e")
	bgColor.alpha = Config.config.whichkey.colors.backgroundAlpha or 0.8
	local borderColor =
		Utils.hexToRgb(Config.config.whichkey.colors.border or "#1e1e2e")

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
		Utils.hexToRgb(Config.config.whichkey.colors.key or "#f9e2af")
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
		Utils.hexToRgb(Config.config.whichkey.colors.separator or "#6c7086")
	local descColor =
		Utils.hexToRgb(Config.config.whichkey.colors.description or "#cdd6f4")

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

	State.state.whichkeyCanvas:replaceElements(elements)
	State.state.whichkeyCanvas:show()
end

---Hide which-key popup
---@return nil
function M:hide()
	Log.log.df("[Whichkey.hide] Hiding which-key popup")

	State:resetWhichkeyCanvas()
	if self.whichkeyTimer then
		self.whichkeyTimer:stop()
		self.whichkeyTimer = nil
	end
end

---Schedule which-key popup to show after delay
---@param prefix string Current key capture
---@return nil
function M:scheduleShow(prefix)
	Log.log.df(
		"[Whichkey.scheduleShow] Scheduling which-key popup for prefix: %s",
		prefix
	)

	if not Config.config.whichkey.enabled then
		Log.log.df("[Whichkey.scheduleShow] Which-key disabled")
		return
	end

	M:hide()

	local delay = Config.config.whichkey.delay or 0.5
	self.whichkeyTimer = hs.timer.doAfter(delay, function()
		M:show(prefix)
	end)
end

return M
