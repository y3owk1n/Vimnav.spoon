---@diagnostic disable: undefined-global

local Utils = require("lib.utils")
local Log = require("lib.log")

local M = {}

local DEFAULT_MAPPING = {
	normal = {
		["?"] = {
			description = "Show help",
			action = "whichkey.show",
		},
		-- modes
		["i"] = {
			description = "Enter passthrough mode",
			action = "mode.passthrough",
		},
		["v"] = {
			description = "Enter visual mode",
			action = "mode.visual",
		},
		-- scrolls
		["h"] = {
			description = "Scroll left",
			action = "scroll.left",
		},
		["j"] = {
			description = "Scroll down",
			action = "scroll.down",
		},
		["k"] = {
			description = "Scroll up",
			action = "scroll.up",
		},
		["l"] = {
			description = "Scroll right",
			action = "scroll.right",
		},
		["C-d"] = {
			description = "Scroll half page down",
			action = "scroll.HalfPageDown",
		},
		["C-u"] = {
			description = "Scroll half page up",
			action = "scroll.halfPageUp",
		},
		["G"] = {
			description = "Scroll to bottom",
			action = "scroll.bottom",
		},
		["gg"] = {
			description = "Scroll to top",
			action = "scroll.top",
		},
		-- navigation (arrows)
		["H"] = {
			description = "Left Arrow",
			action = { {}, "left" },
		},
		["L"] = {
			description = "Right Arrow",
			action = { {}, "right" },
		},
		["J"] = {
			description = "Down Arrow",
			action = { {}, "down" },
		},
		["K"] = {
			description = "Up Arrow",
			action = { {}, "up" },
		},
		["C-n"] = {
			description = "Down Arrow",
			action = { {}, "down" },
		},
		["C-p"] = {
			description = "Up Arrow",
			action = { {}, "up" },
		},
		-- go back/forward
		["<leader>h"] = {
			description = "Go back",
			action = { "cmd", "[" },
		},
		["<leader>l"] = {
			description = "Go forward",
			action = { "cmd", "]" },
		},
		-- hints click
		["f"] = {
			description = "Go to link",
			action = "hints.click",
		},
		["F"] = {
			description = "Double left click",
			action = "hints.doubleClick",
		},
		["r"] = {
			description = "Right click",
			action = "hints.rightClick",
		},
		["gi"] = {
			description = "Go to input",
			action = "hints.input",
		},
		["gf"] = {
			description = "Move mouse to link",
			action = "hints.moveMouse",
		},
		["<leader>f"] = {
			description = "Go to link in new tab",
			action = "hints.newTab",
		}, -- browser only
		["<leader>di"] = {
			description = "Download image",
			action = "hints.downloadImage",
		}, -- browser only
		["<leader>yf"] = {
			description = "Copy link URL to clipboard",
			action = "hints.copyLink",
		}, -- browser only
		-- move mouse
		["zz"] = {
			description = "Move mouse to center",
			action = "misc.moveMouseToCenter",
		},
		-- copy page url
		["<leader>yy"] = {
			description = "Copy page URL to clipboard",
			action = "browser.copyPageUrl",
		}, -- browser only
		-- next/prev page
		["<leader>]"] = {
			description = "Go to next page",
			action = "browser.nextPage",
		}, -- browser only
		["<leader>["] = {
			description = "Go to previous page",
			action = "browser.prevPage",
		}, -- browser only
		["<leader> "] = {
			description = "Bypass spacebar",
			action = { {}, "space" },
		},
		-- searches
		["/"] = {
			description = "Search text",
			action = { "cmd", "f" },
		},
		["n"] = {
			description = "Search forward",
			action = { "cmd", "g" },
		},
		["N"] = {
			description = "Search backward",
			action = { { "cmd", "shift" }, "g" },
		},
	},
	insertNormal = {
		["?"] = {
			description = "Show help",
			action = "whichkey.show",
		},
		-- movements
		["h"] = {
			description = "Move left",
			action = "insertNormal.moveLeft",
		},
		["j"] = {
			description = "Move down",
			action = "insertNormal.moveDown",
		},
		["k"] = {
			description = "Move up",
			action = "insertNormal.moveUp",
		},
		["l"] = {
			description = "Move right",
			action = "insertNormal.moveRight",
		},
		["e"] = {
			description = "Move to end of word",
			action = "insertNormal.moveWordEnd",
		},
		["b"] = {
			description = "Move to beginning of word",
			action = "insertNormal.moveWordBackward",
		},
		["w"] = {
			description = "Move to beginning of next word",
			action = "insertNormal.moveWordForward",
		},
		["^"] = {
			description = "Move to beginning of line non blank",
			action = "insertNormal.moveLineStartNonBlank",
		},
		["0"] = {
			description = "Move to beginning of line",
			action = "insertNormal.moveLineStart",
		},
		["$"] = {
			description = "Move to end of line",
			action = "insertNormal.moveLineEnd",
		},
		["gg"] = {
			description = "Move to top of page",
			action = "insertNormal.moveDocStart",
		},
		["G"] = {
			description = "Move to bottom of page",
			action = "insertNormal.moveDocEnd",
		},
		-- edits
		["diw"] = {
			description = "Delete inner word",
			action = "insertNormal.deleteInnerWord",
		},
		["ciw"] = {
			description = "Change inner word",
			action = "insertNormal.changeInnerWord",
		},
		["yiw"] = {
			description = "Yank word",
			action = "insertNormal.yankInnerWord",
		},
		["dd"] = {
			description = "Delete line",
			action = "insertNormal.deleteLine",
		},
		["cc"] = {
			description = "Change line",
			action = "insertNormal.changeLine",
		},
		["x"] = {
			description = "Delete character",
			action = { {}, "delete" },
		},
		-- yank and paste
		["yy"] = {
			description = "Yank line",
			action = "insertNormal.yankLine",
		},
		["p"] = {
			description = "Paste",
			action = { "cmd", "v" },
		},
		-- undo/redo
		["u"] = {
			description = "Undo",
			action = { "cmd", "z" },
		},
		["C-r"] = {
			description = "Redo",
			action = { { "cmd", "shift" }, "z" },
		},
		-- modes
		["i"] = {
			description = "Enter insert mode",
			action = "mode.insert",
		},
		["o"] = {
			description = "Enter insert mode new line below",
			action = "mode.insertWithNewLineBelow",
		},
		["O"] = {
			description = "Enter insert mode new line above",
			action = "mode.insertWithNewLineAbove",
		},
		["A"] = {
			description = "Enter insert mode end of line",
			action = "mode.insertWithEndOfLine",
		},
		["I"] = {
			description = "Enter insert mode start of line",
			action = "mode.insertWithStartLine",
		},
		["v"] = {
			description = "Enter insert visual mode",
			action = "mode.insertVisual",
		},
		["V"] = {
			description = "Enter insert visual line mode",
			action = "mode.insertVisualLine",
		},
	},
	insertVisual = {
		["?"] = {
			description = "Show help",
			action = "whichkey.show",
		},
		-- movements
		["h"] = {
			description = "Move left",
			action = "insertVisual.moveLeft",
		},
		["j"] = {
			description = "Move down",
			action = "insertVisual.moveDown",
		},
		["k"] = {
			description = "Move up",
			action = "insertVisual.moveUp",
		},
		["l"] = {
			description = "Move right",
			action = "insertVisual.moveRight",
		},
		["e"] = {
			description = "Move to end of word",
			action = "insertVisual.moveWordForward",
		},
		["b"] = {
			description = "Move to beginning of word",
			action = "insertVisual.moveWordBackward",
		},
		["0"] = {
			description = "Move to beginning of line",
			action = "insertVisual.moveLineStart",
		},
		["$"] = {
			description = "Move to end of line",
			action = "insertVisual.moveLineEnd",
		},
		["^"] = {
			description = "Move to beginning of line non blank",
			action = "insertVisual.moveLineFirstNonBlank",
		},
		["gg"] = {
			description = "Move to top of page",
			action = "insertVisual.moveDocStart",
		},
		["G"] = {
			description = "Move to bottom of page",
			action = "insertVisual.moveDocEnd",
		},
		-- edits
		["d"] = {
			description = "Delete highlighted",
			action = { {}, "delete" },
		},
		["c"] = {
			description = "Change highlighted",
			action = "insertVisual.change",
		},
		-- yank
		["y"] = {
			description = "Yank highlighted",
			action = "insertVisual.yank",
		},
	},
	visual = {
		["?"] = {
			description = "Show help",
			action = "whichkey.show",
		},
		-- movements
		["h"] = {
			description = "Move left",
			action = { { "shift" }, "left" },
		},
		["j"] = {
			description = "Move down",
			action = { { "shift" }, "down" },
		},
		["k"] = {
			description = "Move up",
			action = { { "shift" }, "up" },
		},
		["l"] = {
			description = "Move right",
			action = { { "shift" }, "right" },
		},
		["e"] = {
			description = "Move to end of word",
			action = { { "shift", "alt" }, "right" },
		},
		["b"] = {
			description = "Move to beginning of word",
			action = { { "shift", "alt" }, "left" },
		},
		["gg"] = {
			description = "Move to top of page",
			action = { { "shift", "cmd" }, "up" },
		},
		["G"] = {
			description = "Move to bottom of page",
			action = { { "shift", "cmd" }, "down" },
		},
		-- yank
		["y"] = {
			description = "Yank highlighted",
			action = "visual.yank",
		},
	},
}

