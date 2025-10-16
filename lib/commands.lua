---@diagnostic disable: undefined-global

local Actions = require("lib.actions")
local Config = require("lib.config")
local Utils = require("lib.utils")
local Cache = require("lib.cache")
local Elements = require("lib.elements")
local Log = require("lib.log")
local Marks = require("lib.marks")

local M = {}

--------------------------------------------------------------------------------
-- Scrolling
--------------------------------------------------------------------------------

M.scroll = {}

---Scrolls left
---@return nil
function M.scroll.left()
	Log.log.df("[Commands.scroll.left] Scrolling left")

	Actions.smoothScroll({ x = Config.config.scroll.scrollStep })
end

---Scrolls right
---@return nil
function M.scroll.right()
	Log.log.df("[Commands.scroll.right] Scrolling right")

	Actions.smoothScroll({ x = -Config.config.scroll.scrollStep })
end

---Scrolls up
---@return nil
function M.scroll.up()
	Log.log.df("[Commands.scroll.up] Scrolling up")

	Actions.smoothScroll({ y = Config.config.scroll.scrollStep })
end

---Scrolls down
---@return nil
function M.scroll.down()
	Log.log.df("[Commands.scroll.down] Scrolling down")

	Actions.smoothScroll({ y = -Config.config.scroll.scrollStep })
end

---Scrolls half page down
---@return nil
function M.scroll.HalfPageDown()
	Log.log.df("[Commands.scroll.HalfPageDown] Scrolling half page down")

	Actions.smoothScroll({ y = -Config.config.scroll.scrollStepHalfPage })
end

---Scrolls half page up
---@return nil
function M.scroll.halfPageUp()
	Log.log.df("[Commands.scroll.halfPageUp] Scrolling half page up")

	Actions.smoothScroll({ y = Config.config.scroll.scrollStepHalfPage })
end

---Scrolls to top
---@return nil
function M.scroll.top()
	Log.log.df("[Commands.scroll.top] Scrolling to top")

	Actions.smoothScroll({ y = Config.config.scroll.scrollStepFullPage })
end

---Scrolls to bottom
---@return nil
function M.scroll.bottom()
	Log.log.df("[Commands.scroll.bottom] Scrolling to bottom")

	Actions.smoothScroll({ y = -Config.config.scroll.scrollStepFullPage })
end

--------------------------------------------------------------------------------
-- Whichkey Help
--------------------------------------------------------------------------------

M.whichkey = {}

function M.whichkey.show()
	Log.log.df("[Commands.whichkey.show] Showing help for whichkey")

	require("lib.whichkey"):show("")
end

--------------------------------------------------------------------------------
-- Modes
--------------------------------------------------------------------------------

M.mode = {}

---Switches to passthrough mode
---@return boolean
function M.mode.passthrough()
	Log.log.df("[Commands.mode.passthrough] Entering passthrough mode")

	return require("lib.modes"):setModePassthrough()
end

---Switches to insert mode
---@return boolean
function M.mode.insert()
	Log.log.df("[Commands.mode.insert] Entering insert mode")

	return require("lib.modes"):setModeInsert()
end

---Switches to insert mode and make a new line above
---@return boolean
function M.mode.insertWithNewLineAbove()
	Log.log.df(
		"[Commands.mode.insertWithNewLineAbove] Entering insert mode with new line above"
	)

	Utils.keyStroke({}, "up")
	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return M.mode.insert()
end

---Switches to insert mode and make a new line below
---@return boolean
function M.mode.insertWithNewLineBelow()
	Log.log.df(
		"[Commands.mode.insertWithNewLineBelow] Entering insert mode with new line below"
	)

	Utils.keyStroke("cmd", "right")
	Utils.keyStroke("ctrl", "o")
	Utils.keyStroke({}, "down")
	return M.mode.insert()
end

---Switches to insert mode and put cursor at the end of the line
---@return boolean
function M.mode.insertWithEndOfLine()
	Log.log.df(
		"[Commands.mode.insertWithEndOfLine] Entering insert mode with cursor at end of line"
	)

	Utils.keyStroke("cmd", "right")
	return M.mode.insert()
end

