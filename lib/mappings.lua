---@diagnostic disable: undefined-global

local State = require("lib.state")
local Log = require("lib.log")
local Config = require("lib.config")

local M = {}

---Generates all combinations of letters
---@return nil
function M.generateCombinations()
	Log.log.df("[Mappings.generateCombinations] Generating combinations")

	if #State.state.allCombinations > 0 then
		Log.log.df(
			"[Mappings.generateCombinations] Already generated combinations"
		)
		return
	end -- Already generated

	local chars = Config.config.hints.chars

	if not chars then
		Log.log.ef(
			"[Mappings.generateCombinations] No link hint characters configured"
		)
		return
	end

	State.state.maxElements = #chars * #chars

	for i = 1, #chars do
		for j = 1, #chars do
			table.insert(
				State.state.allCombinations,
				chars:sub(i, i) .. chars:sub(j, j)
			)
			if #State.state.allCombinations >= State.state.maxElements then
				Log.log.df(
					"[Mappings.generateCombinations] Reached max combinations"
				)
				return
			end
		end
	end
	Log.log.df(
		"[Mappings.generateCombinations] Generated %d combinations",
		#State.state.allCombinations
	)
end

---Fetches all mapping prefixes
---@return nil
function M.fetchMappingPrefixes()
	Log.log.df("[Mappings.fetchMappingPrefixes] Fetching mapping prefixes")

	State.state.mappingPrefixes = {}
	State.state.mappingPrefixes.normal = {}
	State.state.mappingPrefixes.visual = {}
	State.state.mappingPrefixes.insertNormal = {}
	State.state.mappingPrefixes.insertVisual = {}

	local leaderKey = Config.config.leader.key or " "

	local function addLeaderPrefixes(mapping, prefixTable)
		Log.log.df("[Mappings.fetchMappingPrefixes] Adding leader prefixes")

		for k, v in pairs(mapping) do
			if v == "noop" then
				goto continue
			end

			-- Handle leader key mappings
			if k:sub(1, 8) == "<leader>" then
				-- Mark leader key as prefix
				prefixTable[leaderKey] = true

				-- Extract the part after <leader>
				local afterLeader = k:sub(9)
				if #afterLeader > 1 then
					-- Add all prefixes for multi-char sequences
					-- e.g., for "<leader>ba", add "<leader>b" as prefix
					for i = 1, #afterLeader - 1 do
						local prefix = "<leader>" .. afterLeader:sub(1, i)
						prefixTable[prefix] = true
					end
				end
			elseif #k == 2 then
				prefixTable[string.sub(k, 1, 1)] = true
			elseif #k == 3 then
				prefixTable[string.sub(k, 1, 1)] = true
				prefixTable[string.sub(k, 1, 2)] = true
			end
			::continue::
		end
	end

	addLeaderPrefixes(
		Config.config.mapping.normal,
		State.state.mappingPrefixes.normal
	)
	addLeaderPrefixes(
		Config.config.mapping.insertNormal,
		State.state.mappingPrefixes.insertNormal
	)
	addLeaderPrefixes(
		Config.config.mapping.insertVisual,
		State.state.mappingPrefixes.insertVisual
	)
	addLeaderPrefixes(
		Config.config.mapping.visual,
		State.state.mappingPrefixes.visual
	)

	Log.log.df("[Mappings.fetchMappingPrefixes] Fetched mapping prefixes")
end

return M
