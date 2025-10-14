local Config = require("lib.config")
local Cache = require("lib.cache")
local Log = require("lib.log")
local Utils = require("lib.utils")
local Roles = require("lib.roles")
local State = require("lib.state")
local Async = require("lib.async")

local M = {}

---Returns the application element
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getApp(force)
	return Cache:getElement("app", function()
		return hs.application.frontmostApplication()
	end, force)
end

---Returns the application element for AXUIElement
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxApp(force)
	return Cache:getElement("axApp", function()
		local app = M.getApp(force)
		return app and hs.axuielement.applicationElement(app)
	end, force)
end

---Returns the window element
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getWindow(force)
	return Cache:getElement("window", function()
		local app = M.getApp(force)
		return app and app:focusedWindow()
	end, force)
end

---Returns the window element for AXUIElement
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxWindow(force)
	return Cache:getElement("axWindow", function()
		local window = M.getWindow(force)
		return window and hs.axuielement.windowElement(window)
	end, force)
end

---Returns the focused element for AXUIElement
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxFocusedElement(force)
	return Cache:getElement("axFocusedElement", function()
		local axApp = M.getAxApp(force)
		return axApp and Cache:getAttribute(axApp, "AXFocusedUIElement", force)
	end, force)
end

---Returns the web area element for AXUIElement
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxWebArea(force)
	return Cache:getElement("axWebArea", function()
		local axWindow = M.getAxWindow(force)
		return axWindow and M.findAxRole(axWindow, "AXWebArea", force)
	end, force)
end

---Returns the menu bar element for AXUIElement
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxMenuBar(force)
	return Cache:getElement("axMenuBar", function()
		local axApp = M.getAxApp(force)
		return axApp and Cache:getAttribute(axApp, "AXMenuBar", force)
	end, force)
end

---Returns the full area element
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getFullArea(force)
	return Cache:getElement("fullArea", function()
		local axWin = M.getAxWindow(force)
		local axMenuBar = M.getAxMenuBar(force)

		if not axWin or not axMenuBar then
			return nil
		end

		local winFrame = Cache:getAttribute(axWin, "AXFrame", force) or {}
		local menuBarFrame = Cache:getAttribute(axMenuBar, "AXFrame", force)
			or {}

		return {
			x = 0,
			y = 0,
			w = menuBarFrame.w,
			h = winFrame.h + winFrame.y + menuBarFrame.h,
		}
	end, force)
end

---Finds an element with a specific AXRole
---@param rootElement Hs.Vimnav.Element
---@param role string
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.findAxRole(rootElement, role, force)
	if not rootElement then
		return nil
	end

	local axRole = Cache:getAttribute(rootElement, "AXRole", force)
	if axRole == role then
		return rootElement
	end

	local axChildren = Cache:getAttribute(rootElement, "AXChildren", force)
		or {}

	if type(axChildren) == "string" then
		return nil
	end

	for _, child in ipairs(axChildren) do
		local result = M.findAxRole(child, role, force)
		if result then
			return result
		end
	end

	return nil
end

---Enable enhanced accessibility for Chromium.
---@return boolean
function M.enableEnhancedUIForChrome()
	if not Config.config.enhancedAccessibility.enableForChromium then
		Log.log.df(
			"[M.enableEnhancedUIForChrome] Chromium enhanced accessibility is disabled"
		)
		return false
	end

	local app = M.getApp()
	if not app then
		return false
	end

	local appName = app:name()

	if
		Utils.tblContains(
			Config.config.enhancedAccessibility.chromiumApps or {},
			appName
		)
	then
		local axApp = M.getAxApp()
		if axApp then
			local success = pcall(function()
				axApp:setAttributeValue("AXEnhancedUserInterface", true)
			end)
			if success then
				Log.log.df(
					"[M.enableEnhancedUIForChrome] Enabled AXEnhancedUserInterface for %s",
					appName
				)
				return true
			end
		end
	end

	Log.log.df(
		"[Element.enableEnhancedUIForChrome] Not chrome app, abort enabling AXEnhancedUserInterface"
	)
	return false
end