---Switches to insert mode and put cursor at the start of the line
---@return boolean
function M.mode.insertWithStartLine()
	Log.log.df(
		"[Commands.mode.insertWithStartLine] Entering insert mode with cursor at start of line"
	)

	Utils.keyStroke("cmd", "left")
	return M.mode.insert()
end

---Switches to insert visual mode
---@return boolean
function M.mode.insertVisual()
	Log.log.df("[Commands.mode.insertVisual] Entering insert visual mode")

	return require("lib.modes"):setModeInsertVisual()
end

---Switches to visual mode
---@return boolean
function M.mode.visual()
	Log.log.df("[Commands.mode.visual] Entering visual mode")

	return require("lib.modes"):setModeVisual()
end

---Switches to insert visual mode with line selection
---@return boolean
function M.mode.insertVisualLine()
	Log.log.df(
		"[Commands.mode.insertVisualLine] Entering insert visual line mode"
	)

	-- set cursor to start of line first
	M.insertNormal.moveLineStart()

	local ok = M.mode.insertVisual()

	if ok then
		local buffer = require("lib.buffer")

		if not buffer:selectLine() then
			Utils.keyStroke("cmd", "left")
			Utils.keyStroke({ "shift", "cmd" }, "right")
		end
	end

	return ok
end

--------------------------------------------------------------------------------
-- Hints
--------------------------------------------------------------------------------

M.hints = {}

---Switches to links mode
---@return nil
function M.hints.click()
	Log.log.df("[Commands.hints.click] Going to link")

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.hints.click] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.hints.click] Click callback")
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
		Log.log.df("[Commands.hints.click] Showing marks")
		require("lib.marks"):show({ elementType = "link" })
	end)
end

---Go to input mode
---@return nil
function M.hints.input()
	Log.log.df("[Commands.hints.input] Going to input")

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.hints.input] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.hints.input] Click callback")
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
		Log.log.df("[Commands.hints.input] Showing marks")
		require("lib.marks"):show({ elementType = "input" })
	end)
end

---Double left click
---@return nil
function M.hints.doubleClick()
	Log.log.df("[Commands.hints.doubleClick] Double left click")
	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.hints.doubleClick] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.hints.doubleClick] Click callback")
		local frame = mark.frame

		Actions.tryClick(frame, { doubleClick = true })
	end

	hs.timer.doAfter(0, function()
		Log.log.df("[Commands.hints.doubleClick] Showing marks")
		require("lib.marks"):show({ elementType = "link" })
	end)
end

---Right click
---@return nil
function M.hints.rightClick()
	Log.log.df("[Commands.hints.rightClick] Right click")
	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.hints.rightClick] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.hints.rightClick] Click callback")
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
		Log.log.df("[Commands.hints.rightClick] Showing marks")
		require("lib.marks"):show({ elementType = "link" })
	end)
end

---Go to link in new tab
---@return nil
function M.hints.newTab()
	Log.log.df("[Commands.hints.newTab] Going to link in new tab")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.hints.newTab] Not in browser")
		return
	end

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.hints.newTab] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.hints.newTab] Click callback")
		local url = Cache:getAttribute(mark.element, "AXURL")
		if url then
			Actions.openUrlInNewTab(url.url)
		end
	end

	hs.timer.doAfter(0, function()
		Log.log.df("[Commands.hints.newTab] Showing marks")
		require("lib.marks"):show({ elementType = "link", withUrls = true })
	end)
end

---Download image
---@return nil
function M.hints.downloadImage()
	Log.log.df("[Commands.hints.downloadImage] Downloading image")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.hints.downloadImage] Not in browser")
		return
	end

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.hints.downloadImage] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.hints.downloadImage] Click callback")

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
		Log.log.df("[Commands.hints.downloadImage] Showing marks")
		require("lib.marks"):show({ elementType = "image" })
	end)
end

---Move mouse to link
---@return nil
function M.hints.moveMouse()
	Log.log.df("[Commands.hints.moveMouse] Moving mouse to link")

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.hints.moveMouse] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.hints.moveMouse] Click callback")

		local frame = mark.frame
		if frame then
			hs.mouse.absolutePosition({
				x = frame.x + frame.w / 2,
				y = frame.y + frame.h / 2,
			})
		end
	end

	hs.timer.doAfter(0, function()
		Log.log.df("[Commands.hints.moveMouse] Showing marks")
		require("lib.marks"):show({ elementType = "link" })
	end)
