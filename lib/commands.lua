---@diagnostic disable: undefined-global

local Actions = require("lib.actions")
local Config = require("lib.config")
local Utils = require("lib.utils")
local Cache = require("lib.cache")
local Elements = require("lib.elements")
local Log = require("lib.log")
local Marks = require("lib.marks")

local M = {}

---Scrolls left
---@return nil
function M.scrollLeft()
	Log.log.df("[Commands.scrollLeft] Scrolling left")

	Actions.smoothScroll({ x = Config.config.scroll.scrollStep })
end

---Scrolls right
---@return nil
function M.scrollRight()
	Log.log.df("[Commands.scrollRight] Scrolling right")

	Actions.smoothScroll({ x = -Config.config.scroll.scrollStep })
end

---Scrolls up
---@return nil
function M.scrollUp()
	Log.log.df("[Commands.scrollUp] Scrolling up")

	Actions.smoothScroll({ y = Config.config.scroll.scrollStep })
end

---Scrolls down
---@return nil
function M.scrollDown()
	Log.log.df("[Commands.scrollDown] Scrolling down")

	Actions.smoothScroll({ y = -Config.config.scroll.scrollStep })
end

---Scrolls half page down
---@return nil
function M.scrollHalfPageDown()
	Log.log.df("[Commands.scrollHalfPageDown] Scrolling half page down")

	Actions.smoothScroll({ y = -Config.config.scroll.scrollStepHalfPage })
end

---Scrolls half page up
---@return nil
function M.scrollHalfPageUp()
	Log.log.df("[Commands.scrollHalfPageUp] Scrolling half page up")

	Actions.smoothScroll({ y = Config.config.scroll.scrollStepHalfPage })
end

---Scrolls to top
---@return nil
function M.scrollToTop()
	Log.log.df("[Commands.scrollToTop] Scrolling to top")

	Actions.smoothScroll({ y = Config.config.scroll.scrollStepFullPage })
end

---Scrolls to bottom
---@return nil
function M.scrollToBottom()
	Log.log.df("[Commands.scrollToBottom] Scrolling to bottom")

	Actions.smoothScroll({ y = -Config.config.scroll.scrollStepFullPage })
end

function M.showHelp()
	Log.log.df("[Commands.showHelp] Showing help for whichkey")

	require("lib.whichkey"):show("")
end

---Switches to passthrough mode
---@return boolean
function M.enterPassthroughMode()
	Log.log.df("[Commands.enterPassthroughMode] Entering passthrough mode")

	return require("lib.modes"):setModePassthrough()
end

---Switches to insert mode
---@return boolean
function M.enterInsertMode()
	Log.log.df("[Commands.enterInsertMode] Entering insert mode")

	return require("lib.modes"):setModeInsert()
end

---Switches to insert mode and make a new line above
---@return boolean
function M.enterInsertModeNewLineAbove()
	Log.log.df(
		"[Commands.enterInsertModeNewLineAbove] Entering insert mode with new line above"
	)

	Utils.keyStroke({}, "up")
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return M.enterInsertMode()
end

---Switches to insert mode and make a new line below
---@return boolean
function M.enterInsertModeNewLineBelow()
	Log.log.df(
		"[Commands.enterInsertModeNewLineBelow] Entering insert mode with new line below"
	)

	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return M.enterInsertMode()
end

---Switches to insert mode and put cursor at the end of the line
---@return boolean
function M.enterInsertModeEndOfLine()
	Log.log.df(
		"[Commands.enterInsertModeEndOfLine] Entering insert mode with cursor at end of line"
	)

	Utils.keyStroke("cmd", "right")
	return M.enterInsertMode()
end

---Switches to insert mode and put cursor at the start of the line
---@return boolean
function M.enterInsertModeStartLine()
	Log.log.df(
		"[Commands.enterInsertModeStartLine] Entering insert mode with cursor at start of line"
	)

	Utils.keyStroke("cmd", "left")
	return M.enterInsertMode()
end

---Switches to insert visual mode
---@return boolean
function M.enterInsertVisualMode()
	Log.log.df("[Commands.enterInsertVisualMode] Entering insert visual mode")

	return require("lib.modes"):setModeInsertVisual()
end

---Switches to visual mode
---@return boolean
function M.enterVisualMode()
	Log.log.df("[Commands.enterVisualMode] Entering visual mode")

	return require("lib.modes"):setModeVisual()
end