---@type Hs.Vimnav.Config
local DEFAULT_CONFIG = {
	logLevel = "warning",
	leader = {
		key = " ", -- space
	},
	hints = {
		chars = "abcdefghijklmnopqrstuvwxyz",
		fontSize = 12,
		depth = 20,
		textFont = ".AppleSystemUIFontHeavy",
		colors = {
			from = "#FFF585",
			to = "#FFC442",
			angle = 45,
			border = "#000000",
			borderWidth = 1,
			textColor = "#000000",
		},
	},
	focus = {
		checkInterval = 0.1,
	},
	mapping = DEFAULT_MAPPING,
	scroll = {
		scrollStep = 50,
		scrollStepHalfPage = 500,
		scrollStepFullPage = 1e6,
		smoothScroll = true,
		smoothScrollFramerate = 120,
	},
	axRoles = {
		editable = {
			"AXTextField",
			"AXComboBox",
			"AXTextArea",
			"AXSearchField",
		},
		jumpable = {
			"AXLink",
			"AXButton",
			"AXPopUpButton",
			"AXComboBox",
			"AXTextField",
			"AXTextArea",
			"AXCheckBox",
			"AXRadioButton",
			"AXDisclosureTriangle",
			"AXMenuButton",
			"AXMenuBarItem", -- To support top menu bar
			"AXMenuItem",
			"AXRow", -- To support Mail.app without using "AXStaticText"
			-- "AXColorWell", -- Macos Color Picker
			-- "AXCell", -- This can help with showing marks on Calendar.app
			-- "AXGroup", -- This can help with lots of MacOS apps, but creates lot of noise!
			-- "AXStaticText",
			-- "AXMenu",
			-- "AXToolbar",
			-- "AXToolbarButton",
			-- "AXTabGroup",
			-- "AXTab",
			-- "AXSlider",
			-- "AXIncrementor",
			-- "AXDecrementor",
		},
	},
	applicationGroups = {
		exclusions = {
			"Terminal",
			"Alacritty",
			"iTerm2",
			"Kitty",
			"Ghostty",
		},
		browsers = {
			"Safari",
			"Google Chrome",
			"Firefox",
			"Microsoft Edge",
			"Brave Browser",
			"Zen",
		},
		launchers = { "Spotlight", "Raycast", "Alfred" },
	},
	menubar = {
		enabled = true,
	},
	overlay = {
		enabled = false,
		position = "top-center",
		size = 25,
		padding = 4,
		textFont = ".AppleSystemUIFontHeavy",
		colors = {
			disabled = "#5a5672",
			normal = "#80b8e8",
			insert = "#abe9b3",
			insertNormal = "#f9e2af",
			insertVisual = "#c9a0e9",
			links = "#f8bd96",
			passthrough = "#f28fad",
			visual = "#c9a0e9",
		},
	},
	whichkey = {
		enabled = false,
		delay = 0.25, -- seconds
		fontSize = 14,
		textFont = ".AppleSystemUIFontHeavy",
		minRowsPerCol = 8,
		colors = {
			background = "#1e1e2e",
			backgroundAlpha = 0.8,
			border = "#1e1e2e",
			key = "#f9e2af",
			separator = "#6c7086",
			description = "#cdd6f4",
		},
	},
	enhancedAccessibility = {
		enableForChromium = false,
		chromiumApps = { "Google Chrome", "Brave Browser", "Microsoft Edge" },
		enableForElectron = false,
		electronApps = {
			"Code",
			"Visual Studio Code",
			"Slack",
			"Notion",
			"Discord",
			"Figma",
			"Obsidian",
		},
	},
}

---@type Hs.Vimnav.Config
M.config = {}

---@param userConfig Hs.Vimnav.Config User configuration
---@param opts? Hs.Vimnav.Config.SetOpts Opts for setting config
function M:new(userConfig, opts)
	Log.log.df("[Config:new] Creating config")

	opts = opts or {}
	local extend = opts.extend
	if extend == nil then
		extend = true
	end

	-- Start with defaults
	if not self.config or not next(self.config) then
		Log.log.df("[Config:new] No config found, using defaults")
		self.config = Utils.deepCopy(DEFAULT_CONFIG)
	end

	-- Merge user config
	if userConfig then
		Log.log.df("[Config:new] Merging user config")
		self.config = Utils.tblMerge(self.config, userConfig, extend)
	end
end

return M
