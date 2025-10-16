---@diagnostic disable: undefined-global

local Config = require("lib.config")
local Log = require("lib.log")
local Utils = require("lib.utils")

local M = {}

---Performs a smooth scroll
---@param opts Hs.Vimnav.Actions.SmoothScrollOpts Opts for smooth scroll
---@return nil
function M.smoothScroll(opts)
	local x = opts.x or 0
	local y = opts.y or 0
	local smooth = opts.smooth or Config.config.scroll.smoothScroll

	if not smooth then
		hs.eventtap.event.newScrollEvent({ x, y }, {}, "pixel"):post()
		Log.log.df("[Actions.smoothScroll] Smooth scroll disabled")
		Log.log.df(
			"[Actions.smoothScroll] Performing scroll without smooth scroll"
		)
		return
	end

	local steps = 5
	local dx = x and (x / steps) or 0
	local dy = y and (y / steps) or 0
	local frame = 0
	local interval = 1 / Config.config.scroll.smoothScrollFramerate

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
	Log.log.df("[Actions.smoothScroll] Smooth scroll complete")
end

---Opens a URL in a new tab
---@param url string URL to open
---@return nil
function M.openUrlInNewTab(url)
	if not url then
		Log.log.ef("[Actions.openUrlInNewTab] No URL provided")
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

	local currentApp = require("lib.elements").getApp()
	if not currentApp then
		Log.log.ef("[Actions.openUrlInNewTab] No current app found")
		return
	end

	local appName = currentApp:name()
	local script = browserScripts[appName] or browserScripts["Safari"]

	hs.osascript.applescript(string.format(script, url))

	Log.log.df("[Actions.openUrlInNewTab] Opened URL in new tab")
end

---Sets the clipboard contents
---@param contents string Contents to set
---@return nil
function M.setClipboardContents(contents)
	if not contents then
		hs.alert.show("Nothing to copy", nil, nil, 2)
		Log.log.ef("[Actions.setClipboardContents] Nothing to copy")
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
		Log.log.df("[Actions.setClipboardContents] Copied to clipboard")
	else
		hs.alert.show("Failed to copy to clipboard", nil, nil, 2)
		Log.log.ef("[Actions.setClipboardContents] Failed to copy to clipboard")
	end
end

---Download base64 image
---@param url string URL to download
---@param description string Description for the downloaded image
---@return nil
function M.downloadBase64Image(url, description)
	local base64Data = url:match("^data:image/[^;]+;base64,(.+)$")
	Log.log.df("[Actions.downloadBase64Image] Downloading base64 image")
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
			Log.log.df(
				"[Actions.downloadBase64Image] Image saved: " .. fileName
			)
		else
			Log.log.ef("[Actions.downloadBase64Image] Failed to save image")
		end
	else
		Log.log.ef("[Actions.downloadBase64Image] No base64 data found")
	end
end

---Download image via http
---@param url string URL to download
---@return nil
function M.downloadImageViaHttp(url)
	hs.http.asyncGet(url, nil, function(status, body, headers)
		if status == 200 then
			Log.log.df(
				"[Actions.downloadImageViaHttp] Downloading image via http"
			)
			local contentType = headers["Content-Type"] or ""
			if contentType:match("^image/") then
				Log.log.df("[Actions.downloadImageViaHttp] Image found")
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
			else
				Log.log.ef("[Actions.downloadImageViaHttp] Image not found")
			end
		else
			Log.log.ef(
				"[Actions.downloadImageViaHttp] Failed to download image"
			)
		end
	end)
end

---Force unfocus
---@return nil
function M.forceUnfocus()
	local Timer = require("lib.timer")

	if Timer.focusLastElement then
		Timer.focusLastElement:setAttributeValue("AXFocused", false)
		hs.alert.show("Force unfocused!")

		-- Reset focus state
		Timer:resetFocus()

		Log.log.df("[Actions.forceUnfocus] Force unfocused!")
	else
		Log.log.ef("[Actions.forceUnfocus] No focusable element found")
	end
end

---Force deselect text highlights
---@return nil
function M.forceDeselectTextHighlights()
	local focused = require("lib.elements").getAxFocusedElement()
	if not focused then
		Log.log.ef(
			"[Actions.forceDeselectTextHighlights] No focusable element found"
		)
		return
	end
	local attrs = focused:attributeNames() or {}
	local supportsMarkers =
		hs.fnutils.contains(attrs, "AXSelectedTextMarkerRange")
	if supportsMarkers then
		local textMarkerRange =
			focused:attributeValue("AXSelectedTextMarkerRange")
		if not textMarkerRange then
			Log.log.df(
				"[Actions.forceDeselectTextHighlights] No text marker range found; nothing to clear"
			)
			return
		end
		local range, rangeErr = focused:parameterizedAttributeValue(
			"AXLengthForTextMarkerRange",
			textMarkerRange
		)
		if rangeErr then
			Log.log.ef(
				"[Actions.forceDeselectTextHighlights] Error getting range: %s",
				rangeErr
			)
			return
		end
		if not range or range <= 0 then
			Log.log.df(
				"[Actions.forceDeselectTextHighlights] No range found; nothing to clear"
			)
			return
		end
		-- Extract the start marker from the text marker range
		local startMarkerOfSelection = textMarkerRange:startMarker()
		if not startMarkerOfSelection then
			Log.log.ef(
				"[Actions.forceDeselectTextHighlights] Could not extract start marker from range"
			)
			return
		end
		-- Create an empty range at the current selection start position
		local emptyRange, emptyRangeErr = hs.axuielement.axtextmarker.newRange(
			startMarkerOfSelection,
			startMarkerOfSelection
		)
		if not emptyRange then
			Log.log.ef(
				"[Actions.forceDeselectTextHighlights] Error creating empty range: %s",
				emptyRangeErr
			)
			return
		end
		local ok, setErr =
			focused:setAttributeValue("AXSelectedTextMarkerRange", emptyRange)
		if ok then
			Log.log.df(
				"[Actions.forceDeselectTextHighlights] Text deselected via AX markers."
			)
		else
			Log.log.ef(
				"[Actions.forceDeselectTextHighlights] Could not set AXSelectedTextMarkerRange: %s",
				setErr
			)
		end
	end
end

---Tries to click on a frame
---@param frame table Frame to click
---@param opts? Hs.Vimnav.Actions.TryClickOpts Opts for clicking
---@return nil
function M.tryClick(frame, opts)
	Log.log.df("[Actions.tryClick] Clicking frame")

	opts = opts or {}
	local type = opts.type or "left"
	local doubleClick = opts.doubleClick or false

	local clickX, clickY = frame.x + frame.w / 2, frame.y + frame.h / 2
	local originalPos = hs.mouse.absolutePosition()
	-- hs.mouse.absolutePosition({ x = clickX, y = clickY })
	if type == "left" then
		if doubleClick then
			Utils.doubleClickAtPoint({ x = clickX, y = clickY })
			Log.log.df("[Actions.tryClick] Performed double click")
		else
			hs.eventtap.leftClick({ x = clickX, y = clickY }, 0)
			Log.log.df("[Actions.tryClick] Performed left click")
		end
	elseif type == "right" then
		hs.eventtap.rightClick({ x = clickX, y = clickY }, 0)
		Log.log.df("[Actions.tryClick] Performed right click")
	end
	hs.timer.doAfter(0.1, function()
		hs.mouse.absolutePosition(originalPos)
		Log.log.df("[Actions.tryClick] Restored mouse position")
	end)
end

return M
