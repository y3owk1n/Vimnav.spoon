---@diagnostic disable: undefined-global

local Cache = require("lib.cache")
local Config = require("lib.config")
local Log = require("lib.log")

local M = {}

---Process elements in background coroutine to avoid UI blocking
---@param element table
---@param opts Hs.Vimnav.Async.TraversalOpts
---@return nil
function M.traverseElements(element, opts)
	local matcher = opts.matcher
	local callback = opts.callback
	local maxResults = opts.maxResults

	local results = {}
	local viewport = require("lib.elements").createViewportRegions()

	if not viewport then
		Log.log.ef("[Async.traverseElements] Failed to create viewport regions")
		callback({})
		return
	end

	local traverseCoroutine = coroutine.create(function()
		Log.log.df("[Async.traverseElements] Traversing elements")
		M.walkElement(element, {
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
			Log.log.df("[Async.traverseElements] Traversal complete")
			callback(results)
			return
		end

		local success, shouldStop = coroutine.resume(traverseCoroutine)
		if success and not shouldStop then
			hs.timer.doAfter(0.001, resumeWork) -- 1ms pause
		else
			Log.log.ef("[Async.traverseElements] Traversal failed")
			callback(results)
		end
	end

	resumeWork()
end

---Walks an element with a matcher
---@param element table
---@param opts Hs.Vimnav.Async.WalkElementOpts
---@return boolean|nil
function M.walkElement(element, opts)
	local depth = opts.depth
	local matcher = opts.matcher
	local callback = opts.callback
	local viewport = opts.viewport

	if depth > Config.config.hints.depth then
		Log.log.df(
			"[Async.walkElement] Reached max depth: %s",
			Config.config.hints.depth
		)
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
		local role = Cache:getAttribute(el, "AXRole")
		if
			role == "AXWindow"
			and el ~= require("lib.elements").getAxWindow()
		then
			Log.log.df("[Async.walkElement] Skipping AXWindow: %s", el)
			return false
		end

		-- Get frame once, reuse everywhere
		local frame = Cache:getAttribute(el, "AXFrame")
		if not frame then
			Log.log.ef("[Async.walkElement] No AXFrame found for element")
			return
		end

		-- Viewport check
		if
			not require("lib.elements").isInViewport({
				fx = frame.x,
				fy = frame.y,
				fw = frame.w,
				fh = frame.h,
				viewport = viewport,
			})
		then
			Log.log.df("[Async.walkElement] Element outside viewport: %s", el)
			return
		end

		-- Test element
		if matcher(el) then
			if callback(el) then -- callback returns true to stop
				return true
			end
		end

		-- Process children
		local children = Cache:getAttribute(el, "AXVisibleChildren")
			or Cache:getAttribute(el, "AXChildren")
			or {}

		for i = 1, #children do
			local matched = M.walkElement(children[i], {
				depth = depth + 1,
				matcher = matcher,
				callback = callback,
				viewport = viewport,
			})

			if matched then
				Log.log.df(
					"[Async.walkElement] Matched element: %s",
					children[i]
				)
				return true
			end
		end
	end

	local role = Cache:getAttribute(element, "AXRole")
	if role == "AXApplication" then
		local children = Cache:getAttribute(element, "AXChildren") or {}
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