---Switches to insert visual mode with line selection
---@return boolean
function M.enterInsertVisualLineMode()
	Log.log.df(
		"[Commands.enterInsertVisualLineMode] Entering insert visual line mode"
	)

	-- set cursor to start of line first
	M.bufferMoveLineStart()

	local ok = M.enterInsertVisualMode()

	if ok then
		local buffer = require("lib.buffer")

		if not buffer:selectLine() then
			Utils.keyStroke("cmd", "left")
			Utils.keyStroke({ "shift", "cmd" }, "right")
		end
	end

	return ok
end

---Switches to links mode
---@return nil
function M.gotoLink()
	Log.log.df("[Commands.gotoLink] Going to link")

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.gotoLink] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.gotoLink] Click callback")
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
		Log.log.df("[Commands.gotoLink] Showing marks")
		require("lib.marks"):show({ elementType = "link" })
	end)
end

---Go to input mode
---@return nil
function M.gotoInput()
	Log.log.df("[Commands.gotoInput] Going to input")

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.gotoInput] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.gotoInput] Click callback")
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
		Log.log.df("[Commands.gotoInput] Showing marks")
		require("lib.marks"):show({ elementType = "input" })
	end)
end

---Double left click
---@return nil
function M.doubleLeftClick()
	Log.log.df("[Commands.doubleLeftClick] Double left click")
	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.doubleLeftClick] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.doubleLeftClick] Click callback")
		local frame = mark.frame

		Actions.tryClick(frame, { doubleClick = true })
	end

	hs.timer.doAfter(0, function()
		Log.log.df("[Commands.doubleLeftClick] Showing marks")
		require("lib.marks"):show({ elementType = "link" })
	end)
end

---Right click
---@return nil
function M.rightClick()
	Log.log.df("[Commands.rightClick] Right click")
	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.rightClick] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.rightClick] Click callback")
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
		Log.log.df("[Commands.rightClick] Showing marks")
		require("lib.marks"):show({ elementType = "link" })
	end)
end

---Go to link in new tab
---@return nil
function M.gotoLinkNewTab()
	Log.log.df("[Commands.gotoLinkNewTab] Going to link in new tab")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.gotoLinkNewTab] Not in browser")
		return
	end

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.gotoLinkNewTab] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.gotoLinkNewTab] Click callback")
		local url = Cache:getAttribute(mark.element, "AXURL")
		if url then
			Actions.openUrlInNewTab(url.url)
		end
	end

	hs.timer.doAfter(0, function()
		Log.log.df("[Commands.gotoLinkNewTab] Showing marks")
		require("lib.marks"):show({ elementType = "link", withUrls = true })
	end)
end

---Download image
---@return nil
function M.downloadImage()
	Log.log.df("[Commands.downloadImage] Downloading image")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.downloadImage] Not in browser")
		return
	end

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.downloadImage] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.downloadImage] Click callback")

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
		Log.log.df("[Commands.downloadImage] Showing marks")
		require("lib.marks"):show({ elementType = "image" })
	end)
end

---Move mouse to link
---@return nil
function M.moveMouseToLink()
	Log.log.df("[Commands.moveMouseToLink] Moving mouse to link")

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.moveMouseToLink] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.moveMouseToLink] Click callback")

		local frame = mark.frame
		if frame then
			hs.mouse.absolutePosition({
				x = frame.x + frame.w / 2,
				y = frame.y + frame.h / 2,
			})
		end
	end

	hs.timer.doAfter(0, function()
		Log.log.df("[Commands.moveMouseToLink] Showing marks")
		require("lib.marks"):show({ elementType = "link" })
	end)
end

---Copy link URL to clipboard
---@return nil
function M.copyLinkUrlToClipboard()
	Log.log.df(
		"[Commands.copyLinkUrlToClipboard] Copying link URL to clipboard"
	)

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.copyLinkUrlToClipboard] Not in browser")
		return
	end

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef(
			"[Commands.copyLinkUrlToClipboard] Failed to set mode to link"
		)
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.copyLinkUrlToClipboard] Click callback")

		local url = Cache:getAttribute(mark.element, "AXURL")
		if url then
			Actions.setClipboardContents(url.url)
		else
			hs.alert.show("No URL found", nil, nil, 2)
		end
	end

	hs.timer.doAfter(0, function()
		Log.log.df("[Commands.copyLinkUrlToClipboard] Showing marks")
		require("lib.marks"):show({ elementType = "link", withUrls = true })
	end)
end