end

---Copy link URL to clipboard
---@return nil
function M.hints.copyLink()
	Log.log.df("[Commands.hints.copyLink] Copying link URL to clipboard")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.hints.copyLink] Not in browser")
		return
	end

	local ok = require("lib.modes"):setModeLink()

	if not ok then
		Log.log.ef("[Commands.hints.copyLink] Failed to set mode to link")
		return
	end

	Marks.onClickCallback = function(mark)
		Log.log.df("[Commands.hints.copyLink] Click callback")

		local url = Cache:getAttribute(mark.element, "AXURL")
		if url then
			Actions.setClipboardContents(url.url)
		else
			hs.alert.show("No URL found", nil, nil, 2)
		end
	end

	hs.timer.doAfter(0, function()
		Log.log.df("[Commands.hints.copyLink] Showing marks")
		require("lib.marks"):show({ elementType = "link", withUrls = true })
	end)
end

--------------------------------------------------------------------------------
-- Browser
--------------------------------------------------------------------------------

M.browser = {}

---Next page
---@return nil
function M.browser.nextPage()
	Log.log.df("[Commands.browser.nextPage] Going to next page")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.browser.nextPage] Not in browser")
		return
	end

	local axWindow = Elements.getAxWindow()
	if not axWindow then
		Log.log.ef("[Commands.browser.nextPage] No AXWindow found")
		return
	end

	local function _callback(elements)
		Log.log.df("[Commands.browser.nextPage] Callback")

		if #elements > 0 then
			elements[1]:performAction("AXPress")
			Log.log.df("[Commands.browser.nextPage] Performed action")
		else
			hs.alert.show("No next button found", nil, nil, 2)
			Log.log.ef("[Commands.browser.nextPage] No next button found")
		end
	end

	Elements.findNextButtonElements(axWindow, {
		callback = _callback,
	})
end

---Prev page
---@return nil
function M.browser.prevPage()
	Log.log.df("[Commands.browser.prevPage] Going to previous page")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.browser.prevPage] Not in browser")
		return
	end

	local axWindow = Elements.getAxWindow()
	if not axWindow then
		Log.log.ef("[Commands.browser.prevPage] No AXWindow found")
		return
	end

	local function _callback(elements)
		Log.log.df("[Commands.browser.prevPage] Callback")

		if #elements > 0 then
			elements[1]:performAction("AXPress")
			Log.log.df("[Commands.browser.prevPage] Performed action")
		else
			hs.alert.show("No previous button found", nil, nil, 2)
			Log.log.ef("[Commands.browser.prevPage] No previous button found")
		end
	end

	Elements.findPrevButtonElements(axWindow, { callback = _callback })
end

---Copy page URL to clipboard
---@return nil
function M.browser.copyPageUrl()
	Log.log.df("[Commands.browser.copyPageUrl] Copying page URL to clipboard")

	if not Elements.isInBrowser() then
		hs.alert.show("Only available in browser", nil, nil, 2)
		Log.log.ef("[Commands.browser.copyPageUrl] Not in browser")
		return
	end

	local axWebArea = Elements.getAxWebArea()
	local url = axWebArea and Cache:getAttribute(axWebArea, "AXURL")
	if url then
		Actions.setClipboardContents(url.url)
	end
end

--------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------

M.misc = {}

---Move mouse to center
---@return nil
function M.misc.moveMouseToCenter()
	Log.log.df("[Commands.misc.moveMouseToCenter] Moving mouse to center")

	local window = Elements.getWindow()
	if not window then
		Log.log.ef("[Commands.misc.moveMouseToCenter] No window found")
		return
	end

	local frame = window:frame()
	hs.mouse.absolutePosition({
		x = frame.x + frame.w / 2,
		y = frame.y + frame.h / 2,
	})
end

--------------------------------------------------------------------------------
-- Visual Mode
--------------------------------------------------------------------------------

M.visual = {}

---Yank highlighted
---@return nil
function M.visual.yank()
	Log.log.df("[Commands.visual.yank] Yanking highlighted")

	Utils.keyStroke("cmd", "c")
	Utils.keyStroke({}, "right")
