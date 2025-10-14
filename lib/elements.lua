---@diagnostic disable: undefined-global

local Utils = dofile(hs.spoons.resourcePath("./utils.lua"))

local M = {}

---Returns the application element
---@param vimnav Hs.Vimnav
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getApp(vimnav, force)
	return Utils.getCachedElement(vimnav, "app", function()
		return hs.application.frontmostApplication()
	end, force)
end

---Returns the application element for AXUIElement
---@param vimnav Hs.Vimnav
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxApp(vimnav, force)
	return Utils.getCachedElement(vimnav, "axApp", function()
		local app = M.getApp(vimnav, force)
		return app and hs.axuielement.applicationElement(app)
	end, force)
end

---Returns the window element
---@param vimnav Hs.Vimnav
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getWindow(vimnav, force)
	return Utils.getCachedElement(vimnav, "window", function()
		local app = M.getApp(vimnav, force)
		return app and app:focusedWindow()
	end, force)
end

---Returns the window element for AXUIElement
---@param vimnav Hs.Vimnav
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxWindow(vimnav, force)
	return Utils.getCachedElement(vimnav, "axWindow", function()
		local window = M.getWindow(vimnav, force)
		return window and hs.axuielement.windowElement(window)
	end, force)
end

---Returns the focused element for AXUIElement
---@param vimnav Hs.Vimnav
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxFocusedElement(vimnav, force)
	return Utils.getCachedElement(vimnav, "axFocusedElement", function()
		local axApp = M.getAxApp(vimnav, force)
		return axApp
			and Utils.getAttribute(vimnav, axApp, "AXFocusedUIElement", force)
	end, force)
end

---Returns the web area element for AXUIElement
---@param vimnav Hs.Vimnav
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxWebArea(vimnav, force)
	return Utils.getCachedElement(vimnav, "axWebArea", function()
		local axWindow = M.getAxWindow(vimnav, force)
		return axWindow and M.findAxRole(vimnav, axWindow, "AXWebArea", force)
	end, force)
end

---Returns the menu bar element for AXUIElement
---@param vimnav Hs.Vimnav
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getAxMenuBar(vimnav, force)
	return Utils.getCachedElement(vimnav, "axMenuBar", function()
		local axApp = M.getAxApp(vimnav, force)
		return axApp and Utils.getAttribute(vimnav, axApp, "AXMenuBar", force)
	end, force)
end

---Returns the full area element
---@param vimnav Hs.Vimnav
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.getFullArea(vimnav, force)
	return Utils.getCachedElement(vimnav, "fullArea", function()
		local axWin = M.getAxWindow(vimnav, force)
		local axMenuBar = M.getAxMenuBar(vimnav, force)

		if not axWin or not axMenuBar then
			return nil
		end

		local winFrame = Utils.getAttribute(vimnav, axWin, "AXFrame", force)
			or {}
		local menuBarFrame = Utils.getAttribute(
			vimnav,
			axMenuBar,
			"AXFrame",
			force
		) or {}

		return {
			x = 0,
			y = 0,
			w = menuBarFrame.w,
			h = winFrame.h + winFrame.y + menuBarFrame.h,
		}
	end, force)
end

---Finds an element with a specific AXRole
---@param vimnav Hs.Vimnav
---@param rootElement Hs.Vimnav.Element
---@param role string
---@param force? boolean
---@return Hs.Vimnav.Element|nil
function M.findAxRole(vimnav, rootElement, role, force)
	if not rootElement then
		return nil
	end

	local axRole = Utils.getAttribute(vimnav, rootElement, "AXRole", force)
	if axRole == role then
		return rootElement
	end

	local axChildren = Utils.getAttribute(
		vimnav,
		rootElement,
		"AXChildren",
		force
	) or {}

	if type(axChildren) == "string" then
		return nil
	end

	for _, child in ipairs(axChildren) do
		local result = M.findAxRole(vimnav, child, role, force)
		if result then
			return result
		end
	end

	return nil
end

---Enable enhanced accessibility for Chromium.
---@param vimnav Hs.Vimnav
---@return boolean
function M.enableEnhancedUIForChrome(vimnav)
	if not vimnav.config.enhancedAccessibility.enableForChromium then
		vimnav.log.df(
			"[M.enableEnhancedUIForChrome] Chromium enhanced accessibility is disabled"
		)
		return false
	end

	local app = M.getApp(vimnav)
	if not app then
		return false
	end

	local appName = app:name()

	if
		Utils.tblContains(
			vimnav.config.enhancedAccessibility.chromiumApps or {},
			appName
		)
	then
		local axApp = M.getAxApp(vimnav)
		if axApp then
			local success = pcall(function()
				axApp:setAttributeValue("AXEnhancedUserInterface", true)
			end)
			if success then
				vimnav.log.df(
					"[M.enableEnhancedUIForChrome] Enabled AXEnhancedUserInterface for %s",
					appName
				)
				return true
			end
		end
	end

	vimnav.log.df(
		"[Element.enableEnhancedUIForChrome] Not chrome app, abort enabling AXEnhancedUserInterface"
	)
	return false