---Enables accessibility for Electron apps.
---@return boolean
function M.enableAccessibilityForElectron()
	if not Config.config.enhancedAccessibility.enableForElectron then
		Log.log.df(
			"[M.enableAccessibilityForElectron] Electron enhanced accessibility is disabled"
		)
		return false
	end

	if not M.isElectronApp() then
		Log.log.df("[M.enableAccessibilityForElectron] Electron is not running")
		return false
	end

	local axApp = M.getAxApp()
	if not axApp then
		return false
	end

	-- Try AXManualAccessibility first (preferred for Electron)
	local success = pcall(function()
		axApp:setAttributeValue("AXManualAccessibility", true)
	end)

	if success then
		Log.log.df(
			"[M.enableAccessibilityForElectron] Enabled AXManualAccessibility for Electron app"
		)
		return true
	end

	-- Fallback to AXEnhancedUserInterface (has side effects)
	success = pcall(function()
		axApp:setAttributeValue("AXEnhancedUserInterface", true)
	end)

	if success then
		Log.log.wf(
			"[M.enableAccessibilityForElectron] Enabled AXEnhancedUserInterface (may affect window positioning)"
		)
		return true
	end

	return false
end

---Quad-tree like spatial indexing for viewport culling
---@return table|nil
function M.createViewportRegions()
	local fullArea = M.getFullArea()
	if not fullArea then
		return nil
	end

	return {
		x = fullArea.x,
		y = fullArea.y,
		w = fullArea.w,
		h = fullArea.h,
		centerX = fullArea.x + fullArea.w / 2,
		centerY = fullArea.y + fullArea.h / 2,
	}
end

---Checks if the element is in the viewport
---@param opts Hs.Vimnav.Elements.IsInViewportOpts
---@return boolean
function M.isInViewport(opts)
	local fx = opts.fx
	local fy = opts.fy
	local fw = opts.fw
	local fh = opts.fh
	local viewport = opts.viewport

	return fx < viewport.x + viewport.w
		and fx + fw > viewport.x
		and fy < viewport.y + viewport.h
		and fy + fh > viewport.y
		and fw > 2
		and fh > 2 -- Skip tiny elements
end

---Checks if the application is in the browser list
---@return boolean
function M.isInBrowser()
	local app = M.getApp()
	return app
			and Utils.tblContains(
				Config.config.applicationGroups.browsers,
				app:name()
			)
		or false
end

---@return boolean
function M.isElectronApp()
	local app = M.getApp()
	if not app then
		return false
	end

	local pid = app:pid()
	local name = app:name() or ""
	local bundleID = app:bundleID() or ""
	local path = app:path() or ""

	Log.log.df(
		"[Utils.isElectronApp] Checking app: name=%s, bundleID=%s, pid=%d, path=%s",
		name,
		bundleID,
		pid,
		path
	)

	-- Cached result
	if Cache.cache.electrons[pid] ~= nil then
		Log.log.df(
			"[Utils.isElectronApp] Cache hit for pid=%d → %s",
			pid,
			tostring(Cache.cache.electrons[pid])
		)
		return Cache.cache.electrons[pid]
	end

	-- Quick early checks
	if bundleID:match("electron") or path:match("Electron") then
		Log.log.df(
			"[Utils.isElectronApp] Quick match via bundleID/path for %s",
			name
		)
		Cache.cache.electrons[pid] = true
		return true
	end

	if
		Utils.tblContains(
			Config.config.enhancedAccessibility.electronApps or {},
			name
		)
	then
		Log.log.df(
			"[Utils.isElectronApp] Matched known Electron app name: %s",
			name
		)
		Cache.cache.electrons[pid] = true
		return true
	end

	-- Framework path check
	local frameworksPath = path .. "/Contents/Frameworks"
	local attr = hs.fs.attributes(frameworksPath)
	if not attr then
		Log.log.df(
			"[Utils.isElectronApp] No attributes found for %s (app may be sandboxed or path invalid)",
			frameworksPath
		)
		Cache.cache.electrons[pid] = false
		return false
	elseif attr.mode ~= "directory" then
		Log.log.df(
			"[Utils.isElectronApp] %s exists but is not a directory (mode=%s)",
			frameworksPath,
			tostring(attr.mode)
		)
		Cache.cache.electrons[pid] = false
		return false
	end

	Log.log.df(
		"[Utils.isElectronApp] Frameworks directory verified: %s",
		frameworksPath
	)

	-- Try directory iteration
	local ok, iterOrErr = pcall(hs.fs.dir, frameworksPath)
	if not ok then
		Log.log.ef(
			"[Utils.isElectronApp] hs.fs.dir failed for %s: %s",
			frameworksPath,
			tostring(iterOrErr)
		)
		Cache.cache.electrons[pid] = false
		return false
	end

	if type(iterOrErr) ~= "function" then
		Log.log.ef(
			"[Utils.isElectronApp] hs.fs.dir did not return iterator for %s (got %s)",
			frameworksPath,
			type(iterOrErr)
		)
		Cache.cache.electrons[pid] = false
		return false
	end

	Log.log.df("[Utils.isElectronApp] Iterating %s ...", frameworksPath)

	local success, result = pcall(function()
		for file in iterOrErr do
			Log.log.df(
				"[Utils.isElectronApp] Found file in frameworks: %s",
				tostring(file)
			)
			if file and (file:match("Electron") or file:match("Chromium")) then
				Log.log.df(
					"[Utils.isElectronApp] Electron-like framework found: %s",
					file
				)
				return true
			end
		end
		return false
	end)

	if not success then
		Log.log.df(
			"[Utils.isElectronApp] Failed to iterate over %s (error or sandboxed)",
			frameworksPath
		)
		Cache.cache.electrons[pid] = false
		return false
	end

	Cache.cache.electrons[pid] = result or false
	Log.log.df(
		"[Utils.isElectronApp] Final result for %s: %s",
		name,
		tostring(Cache.cache.electrons[pid])
	)
	return Cache.cache.electrons[pid]