end

--------------------------------------------------------------------------------
-- Insert Normal Mode
--------------------------------------------------------------------------------

M.insertNormal = {}

---Move cursor left
---@return nil
function M.insertNormal.moveLeft()
	Log.log.df("[Commands.insertNormal.moveLeft] Moving left")

	local ok = require("lib.buffer"):moveCursorX(-1)

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveLeft] Failed to move left, fallback to keyStroke"
		)
		Utils.keyStroke({}, "left")
	end
end

---Move cursor right
---@return nil
function M.insertNormal.moveRight()
	Log.log.df("[Commands.insertNormal.moveRight] Moving right")

	local ok = require("lib.buffer"):moveCursorX(1)

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveRight] Failed to move right, fallback to keyStroke"
		)
		Utils.keyStroke({}, "right")
	end
end

---Move cursor up one line
---@return nil
function M.insertNormal.moveUp()
	Log.log.df("[Commands.insertNormal.moveUp] Moving up")

	local ok = require("lib.buffer"):moveLineUp()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveUp] Failed to move up, fallback to keyStroke"
		)
		Utils.keyStroke({}, "up")
	end
end

---Move cursor down one line
---@return nil
function M.insertNormal.moveDown()
	Log.log.df("[Commands.insertNormal.moveDown] Moving down")

	local ok = require("lib.buffer"):moveLineDown()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveDown] Failed to move down, fallback to keyStroke"
		)
		Utils.keyStroke({}, "down")
	end
end

---Move cursor to the next word
---@return nil
function M.insertNormal.moveWordForward()
	Log.log.df("[Commands.insertNormal.moveWordForward] Moving word forward")

	local ok = require("lib.buffer"):moveWordForward()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveWordForward] Failed to move word forward, fallback to keyStroke"
		)
		Utils.keyStroke({ "alt" }, "right")
	end
end

---Move cursor to the previous word
---@return nil
function M.insertNormal.moveWordBackward()
	Log.log.df("[Commands.insertNormal.moveWordBackward] Moving word backward")

	local ok = require("lib.buffer"):moveWordBackward()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveWordBackward] Failed to move word backward, fallback to keyStroke"
		)
		Utils.keyStroke({ "alt" }, "left")
	end
end

---Move cursor to the end of the word
---@return nil
function M.insertNormal.moveWordEnd()
	Log.log.df("[Commands.insertNormal.moveWordEnd] Moving word end")

	local ok = require("lib.buffer"):moveWordEnd()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveWordEnd] Failed to move word end, fallback to keyStroke"
		)
		Utils.keyStroke({ "alt" }, "right")
	end
end

---Move cursor to the start of the line
---@return nil
function M.insertNormal.moveLineStart()
	Log.log.df("[Commands.insertNormal.moveLineStart] Moving line start")

	local ok = require("lib.buffer"):moveLineStart()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveLineStart] Failed to move line start, fallback to keyStroke"
		)
		Utils.keyStroke({ "cmd" }, "left")
	end
end

---Move cursor to the end of the line
---@return nil
function M.insertNormal.moveLineEnd()
	Log.log.df("[Commands.insertNormal.moveLineEnd] Moving line end")

	local ok = require("lib.buffer"):moveLineEnd()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveLineEnd] Failed to move line end, fallback to keyStroke"
		)
		Utils.keyStroke({ "cmd" }, "right")
	end
end

---Move cursor to the first non-blank character of the line
---If it fails, it will fallback to moving to the start of the line
---As there's no default mapping in macos for this
---@return nil
function M.insertNormal.moveLineStartNonBlank()
	Log.log.df(
		"[Commands.insertNormal.moveLineStartNonBlank] Moving line start non-blank"
	)

	local ok = require("lib.buffer"):moveLineFirstNonBlank()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveLineStartNonBlank] Failed to move line start non-blank, fallback to keyStroke"
		)
		Utils.keyStroke({ "cmd" }, "left")
	end
end

---Move cursor to the start of the document
---@return nil
function M.insertNormal.moveDocStart()
	Log.log.df("[Commands.insertNormal.moveDocStart] Moving document start")

	local ok = require("lib.buffer"):moveDocStart()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveDocStart] Failed to move document start, fallback to keyStroke"
		)
		Utils.keyStroke({ "cmd" }, "up")
	end