---Next page
---@return nil
function M.gotoNextPage()
	Log.log.df("[Commands.gotoNextPage] Going to next page")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.gotoNextPage] Not in browser")
		return
	end

	local axWindow = Elements.getAxWindow()
	if not axWindow then
		Log.log.ef("[Commands.gotoNextPage] No AXWindow found")
		return
	end

	local function _callback(elements)
		Log.log.df("[Commands.gotoNextPage] Callback")

		if #elements > 0 then
			elements[1]:performAction("AXPress")
			Log.log.df("[Commands.gotoNextPage] Performed action")
		else
			hs.alert.show("No next button found", nil, nil, 2)
			Log.log.ef("[Commands.gotoNextPage] No next button found")
		end
	end

	Elements.findNextButtonElements(axWindow, {
		callback = _callback,
	})
end

---Prev page
---@return nil
function M.gotoPrevPage()
	Log.log.df("[Commands.gotoPrevPage] Going to previous page")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.gotoPrevPage] Not in browser")
		return
	end

	local axWindow = Elements.getAxWindow()
	if not axWindow then
		Log.log.ef("[Commands.gotoPrevPage] No AXWindow found")
		return
	end

	local function _callback(elements)
		Log.log.df("[Commands.gotoPrevPage] Callback")

		if #elements > 0 then
			elements[1]:performAction("AXPress")
			Log.log.df("[Commands.gotoPrevPage] Performed action")
		else
			hs.alert.show("No previous button found", nil, nil, 2)
			Log.log.ef("[Commands.gotoPrevPage] No previous button found")
		end
	end

	Elements.findPrevButtonElements(axWindow, { callback = _callback })
end

---Copy page URL to clipboard
---@return nil
function M.copyPageUrlToClipboard()
	Log.log.df(
		"[Commands.copyPageUrlToClipboard] Copying page URL to clipboard"
	)

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.copyPageUrlToClipboard] Not in browser")
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
	Log.log.df("[Commands.moveMouseToCenter] Moving mouse to center")

	local window = Elements.getWindow()
	if not window then
		Log.log.ef("[Commands.moveMouseToCenter] No window found")
		return
	end

	local frame = window:frame()
	hs.mouse.absolutePosition({
		x = frame.x + frame.w / 2,
		y = frame.y + frame.h / 2,
	})
end

---Yank highlighted
---@return nil
function M.yankHighlighted()
	Log.log.df("[Commands.yankHighlighted] Yanking highlighted")

	Utils.keyStroke("cmd", "c")
	Utils.keyStroke({}, "right")
end
function M.bufferMoveLeft()
	local ok = require("lib.buffer"):moveCursorX(-1)

	if not ok then
		Utils.keyStroke({}, "left")
	end
end

function M.bufferMoveRight()
	local ok = require("lib.buffer"):moveCursorX(1)

	if not ok then
		Utils.keyStroke({}, "right")
	end
end

function M.bufferMoveUp()
	local ok = require("lib.buffer"):moveLineUp()
	if not ok then
		Utils.keyStroke({}, "up")
	end
end

function M.bufferMoveDown()
	local ok = require("lib.buffer"):moveLineDown()
	if not ok then
		Utils.keyStroke({}, "down")
	end
end

function M.bufferMoveWordForward()
	local ok = require("lib.buffer"):moveWordForward()
	if not ok then
		Utils.keyStroke({ "alt" }, "right")
	end
end

function M.bufferMoveWordBackward()
	local ok = require("lib.buffer"):moveWordBackward()
	if not ok then
		Utils.keyStroke({ "alt" }, "left")
	end
end

function M.bufferMoveWordEnd()
	local ok = require("lib.buffer"):moveWordEnd()
	if not ok then
		Utils.keyStroke({ "alt" }, "right")
	end
end

function M.bufferMoveLineStart()
	local ok = require("lib.buffer"):moveLineStart()
	if not ok then
		Utils.keyStroke({ "cmd" }, "left")
	end
end

function M.bufferMoveLineEnd()
	local ok = require("lib.buffer"):moveLineEnd()
	if not ok then
		Utils.keyStroke({ "cmd" }, "right")
	end
end

function M.bufferMoveLineFirstNonBlank()
	local ok = require("lib.buffer"):moveLineFirstNonBlank()
	if not ok then
		Utils.keyStroke({ "cmd" }, "left")
	end
end

function M.bufferMoveDocStart()
	local ok = require("lib.buffer"):moveDocStart()
	if not ok then
		Utils.keyStroke({ "cmd" }, "up")
	end
end

function M.bufferMoveDocEnd()
	local ok = require("lib.buffer"):moveDocEnd()
	if not ok then
		Utils.keyStroke({ "cmd" }, "down")
	end
end

