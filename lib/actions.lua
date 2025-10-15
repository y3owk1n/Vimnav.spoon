local Config = require("lib.config")
local Elements = require("lib.elements")
local State = require("lib.state")
local Log = require("lib.log")
local Utils = require("lib.utils")

local M = {}

---Performs a smooth scroll
---@param opts Hs.Vimnav.Actions.SmoothScrollOpts
---@return nil
function M.smoothScroll(opts)
	local x = opts.x or 0
	local y = opts.y or 0
	local smooth = opts.smooth or Config.config.scroll.smoothScroll

	if not smooth then
		hs.eventtap.event.newScrollEvent({ x, y }, {}, "pixel"):post()
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
end

---Opens a URL in a new tab
---@param url string
---@return nil
function M.openUrlInNewTab(url)
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
function M.setClipboardContents(contents)
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
function M.downloadBase64Image(url, description)
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
function M.downloadImageViaHttp(url)
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
---@return nil
function M.forceUnfocus()
	if State.state.focusLastElement then
		State.state.focusLastElement:setAttributeValue("AXFocused", false)
		hs.alert.show("Force unfocused!")

		-- Reset focus state
		State:resetFocus()
	end
end

---Force deselect text highlights
---@return nil
function M.forceDeselectTextHighlights()
	local focused = Elements.getAxFocusedElement()

	if not focused then
		return
	end

	local attrs = focused:attributeNames() or {}
	local supportsMarkers =
		hs.fnutils.contains(attrs, "AXSelectedTextMarkerRange")

	if supportsMarkers then
		local startMarker = focused:attributeValue("AXStartTextMarker")
		if not startMarker then
			Log.log.df(
				"[Actions.forceDeselectTextHighlights] No AXStartTextMarker found; cannot clear"
			)
			return
		end

		local emptyRange, err =
			hs.axuielement.axtextmarker.newRange(startMarker, startMarker)
		if not emptyRange then
			Log.log.ef(
				"[Actions.forceDeselectTextHighlights] Error creating empty range: %s",
				err
			)
			return
		end

		local ok, setErr =
			focused:setAttributeValue("AXSelectedTextMarkerRange", emptyRange)
		if ok then
			Log.log.df(
				"[Actions.forceDeselectTextHighlights] Text deselected via AX markers."
			)
			return
		else
			Log.log.ef(
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
		Log.log.df(
			"[Actions.forceDeselectTextHighlights] Text deselected via simulated click."
		)
	else
		Log.log.ef(
			"[Actions.forceDeselectTextHighlights] No frame available for click fallback."
		)
	end
end

---Tries to click on a frame
---@param frame table
---@param opts? Hs.Vimnav.Actions.TryClickOpts
---@return nil
function M.tryClick(frame, opts)
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

return M
