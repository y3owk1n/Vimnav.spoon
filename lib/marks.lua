---@diagnostic disable: undefined-global

local Config = require("lib.config")
local Cache = require("lib.cache")
local Utils = require("lib.utils")
local Log = require("lib.log")
local Elements = require("lib.elements")
local Modes = require("lib.modes")
local Mappings = require("lib.mappings")

local M = {}

---@type table
M.canvas = nil

---@type table
M.marks = {}

---@type fun(any): nil
M.onClickCallback = nil

---Clears the marks
---@return nil
function M:clear()
	Log.log.df("[Marks.clear] Clearing marks")

	if self.canvas then
		self.canvas:delete()
		self.canvas = nil
	end

	self.marks = {}

	require("lib.eventhandler"):resetLinkCapture()
	Cache:clearMarks()
end

---Adds a mark to the list
---@param element table Element to add
---@return nil
function M:add(element)
	Log.log.df("[Marks.add] Adding mark")

	if #self.marks >= Mappings.maxElements then
		Log.log.df("[Marks.add] Reached max marks: %d", Mappings.maxElements)
		return
	end

	local frame = Cache:getAttribute(element, "AXFrame")
	if not frame or frame.w <= 2 or frame.h <= 2 then
		Log.log.df("[Marks.add] Frame is invalid: %s", tostring(frame))
		return
	end

	local mark = Cache:getMark()
	mark.element = element
	mark.frame = frame
	mark.role = Cache:getAttribute(element, "AXRole")

	self.marks[#self.marks + 1] = mark
end

---Show marks
---@param opts Hs.Vimnav.Marks.ShowOpts Opts for showing marks
---@return nil
function M:show(opts)
	Log.log.df("[Marks.show] Showing marks")

	local axApp = Elements.getAxApp()
	if not axApp then
		Log.log.ef("[Marks.show] No AXApp found")
		return
	end

	local withUrls = opts.withUrls or false
	local elementType = opts.elementType

	M:clear()

	if elementType == "link" then
		Log.log.df("[Marks.show] Showing links")

		local function _callback(elements)
			-- Convert to marks
			for i = 1, math.min(#elements, Mappings.maxElements) do
				M:add(elements[i])
			end

			if #self.marks > 0 then
				Log.log.df("[Marks.show] Showing marks for links")
				M:draw()
			else
				Log.log.df("[Marks.show] No links found")
				hs.alert.show("No links found", nil, nil, 1)
				Modes:setModeNormal()
				M:clear()
			end
		end

		Elements.findClickableElements(axApp, {
			withUrls = withUrls,
			callback = _callback,
		})
	elseif elementType == "input" then
		Log.log.df("[Marks.show] Showing inputs")

		local function _callback(elements)
			for i = 1, #elements do
				M:add(elements[i])
			end

			if #self.marks > 0 then
				Log.log.df("[Marks.show] Showing marks for inputs")
				M:draw()
			else
				Log.log.df("[Marks.show] No inputs found")
				hs.alert.show("No inputs found", nil, nil, 1)
				Modes:setModeNormal()
				M:clear()
			end
		end

		Elements.findInputElements(axApp, {
			callback = _callback,
		})
	elseif elementType == "image" then
		Log.log.df("[Marks.show] Showing images")

		local function _callback(elements)
			for i = 1, #elements do
				M:add(elements[i])
			end

			if #self.marks > 0 then
				Log.log.df("[Marks.show] Showing marks for images")
				M:draw()
			else
				Log.log.df("[Marks.show] No images found")
				hs.alert.show("No images found", nil, nil, 1)
				Modes:setModeNormal()
				M:clear()
			end
		end

		Elements.findImageElements(axApp, {
			callback = _callback,
		})
	end
end

---Draws the marks
---@return nil
function M:draw()
	Log.log.df("[Marks.draw] Drawing marks")

	if not self.canvas then
		local frame = Elements.getFullArea()
		if not frame then
			Log.log.ef("[Marks.draw] No frame found")
			return
		end
		self.canvas = hs.canvas.new(frame)
	end

	local linkCapture = require("lib.eventhandler").linkCapture

	local captureLen = #linkCapture
	local elementsToDraw = {}
	local template = M:getMarkTemplate()

	local count = 0
	for i = 1, #self.marks do
		if count >= #Mappings.allCombinations then
			break
		end

		local mark = self.marks[i]
		local markText = Mappings.allCombinations[i]:upper()

		if captureLen == 0 or markText:sub(1, captureLen) == linkCapture then
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

	self.canvas:replaceElements(elementsToDraw)
	self.canvas:show()
end

---Clicks a mark
---@param combination string Combination to click
---@return nil
function M:click(combination)
	Log.log.df("[Marks.click] Clicking mark: %s", combination)

	for i, c in ipairs(Mappings.allCombinations) do
		if c == combination and self.marks[i] and self.onClickCallback then
			local success, err = pcall(self.onClickCallback, self.marks[i])
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
function M:getMarkTemplate()
	Log.log.df("[Marks.getMarkTemplate] Getting mark template")

	if Cache.cache.canvasTemplate then
		Log.log.df("[Marks.getMarkTemplate] Using cached template")
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