end

---Move cursor to the end of the document
---@return nil
function M.insertNormal.moveDocEnd()
	Log.log.df("[Commands.insertNormal.moveDocEnd] Moving document end")

	local ok = require("lib.buffer"):moveDocEnd()

	if not ok then
		Log.log.ef(
			"[Commands.insertNormal.moveDocEnd] Failed to move document end, fallback to keyStroke"
		)
		Utils.keyStroke({ "cmd" }, "down")
	end
end

---Delete the inner word (typically `diw`)
---@return nil
function M.insertNormal.deleteInnerWord()
	Log.log.df("[Commands.insertNormal.deleteInnerWord] Deleting inner word")

	local buffer = require("lib.buffer")

	if buffer:selectInnerWord() then
		Utils.keyStroke({}, "delete")
	else
		Log.log.ef(
			"[Commands.insertNormal.deleteInnerWord] Failed to delete inner word, fallback to keyStroke"
		)
		Utils.keyStroke("alt", "right")
		Utils.keyStroke("alt", "delete")
	end
end

---Change the inner word (typically `ciw`)
---@return nil
function M.insertNormal.changeInnerWord()
	Log.log.df("[Commands.insertNormal.changeInnerWord] Changing inner word")

	local buffer = require("lib.buffer")

	if buffer:selectInnerWord() then
		Utils.keyStroke({}, "delete")
	else
		Log.log.ef(
			"[Commands.insertNormal.changeInnerWord] Failed to change inner word, fallback to keyStroke"
		)
		Utils.keyStroke("alt", "right")
		Utils.keyStroke("alt", "delete")
	end

	require("lib.modes"):setModeInsert()
end

---Yank the inner word (typically `yiw`)
---@return nil
function M.insertNormal.yankInnerWord()
	Log.log("insertNormal.yankInnerWord] Yanking inner word")

	local buffer = require("lib.buffer")

	local _pos = buffer:getCursorPosition()

	if buffer:selectInnerWord() then
		Utils.keyStroke({ "cmd" }, "c")
		hs.timer.doAfter(0.05, function()
			buffer:setCursorPosition(_pos)
		end)
	else
		Log.log.ef(
			"[Commands.insertNormal.yankInnerWord] Failed to yank inner word, fallback to keyStroke"
		)
		Utils.keyStroke("alt", "right")
		Utils.keyStroke({ "shift", "alt" }, "left")
		Utils.keyStroke("cmd", "c")
		Utils.keyStroke({}, "right")
	end
end

---Delete the current line (typically `dd`)
---@return nil
function M.insertNormal.deleteLine()
	Log.log.df("[Commands.insertNormal.deleteLine] Deleting line")

	local buffer = require("lib.buffer")

	if buffer:selectLine() then
		Utils.keyStroke({}, "delete")
	else
		Log.log.ef(
			"[Commands.insertNormal.deleteLine] Failed to delete line, fallback to keyStroke"
		)
		Utils.keyStroke("cmd", "right")
		Utils.keyStroke("cmd", "delete")
	end
end

---Change the current line (typically `cc`)
---@return nil
function M.insertNormal.changeLine()
	Log.log.df("[Commands.insertNormal.changeLine] Changing line")

	local buffer = require("lib.buffer")

	if buffer:selectLine() then
		Utils.keyStroke({}, "delete")
	else
		Log.log.ef(
			"[Commands.insertNormal.changeLine] Failed to change line, fallback to keyStroke"
		)
		Utils.keyStroke("cmd", "right")
		Utils.keyStroke("cmd", "delete")
	end

	require("lib.modes"):setModeInsert()
end

---Yank the current line (typically `yy`)
---@return nil
function M.insertNormal.yankLine()
	Log.log.df("[Commands.insertNormal.yankLine] Yanking line")

	local buffer = require("lib.buffer")
	local _pos = buffer:getCursorPosition()

	if buffer:selectLine() then
		Utils.keyStroke({ "cmd" }, "c")
		hs.timer.doAfter(0.05, function()
			buffer:setCursorPosition(_pos)
		end)
	else
		Log.log.ef(
			"[Commands.insertNormal.yankLine] Failed to yank line, fallback to keyStroke"
		)
		Utils.keyStroke("cmd", "left")
		Utils.keyStroke({ "shift", "cmd" }, "right")
		Utils.keyStroke("cmd", "c")
		Utils.keyStroke({}, "right")
	end
