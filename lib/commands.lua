local Actions = require("lib.actions")
local Config = require("lib.config")
local State = require("lib.state")
local Utils = require("lib.utils")
local Cache = require("lib.cache")
local Elements = require("lib.elements")

local M = {}

---Scrolls left
---@return nil
function M.scrollLeft()
	Actions.smoothScroll({ x = Config.config.scroll.scrollStep })
end

---Scrolls right
---@return nil
function M.scrollRight()
	Actions.smoothScroll({ x = -Config.config.scroll.scrollStep })
end

---Scrolls up
---@return nil
function M.scrollUp()
	Actions.smoothScroll({ y = Config.config.scroll.scrollStep })
end

---Scrolls down
---@return nil
function M.scrollDown()
	Actions.smoothScroll({ y = -Config.config.scroll.scrollStep })
end

---Scrolls half page down
---@return nil
function M.scrollHalfPageDown()
	Actions.smoothScroll({ y = -Config.config.scroll.scrollStepHalfPage })
end

---Scrolls half page up
---@return nil
function M.scrollHalfPageUp()
	Actions.smoothScroll({ y = Config.config.scroll.scrollStepHalfPage })
end

---Scrolls to top
---@return nil
function M.scrollToTop()
	Actions.smoothScroll({ y = Config.config.scroll.scrollStepFullPage })
end

---Scrolls to bottom
---@return nil
function M.scrollToBottom()
	Actions.smoothScroll({ y = -Config.config.scroll.scrollStepFullPage })
end

function M.showHelp()
	State.state.showingHelp = true
	require("lib.whichkey").show("")
end

---Switches to passthrough mode
---@return boolean
function M.enterPassthroughMode()
	return require("lib.modes").setModePassthrough()
end

---Switches to insert mode
---@return boolean
function M.enterInsertMode()
	return require("lib.modes").setModeInsert()
end

---Switches to insert mode and make a new line above
---@return boolean
function M.enterInsertModeNewLineAbove()
	Utils.keyStroke({}, "up")
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return M.enterInsertMode()
end

---Switches to insert mode and make a new line below
---@return boolean
function M.enterInsertModeNewLineBelow()
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return M.enterInsertMode()
end

---Switches to insert mode and put cursor at the end of the line
---@return boolean
function M.enterInsertModeEndOfLine()
	Utils.keyStroke("cmd", "right")
	return M.enterInsertMode()
end

---Switches to insert mode and put cursor at the start of the line
---@return boolean
function M.enterInsertModeStartLine()
	Utils.keyStroke("cmd", "left")
	return M.enterInsertMode()
end

---Switches to insert visual mode
---@return boolean
function M.enterInsertVisualMode()
	return require("lib.modes").setModeInsertVisual()
end

---Switches to visual mode
---@return boolean
function M.enterVisualMode()
	return require("lib.modes").setModeVisual()
end

---Switches to insert visual mode with line selection
---@return boolean
function M.enterInsertVisualLineMode()
	Utils.keyStroke("cmd", "left")
	Utils.keyStroke({ "shift", "cmd" }, "right")

	return M.enterInsertVisualMode()
end

---Switches to links mode
---@return nil
function M.gotoLink()
	local ok = require("lib.modes").setModeLink()

	if not ok then
		return
	end

	State.state.onClickCallback = function(mark)
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
		require("lib.marks").show({ elementType = "link" })
	end)
end

---Go to input mode
---@return nil
function M.gotoInput()
	local ok = require("lib.modes").setModeLink()

	if not ok then
		return
	end

	State.state.onClickCallback = function(mark)
		local element = mark.element

		local pressOk = element:performAction("AXPress")

		if pressOk then
			local focused = Cache:getAttribute(element, "AXFocused")
			if not focused then
				Actions.tryClick(mark.frame)
				return
			end
		end

		Actions.tryClick(mark.frame)
	end
	hs.timer.doAfter(0, function()
		require("lib.marks").show({ elementType = "input" })
	end)
end

---Double left click
---@return nil
function M.doubleLeftClick()
	local ok = require("lib.modes").setModeLink()

	if not ok then
		return
	end

	State.state.onClickCallback = function(mark)
		local frame = mark.frame

		Actions.tryClick(frame, { doubleClick = true })
	end
	hs.timer.doAfter(0, function()
		require("lib.marks").show({ elementType = "link" })
	end)
