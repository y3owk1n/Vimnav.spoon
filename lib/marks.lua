local Config = require("lib.config")
local Cache = require("lib.cache")
local Utils = require("lib.utils")
local State = require("lib.state")
local Log = require("lib.log")
local Elements = require("lib.elements")
local Modes = require("lib.modes")

local M = {}

---Clears the marks
---@return nil
function M.clear()
	State:resetMarkCanvas()
	State:resetMarks()
	State:resetLinkCapture()
	Cache:clearMarks()
	Log.log.df("[Marks.clear] Cleared marks")
end

---Adds a mark to the list
---@param element table
---@return nil
function M.add(element)
	if #State.state.marks >= State.state.maxElements then
		return
	end

	local frame = Cache:getAttribute(element, "AXFrame")
	if not frame or frame.w <= 2 or frame.h <= 2 then
		return
	end

	local mark = Cache:getMark()
	mark.element = element
	mark.frame = frame
	mark.role = Cache:getAttribute(element, "AXRole")

	State.state.marks[#State.state.marks + 1] = mark
end

---Show marks
---@param opts Hs.Vimnav.Marks.ShowOpts
---@return nil
function M.show(opts)
	local axApp = Elements.getAxApp()
	if not axApp then
		return
	end

	local withUrls = opts.withUrls or false
	local elementType = opts.elementType

	M.clear()

	if elementType == "link" then
		local function _callback(elements)
			-- Convert to marks
			for i = 1, math.min(#elements, State.state.maxElements) do
				M.add(elements[i])
			end

			if #State.state.marks > 0 then
				M.draw()
			else
				hs.alert.show("No links found", nil, nil, 1)
				Modes.setModeNormal()
				M.clear()
			end
		end
		Elements.findClickableElements(axApp, {
			withUrls = withUrls,
			callback = _callback,
		})
	elseif elementType == "input" then
		local function _callback(elements)
			for i = 1, #elements do
				M.add(elements[i])
			end
			if #State.state.marks > 0 then
				M.draw()
			else
				hs.alert.show("No inputs found", nil, nil, 1)
				Modes.setModeNormal()
				M.clear()
			end
		end
		Elements.findInputElements(axApp, {
			callback = _callback,
		})
	elseif elementType == "image" then
		local function _callback(elements)
			for i = 1, #elements do
				M.add(elements[i])
			end
			if #State.state.marks > 0 then
				M.draw()
			else
				hs.alert.show("No images found", nil, nil, 1)
				Modes.setModeNormal()
				M.clear()
			end
		end
		Elements.findImageElements(axApp, {
			callback = _callback,
		})
	end
end

---Draws the marks
---@return nil
function M.draw()
	if not State.state.markCanvas then
		local frame = Elements.getFullArea()
		if not frame then
			return
		end
		State.state.markCanvas = hs.canvas.new(frame)
	end

	local captureLen = #State.state.linkCapture
	local elementsToDraw = {}
	local template = M.getMarkTemplate()

	local count = 0
	for i = 1, #State.state.marks do
		if count >= #State.state.allCombinations then
			break
		end

		local mark = State.state.marks[i]
		local markText = State.state.allCombinations[i]:upper()

		if
			captureLen == 0
			or markText:sub(1, captureLen) == State.state.linkCapture
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
				local fontSize = Config.config.hints.fontSize
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

	State.state.markCanvas:replaceElements(elementsToDraw)
	State.state.markCanvas:show()
end

---Clicks a mark
---@param combination string
---@return nil
function M.click(combination)
	for i, c in ipairs(State.state.allCombinations) do
		if
			c == combination
			and State.state.marks[i]
			and State.state.onClickCallback
		then
			local success, err =
				pcall(State.state.onClickCallback, State.state.marks[i])
			if not success then
				Log.log.ef(
					"[Marks.click] Error clicking element: " .. tostring(err)
				)
			end
			break
		end
	end
end

---Returns the mark template
---@return table
function M.getMarkTemplate()
	if Cache.cache.canvasTemplate then
		return Cache.cache.canvasTemplate
	end

	local gradientFrom =
		Utils.hexToRgb(Config.config.hints.colors.from or "#FFF585")
	local gradientTo =
		Utils.hexToRgb(Config.config.hints.colors.to or "#FFC442")
	local gradientAngle = Config.config.hints.colors.angle or 0
	local borderColor =
		Utils.hexToRgb(Config.config.hints.colors.border or "#000000")
	local borderWidth = Config.config.hints.colors.borderWidth or 1

	local textColor =
		Utils.hexToRgb(Config.config.hints.colors.textColor or "#000000")

	Cache.cache.canvasTemplate = {
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
			textSize = Config.config.hints.fontSize,
			textFont = Config.config.hints.textFont
				or ".AppleSystemUIFontHeavy",
		},
	}

	if borderWidth > 0 then
		Cache.cache.canvasTemplate.background.action = "strokeAndFill"
		Cache.cache.canvasTemplate.background.strokeColor = borderColor
		Cache.cache.canvasTemplate.background.strokeWidth = borderWidth
	end

	return Cache.cache.canvasTemplate
end

return M