end

--------------------------------------------------------------------------------
-- Insert Visual Mode
--------------------------------------------------------------------------------

M.insertVisual = {}

---Move cursor left
---@return nil
function M.insertVisual.moveLeft()
	Log.log.df("[Commands.insertVisual.moveLeft] Moving left")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLeft()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveLeft] Failed to move left, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift" }, "left")
	end
end

---Move cursor right
---@return nil
function M.insertVisual.moveRight()
	Log.log.df("[Commands.insertVisual.moveRight] Moving right")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveRight()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveRight] Failed to move right, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift" }, "right")
	end
end

---Move cursor up one line
---@return nil
function M.insertVisual.moveUp()
	Log.log.df("[Commands.insertVisual.moveUp] Moving up")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineUp()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveUp] Failed to move up, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift" }, "up")
	end
end

---Move cursor down one line
---@return nil
function M.insertVisual.moveDown()
	Log.log.df("[Commands.insertVisual.moveDown] Moving down")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineDown()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveDown] Failed to move down, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift" }, "down")
	end
end

---Move cursor to the next word
---@return nil
function M.insertVisual.moveWordForward()
	Log.log.df("[Commands.insertVisual.moveWordForward] Moving word forward")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveWordForward()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveWordForward] Failed to move word forward, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift", "alt" }, "right")
	end
end

---Move cursor to the previous word
---@return nil
function M.insertVisual.moveWordBackward()
	Log.log.df("[Commands.insertVisual.moveWordBackward] Moving word backward")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveWordBackward()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveWordBackward] Failed to move word backward, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift", "alt" }, "left")
	end
end

---Move cursor to the start of the line
---@return nil
function M.insertVisual.moveLineStart()
	Log.log.df("[Commands.insertVisual.moveLineStart] Moving line start")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineStart()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveLineStart] Failed to move line start, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift", "cmd" }, "left")
	end
end

---Move cursor to the end of the line
---@return nil
function M.insertVisual.moveLineEnd()
	Log.log.df("[Commands.insertVisual.moveLineEnd] Moving line end")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineEnd()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveLineEnd] Failed to move line end, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift", "cmd" }, "right")
	end
end

---Move cursor to the first non-blank character of the line
---return nil
function M.insertVisual.moveLineFirstNonBlank()
	Log.log.df(
		"[Commands.insertVisual.moveLineFirstNonBlank] Moving line first non-blank"
	)

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveLineFirstNonBlank()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveLineFirstNonBlank] Failed to move line first non-blank, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift", "cmd" }, "left")
	end
end

---Move cursor to the start of the document
---@return nil
function M.insertVisual.moveDocStart()
	Log.log.df("[Commands.insertVisual.moveDocStart] Moving document start")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveDocStart()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveDocStart] Failed to move document start, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift", "cmd" }, "up")
	end
end

---Move cursor to the end of the document
---@return nil
function M.insertVisual.moveDocEnd()
	Log.log.df("[Commands.insertVisual.moveDocEnd] Moving document end")

	local buffer = require("lib.buffer")

	local ok = buffer:visualMoveDocEnd()

	if not ok then
		Log.log.ef(
			"[Commands.insertVisual.moveDocEnd] Failed to move document end, fallback to keyStroke"
		)
		Utils.keyStroke({ "shift", "cmd" }, "down")
	end
end

---Change the highlighted text and go into insert mode
---@return nil
function M.insertVisual.change()
	Log.log.df("[Commands.insertVisual.change] Changing highlighted")

	Utils.keyStroke({}, "delete")

	require("lib.modes"):setModeInsert()
end

---Yank the highlighted text
---@return nil
function M.insertVisual.yank()
	Log.log.df("[Commands.insertVisual.yank] Yanking highlighted")

	Utils.keyStroke("cmd", "c")

	local buffer = require("lib.buffer")

	hs.timer.doAfter(0.05, function()
		buffer:setCursorPosition(buffer._visualAnchor)
	end)
end

return M