end

---Finds clickable elements
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.Elements.FindClickableElementsOpts
---@return nil
function M.findClickableElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback
	local withUrls = opts.withUrls

	local function _matcher(element)
		local role = Cache:getAttribute(element, "AXRole")

		if withUrls then
			local url = Cache:getAttribute(element, "AXURL")
			return url ~= nil
		end

		-- Role check
		if not role or type(role) ~= "string" or not Roles:isJumpable(role) then
			return false
		end

		-- Skip obviously non-interactive elements quickly
		if Roles:shouldSkip(role) then
			return false
		end

		return true
	end

	Async.traverseElements(axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = State.state.maxElements,
	})
end

---Finds input elements
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.Elements.FindElementsOpts
---@return nil
function M.findInputElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Cache:getAttribute(element, "AXRole")
		return (role and type(role) == "string" and Roles:isEditable(role))
			or false
	end

	local function _callback(results)
		-- Auto-click if single input found
		if #results == 1 then
			State.state.onClickCallback({
				element = results[1],
				frame = Cache:getAttribute(results[1], "AXFrame"),
			})
			require("lib.modes").setModeNormal()
			require("lib.marks").clear()
		else
			callback(results)
		end
	end

	Async.traverseElements(axApp, {
		matcher = _matcher,
		callback = _callback,
		maxResults = 10,
	})
end

---Finds image elements
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.Elements.FindElementsOpts
---@return nil
function M.findImageElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Cache:getAttribute(element, "AXRole")
		local url = Cache:getAttribute(element, "AXURL")
		return role == "AXImage" and url ~= nil
	end

	Async.traverseElements(axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 100,
	})
end

---Finds next button elemets
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.Elements.FindElementsOpts
---@return nil
function M.findNextButtonElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Cache:getAttribute(element, "AXRole")
		local title = Cache:getAttribute(element, "AXTitle")

		if
			(role == "AXLink" or role == "AXButton")
			and title
			and type(title) == "string"
		then
			return title:lower():find("next") ~= nil
		end
		return false
	end

	Async.traverseElements(axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 5,
	})
end

---Finds previous button elemets
---@param axApp Hs.Vimnav.Element
---@param opts Hs.Vimnav.Elements.FindElementsOpts
---@return nil
function M.findPrevButtonElements(axApp, opts)
	if type(axApp) == "string" then
		return
	end

	local callback = opts.callback

	local function _matcher(element)
		local role = Cache:getAttribute(element, "AXRole")
		local title = Cache:getAttribute(element, "AXTitle")

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

	Async.traverseElements(axApp, {
		matcher = _matcher,
		callback = callback,
		maxResults = 5,
	})
end

return M