function M.bufferDeleteInnerWord()
	local buffer = require("lib.buffer")
	if buffer:selectInnerWord() then
		Utils.keyStroke({}, "delete")
	else
		Utils.keyStroke("alt", "right")
		Utils.keyStroke("alt", "delete")
	end
end

function M.bufferChangeInnerWord()
	local buffer = require("lib.buffer")
	if buffer:selectInnerWord() then
		Utils.keyStroke({}, "delete")
	else
		Utils.keyStroke("alt", "right")
		Utils.keyStroke("alt", "delete")
	end

	require("lib.modes"):setModeInsert()
end

function M.bufferYankInnerWord()
	local buffer = require("lib.buffer")
	local _pos = buffer:getCursorPosition()

	if buffer:selectInnerWord() then
		Utils.keyStroke({ "cmd" }, "c")
		hs.timer.doAfter(0.05, function()
			buffer:setCursorPosition(_pos)
		end)
	else
		Utils.keyStroke("alt", "right")
		Utils.keyStroke({ "shift", "alt" }, "left")
		Utils.keyStroke("cmd", "c")
		Utils.keyStroke({}, "right")
	end
end

function M.bufferDeleteLine()
	local buffer = require("lib.buffer")

	if buffer:selectLine() then
		Utils.keyStroke({}, "delete")
	else
		Utils.keyStroke("cmd", "right")
		Utils.keyStroke("cmd", "delete")
	end
end

function M.bufferChangeLine()
	local buffer = require("lib.buffer")

	if buffer:selectLine() then
		Utils.keyStroke({}, "delete")
	else
		-- Fallback: go to most right and delete
		Utils.keyStroke("cmd", "right")
		Utils.keyStroke("cmd", "delete")
	end
	require("lib.modes"):setModeInsert()
end

function M.bufferYankLine()
	local buffer = require("lib.buffer")
	local _pos = buffer:getCursorPosition()

	if buffer:selectLine() then
		Utils.keyStroke({ "cmd" }, "c")
		hs.timer.doAfter(0.05, function()
			buffer:setCursorPosition(_pos)
		end)
	else
		-- Fallback: go to most right and copy
		Utils.keyStroke("cmd", "left")
		Utils.keyStroke({ "shift", "cmd" }, "right")
		Utils.keyStroke("cmd", "c")
		Utils.keyStroke({}, "right")
	end
end

function M.bufferDeleteChar()
	Utils.keyStroke({}, "delete")
end

function M.bufferSelectMoveLeft()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLeft()

	if not ok then
		Utils.keyStroke({ "shift" }, "left")
	end
end

function M.bufferSelectMoveRight()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveRight()

	if not ok then
		Utils.keyStroke({ "shift" }, "right")
	end
end

function M.bufferSelectMoveUp()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineUp()

	if not ok then
		Utils.keyStroke({ "shift" }, "up")
	end
end

function M.bufferSelectMoveDown()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineDown()

	if not ok then
		Utils.keyStroke({ "shift" }, "down")
	end
end

function M.bufferSelectMoveWordForward()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveWordForward()

	if not ok then
		Utils.keyStroke({ "shift", "alt" }, "right")
	end
end

function M.bufferSelectMoveWordBackward()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveWordBackward()

	if not ok then
		Utils.keyStroke({ "shift", "alt" }, "left")
	end
end

function M.bufferSelectMoveLineStart()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineStart()

	if not ok then
		Utils.keyStroke({ "shift", "cmd" }, "left")
	end
end

function M.bufferSelectMoveLineEnd()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineEnd()

	if not ok then
		Utils.keyStroke({ "shift", "cmd" }, "right")
	end
end

function M.bufferSelectMoveLineFirstNonBlank()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineFirstNonBlank()

	if not ok then
		Utils.keyStroke({ "shift", "cmd" }, "left")
	end
end

function M.bufferSelectMoveDocStart()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveDocStart()

	if not ok then
		Utils.keyStroke({ "shift", "cmd" }, "up")
	end
end

function M.bufferSelectMoveDocEnd()
	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveDocEnd()

	if not ok then
		Utils.keyStroke({ "shift", "cmd" }, "down")
	end
end

function M.bufferSelectDelete()
	Utils.keyStroke({}, "delete")
end

function M.bufferSelectChange()
	Utils.keyStroke({}, "delete")

	require("lib.modes"):setModeInsert()
end

function M.bufferSelectYank()
	Utils.keyStroke("cmd", "c")

	local buffer = require("lib.buffer")

	hs.timer.doAfter(0.05, function()
		buffer:setCursorPosition(buffer._visualAnchor)
	end)
end

return M
