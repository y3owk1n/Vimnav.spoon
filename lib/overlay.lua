local Config = require("lib.config")
local Log = require("lib.log")
local State = require("lib.state")
local Utils = require("lib.utils")

local M = {}

---Creates the overlay indicator
---@return nil
function M.create()
	if not Config.config.overlay.enabled then
		return
	end

	M.destroy()

	local screen = hs.screen.mainScreen()
	local frame = screen:fullFrame()
	local height = Config.config.overlay.size or 30
	local position = Config.config.overlay.position or "top-center"

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

	local padding = Config.config.overlay.padding

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

	State.state.overlayCanvas = hs.canvas.new(overlayFrame)
	State.state.overlayCanvas:level("overlay")
	State.state.overlayCanvas:behavior("canJoinAllSpaces")

	Log.log.df("[Overlay.create] Created overlay indicator at " .. position)
end

---Get color for mode
---@param mode number
---@return table
function M.getModeColor(mode)
	local MODES = require("lib.modes").MODES
	local colors = {
		[MODES.DISABLED] = Utils.hexToRgb(
			Config.config.overlay.colors.disabled or "#5a5672"
		),
		[MODES.NORMAL] = Utils.hexToRgb(
			Config.config.overlay.colors.normal or "#80b8e8"
		),
		[MODES.INSERT] = Utils.hexToRgb(
			Config.config.overlay.colors.insert or "#abe9b3"
		),
		[MODES.VISUAL] = Utils.hexToRgb(
			Config.config.overlay.colors.visual or "#c9a0e9"
		),
		[MODES.INSERT_NORMAL] = Utils.hexToRgb(
			Config.config.overlay.colors.insertNormal or "#f9e2af"
		),
		[MODES.INSERT_VISUAL] = Utils.hexToRgb(
			Config.config.overlay.colors.insertVisual or "#c9a0e9"
		),
		[MODES.LINKS] = Utils.hexToRgb(
			Config.config.overlay.colors.links or "#f8bd96"
		),
		[MODES.PASSTHROUGH] = Utils.hexToRgb(
			Config.config.overlay.colors.passthrough or "#f28fad"
		),
	}
	return colors[mode]
		or Utils.hexToRgb(Config.config.overlay.colors.disabled or "#5a5672")
end

---Updates the overlay indicator
---@param mode number
---@param keys? string|nil
---@return nil
function M.update(mode, keys)
	if not Config.config.overlay.enabled or not State.state.overlayCanvas then
		return
	end

	local color = M.getModeColor(mode)
	local modeChar = require("lib.modes").defaultModeChars[mode] or "?"
	local fontSize = Config.config.overlay.size / 2

	-- Build display text
	local displayText = modeChar
	if keys then
		displayText = string.format("%s [%s]", modeChar, keys)
	end

	local textWidth = #displayText * fontSize
	local height = Config.config.overlay.size or 30
	local newWidth = textWidth < height and height or textWidth

	-- Get current frame
	local currentFrame = State.state.overlayCanvas:frame()
	local screen = hs.screen.mainScreen()
	local screenFrame = screen:fullFrame()
	local position = Config.config.overlay.position or "top-center"

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
	State.state.overlayCanvas:frame({
		x = newX,
		y = currentFrame.y,
		w = newWidth,
		h = height,
	})

	-- Apply alpha to color
	color.alpha = 0.2
	local textColor = M.getModeColor(mode)

	State.state.overlayCanvas:replaceElements({
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
			textFont = Config.config.overlay.textFont
				or ".AppleSystemUIFontBold",
			frame = {
				x = 0,
				y = (height - fontSize) / 2 - 2,
				w = newWidth,
				h = fontSize + 4,
			},
		},
	})
	State.state.overlayCanvas:show()
end

---Destroys the overlay indicator
---@return nil
function M.destroy()
	State:resetOverlayCanvas()
end

return M