end

---Enables accessibility for Electron apps.
---@param vimnav Hs.Vimnav
---@return boolean
function M.enableAccessibilityForElectron(vimnav)
	if not vimnav.config.enhancedAccessibility.enableForElectron then
		vimnav.log.df(
			"[M.enableAccessibilityForElectron] Electron enhanced accessibility is disabled"
		)
		return false
	end

	if not Utils.isElectronApp(vimnav) then
		vimnav.log.df(
			"[M.enableAccessibilityForElectron] Electron is not running"
		)
		return false
	end

	local axApp = M.getAxApp(vimnav)
	if not axApp then
		return false
	end

	-- Try AXManualAccessibility first (preferred for Electron)
	local success = pcall(function()
		axApp:setAttributeValue("AXManualAccessibility", true)
	end)

	if success then
		vimnav.log.df(
			"[M.enableAccessibilityForElectron] Enabled AXManualAccessibility for Electron app"
		)
		return true
	end

	-- Fallback to AXEnhancedUserInterface (has side effects)
	success = pcall(function()
		axApp:setAttributeValue("AXEnhancedUserInterface", true)
	end)

	if success then
		vimnav.log.wf(
			"[M.enableAccessibilityForElectron] Enabled AXEnhancedUserInterface (may affect window positioning)"
		)
		return true
	end

	return false
end

---Checks if the application is in the browser list
---@param vimnav Hs.Vimnav
---@return boolean
function M.isInBrowser(vimnav)
	local app = M.getApp(vimnav)
	return app
			and Utils.tblContains(
				vimnav.config.applicationGroups.browsers,
				app:name()
			)
		or false
end

---@param vimnav Hs.Vimnav
---@return boolean
function M.isElectronApp(vimnav)
	local app = M.getApp(vimnav)
	if not app then
		return false
	end

	local pid = app:pid()
	local name = app:name() or ""
	local bundleID = app:bundleID() or ""
	local path = app:path() or ""

	vimnav.log.df(
		"[M.isElectronApp] Checking app: name=%s, bundleID=%s, pid=%d, path=%s",
		name,
		bundleID,
		pid,
		path
	)

	-- Cached result
	if vimnav.cache.electron[pid] ~= nil then
		vimnav.log.df(
			"[M.isElectronApp] Cache hit for pid=%d → %s",
			pid,
			tostring(vimnav.cache.electron[pid])
		)
		return vimnav.cache.electron[pid]
	end

	-- Quick early checks
	if bundleID:match("electron") or path:match("Electron") then
		vimnav.log.df(
			"[M.isElectronApp] Quick match via bundleID/path for %s",
			name
		)
		vimnav.cache.electron[pid] = true
		return true
	end

	if
		M.tblContains(
			vimnav.config.enhancedAccessibility.electronApps or {},
			name
		)
	then
		vimnav.log.df(
			"[M.isElectronApp] Matched known Electron app name: %s",
			name
		)
		vimnav.cache.electron[pid] = true
		return true
	end

	-- Framework path check
	local frameworksPath = path .. "/Contents/Frameworks"
	local attr = hs.fs.attributes(frameworksPath)
	if not attr then
		vimnav.log.df(
			"[M.isElectronApp] No attributes found for %s (app may be sandboxed or path invalid)",
			frameworksPath
		)
		vimnav.cache.electron[pid] = false
		return false
	elseif attr.mode ~= "directory" then
		vimnav.log.df(
			"[M.isElectronApp] %s exists but is not a directory (mode=%s)",
			frameworksPath,
			tostring(attr.mode)
		)
		vimnav.cache.electron[pid] = false
		return false
	end

	vimnav.log.df(
		"[M.isElectronApp] Frameworks directory verified: %s",
		frameworksPath
	)

	-- Try directory iteration
	local ok, iterOrErr = pcall(hs.fs.dir, frameworksPath)
	if not ok then
		vimnav.log.ef(
			"[M.isElectronApp] hs.fs.dir failed for %s: %s",
			frameworksPath,
			tostring(iterOrErr)
		)
		vimnav.cache.electron[pid] = false
		return false
	end

	if type(iterOrErr) ~= "function" then
		vimnav.log.ef(
			"[M.isElectronApp] hs.fs.dir did not return iterator for %s (got %s)",
			frameworksPath,
			type(iterOrErr)
		)
		vimnav.cache.electron[pid] = false
		return false
	end

	vimnav.log.df("[M.isElectronApp] Iterating %s ...", frameworksPath)

	local success, result = pcall(function()
		for file in iterOrErr do
			vimnav.log.df(
				"[M.isElectronApp] Found file in frameworks: %s",
				tostring(file)
			)
			if file and (file:match("Electron") or file:match("Chromium")) then
				vimnav.log.df(
					"[M.isElectronApp] Electron-like framework found: %s",
					file
				)
				return true
			end
		end
		return false
	end)

	if not success then
		vimnav.log.df(
			"[M.isElectronApp] Failed to iterate over %s (error or sandboxed)",
			frameworksPath
		)
		vimnav.cache.electron[pid] = false
		return false
	end

	vimnav.cache.electron[pid] = result or false
	vimnav.log.df(
		"[M.isElectronApp] Final result for %s: %s",
		name,
		tostring(vimnav.cache.electron[pid])
	)
	return vimnav.cache.electron[pid]