end

---Right click
---@return nil
function M.rightClick()
	local ok = require("lib.modes").setModeLink()

	if not ok then
		return
	end

	State.state.onClickCallback = function(mark)
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
		require("lib.marks").show({ elementType = "link" })
	end)
end

---Go to link in new tab
---@return nil
function M.gotoLinkNewTab()
	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = require("lib.modes").setModeLink()

	if not ok then
		return
	end

	State.state.onClickCallback = function(mark)
		local url = Cache:getAttribute(mark.element, "AXURL")
		if url then
			Actions.openUrlInNewTab(url.url)
		end
	end
	hs.timer.doAfter(0, function()
		require("lib.marks").show({ elementType = "link", withUrls = true })
	end)
end

---Download image
---@return nil
function M.downloadImage()
	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = require("lib.modes").setModeLink()

	if not ok then
		return
	end

	State.state.onClickCallback = function(mark)
		local element = mark.element
		local role = Cache:getAttribute(element, "AXRole")

		if role == "AXImage" then
			local description = Cache:getAttribute(element, "AXDescription")
				or "image"

			local downloadUrlAttr = Cache:getAttribute(element, "AXURL")

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
		require("lib.marks").show({ elementType = "image" })
	end)
end

---Move mouse to link
---@return nil
function M.moveMouseToLink()
	local ok = require("lib.modes").setModeLink()

	if not ok then
		return
	end

	State.state.onClickCallback = function(mark)
		local frame = mark.frame
		if frame then
			hs.mouse.absolutePosition({
				x = frame.x + frame.w / 2,
				y = frame.y + frame.h / 2,
			})
		end
	end
	hs.timer.doAfter(0, function()
		require("lib.marks").show({ elementType = "link" })
	end)
end

---Copy link URL to clipboard
---@return nil
function M.copyLinkUrlToClipboard()
	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local ok = require("lib.modes").setModeLink()

	if not ok then
		return
	end

	State.state.onClickCallback = function(mark)
		local url = Cache:getAttribute(mark.element, "AXURL")
		if url then
			Actions.setClipboardContents(url.url)
		else
			hs.alert.show("No URL found", nil, nil, 2)
		end
	end
	hs.timer.doAfter(0, function()
		require("lib.marks").show({ elementType = "link", withUrls = true })
	end)
end

---Next page
---@return nil
function M.gotoNextPage()
	if not Elements.isInBrowser() then
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

	Elements.findNextButtonElements(axWindow, {
		callback = _callback,
	})
end

---Prev page
---@return nil
function M.gotoPrevPage()
	if not Elements.isInBrowser() then
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

	Elements.findPrevButtonElements(axWindow, { callback = _callback })
end

---Copy page URL to clipboard
---@return nil
function M.copyPageUrlToClipboard()
	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		return
	end

	local axWebArea = Elements.getAxWebArea()
	local url = axWebArea and Cache:getAttribute(axWebArea, "AXURL")
	if url then
		Actions.setClipboardContents(url.url)
	end
end

---Move mouse to center
---@return nil
function M.moveMouseToCenter()
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

function M.deleteWord()
	Utils.keyStroke("alt", "right")
	Utils.keyStroke("alt", "delete")
end

function M.changeWord()
	M.deleteWord()
	require("lib.modes").setModeInsert()
end

function M.yankWord()
	Utils.keyStroke("alt", "right")
	Utils.keyStroke({ "shift", "alt" }, "left")
	Utils.keyStroke("cmd", "c")
	Utils.keyStroke({}, "right")
end

function M.deleteLine()
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("cmd", "delete")
end

function M.changeLine()
	M.deleteLine()
	require("lib.modes").setModeInsert()
end

function M.yankLine()
	Utils.keyStroke("cmd", "left")
	Utils.keyStroke({ "shift", "cmd" }, "right")
	Utils.keyStroke("cmd", "c")
	Utils.keyStroke({}, "right")
end

function M.deleteHighlighted()
	Utils.keyStroke({}, "delete")
end

function M.changeHighlighted()
	M.deleteHighlighted()
	require("lib.modes").setModeInsert()
end

function M.yankHighlighted()
	Utils.keyStroke("cmd", "c")
	Utils.keyStroke({}, "right")
end

return M