end

---Quad-tree like spatial indexing for viewport culling
---@param vimnav Hs.Vimnav
---@return table|nil
function M.createViewportRegions(vimnav)
	local fullArea = M.getFullArea(vimnav)
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

---Process elements in background coroutine to avoid UI blocking
---@param vimnav Hs.Vimnav
---@param element table
---@param opts Hs.Vimnav.Elements.TraversalOpts
---@return nil
function M.traverseAsync(vimnav, element, opts)
	local matcher = opts.matcher
	local callback = opts.callback
	local maxResults = opts.maxResults

	local results = {}
	local viewport = M.createViewportRegions(vimnav)

	if not viewport then
		callback({})
		return
	end

	local traverseCoroutine = coroutine.create(function()
		M.walkElement(vimnav, element, {
			depth = 0,
			matcher = matcher,
			callback = function(el)
				results[#results + 1] = el
				return #results >= maxResults
			end,
			viewport = viewport,
		})
	end)

	-- Resume coroutine in chunks
	local function resumeWork()
		if coroutine.status(traverseCoroutine) == "dead" then
			callback(results)
			return
		end

		local success, shouldStop = coroutine.resume(traverseCoroutine)
		if success and not shouldStop then
			hs.timer.doAfter(0.001, resumeWork) -- 1ms pause
		else
			callback(results)
		end
	end

	resumeWork()
end

---Walks an element with a matcher
---@param vimnav Hs.Vimnav
---@param element table
---@param opts Hs.Vimnav.Elements.WalkElementOpts
---@return boolean|nil
function M.walkElement(vimnav, element, opts)
	local depth = opts.depth
	local matcher = opts.matcher
	local callback = opts.callback
	local viewport = opts.viewport

	if depth > vimnav.config.hints.depth then
		return
	end -- Hard depth limit

	local batchSize = 0
	local function processElement(el)
		batchSize = batchSize + 1

		-- Batch yield every 30 elements to stay responsive
		if batchSize % 30 == 0 then
			coroutine.yield(false) -- Don't stop, just yield
		end

		-- Skip AXWindows that are not the current window
		local role = Utils.getAttribute(vimnav, el, "AXRole")
		if role == "AXWindow" and el ~= M.getAxWindow(vimnav) then
			return false
		end

		-- Get frame once, reuse everywhere
		local frame = Utils.getAttribute(vimnav, el, "AXFrame")
		if not frame then
			return
		end

		-- Viewport check
		if
			not M.isInViewport({
				fx = frame.x,
				fy = frame.y,
				fw = frame.w,
				fh = frame.h,
				viewport = viewport,
			})
		then
			return
		end

		-- Test element
		if matcher(el) then
			if callback(el) then -- callback returns true to stop
				return true
			end
		end

		-- Process children
		local children = Utils.getAttribute(vimnav, el, "AXVisibleChildren")
			or Utils.getAttribute(vimnav, el, "AXChildren")
			or {}

		for i = 1, #children do
			local matched = M.walkElement(vimnav, children[i], {
				depth = depth + 1,
				matcher = matcher,
				callback = callback,
				viewport = viewport,
			})

			if matched then
				return true
			end
		end
	end

	local role = Utils.getAttribute(vimnav, element, "AXRole")
	if role == "AXApplication" then
		local children = Utils.getAttribute(vimnav, element, "AXChildren") or {}
		for i = 1, #children do
			if processElement(children[i]) then
				return true
			end
		end
	else
		return processElement(element)
	end
end

return M
