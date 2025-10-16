---@diagnostic disable: undefined-global

local Utils = require("lib.utils")
local Log = require("lib.log")

local M = {}

local DEFAULT_MAPPING = {
	normal = {
		["?"] = {
			description = "Show help",
			action = "showHelp",
		},
		-- modes
		["i"] = {
			description = "Enter passthrough mode",
			action = "enterPassthroughMode",
		},
		["v"] = {
			description = "Enter visual mode",
			action = "enterVisualMode",
		},
		-- scrolls
		["h"] = {
			description = "Scroll left",
			action = "scrollLeft",
		},
		["j"] = {
			description = "Scroll down",
			action = "scrollDown",
		},
		["k"] = {
			description = "Scroll up",
			action = "scrollUp",
		},
		["l"] = {
			description = "Scroll right",
			action = "scrollRight",
		},
		["C-d"] = {
			description = "Scroll half page down",
			action = "scrollHalfPageDown",
		},
		["C-u"] = {
			description = "Scroll half page up",
			action = "scrollHalfPageUp",
		},
		["G"] = {
			description = "Scroll to bottom",
			action = "scrollToBottom",
		},
		["gg"] = {
			description = "Scroll to top",
			action = "scrollToTop",
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
			action = "gotoLink",
		},
		["F"] = {
			description = "Double left click",
			action = "doubleLeftClick",
		},
		["r"] = {
			description = "Right click",
			action = "rightClick",
		},
		["gi"] = {
			description = "Go to input",
			action = "gotoInput",
		},
		["gf"] = {
			description = "Move mouse to link",
			action = "moveMouseToLink",
		},
		["<leader>f"] = {
			description = "Go to link in new tab",
			action = "gotoLinkNewTab",
		}, -- browser only
		["<leader>di"] = {
			description = "Download image",
			action = "downloadImage",
		}, -- browser only
		["<leader>yf"] = {
			description = "Copy link URL to clipboard",
			action = "copyLinkUrlToClipboard",
		}, -- browser only
		-- move mouse
		["zz"] = {
			description = "Move mouse to center",
			action = "moveMouseToCenter",
		},
		-- copy page url
		["<leader>yy"] = {
			description = "Copy page URL to clipboard",
			action = "copyPageUrlToClipboard",
		}, -- browser only
		-- next/prev page
		["<leader>]"] = {
			description = "Go to next page",
			action = "gotoNextPage",
		}, -- browser only
		["<leader>["] = {
			description = "Go to previous page",
			action = "gotoPrevPage",
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
			action = "showHelp",
		},
		-- movements
		["h"] = {
			description = "Move left",
			action = "bufferMoveLeft",
		},
		["j"] = {
			description = "Move down",
			action = "bufferMoveDown",
		},
		["k"] = {
			description = "Move up",
			action = "bufferMoveUp",
		},
		["l"] = {
			description = "Move right",
			action = "bufferMoveRight",
		},
		["e"] = {
			description = "Move to end of word",
			action = "bufferMoveWordEnd",
		},
		["b"] = {
			description = "Move to beginning of word",
			action = "bufferMoveWordBackward",
		},
		["w"] = {
			description = "Move to beginning of next word",
			action = "bufferMoveWordForward",
		},
		["^"] = {
			description = "Move to beginning of line non blank",
			action = "bufferMoveLineFirstNonBlank",
		},
		["0"] = {
			description = "Move to beginning of line",
			action = "bufferMoveLineStart",
		},
		["$"] = {
			description = "Move to end of line",
			action = "bufferMoveLineEnd",
		},
		["gg"] = {
			description = "Move to top of page",
			action = "bufferMoveDocStart",
		},
		["G"] = {
			description = "Move to bottom of page",
			action = "bufferMoveDocEnd",
		},
		-- edits
		["diw"] = {
			description = "Delete inner word",
			action = "bufferDeleteInnerWord",
		},
		["ciw"] = {
			description = "Change inner word",
			action = "bufferChangeInnerWord",
		},
		["yiw"] = {
			description = "Yank word",
			action = "bufferYankInnerWord",
		},
		["dd"] = {
			description = "Delete line",
			action = "bufferDeleteLine",
		},
		["cc"] = {
			description = "Change line",
			action = "bufferChangeLine",
		},
		["x"] = {
			description = "Delete character",
			action = "bufferDeleteChar",
		},
		-- yank and paste
		["yy"] = {
			description = "Yank line",
			action = "bufferYankLine",
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
			action = "enterInsertMode",
		},
		["o"] = {
			description = "Enter insert mode new line below",
			action = "enterInsertModeNewLineBelow",
		},
		["O"] = {
			description = "Enter insert mode new line above",
			action = "enterInsertModeNewLineAbove",
		},
		["A"] = {
			description = "Enter insert mode end of line",
			action = "enterInsertModeEndOfLine",
		},
		["I"] = {
			description = "Enter insert mode start of line",
			action = "enterInsertModeStartLine",
		},
		["v"] = {
			description = "Enter insert visual mode",
			action = "enterInsertVisualMode",
		},
		["V"] = {
			description = "Enter insert visual line mode",
			action = "enterInsertVisualLineMode",
		},
	},
	insertVisual = {
		["?"] = {
			description = "Show help",
			action = "showHelp",
		},
		-- movements
		["h"] = {
			description = "Move left",
			action = "bufferSelectMoveLeft",
		},
		["j"] = {
			description = "Move down",
			action = "bufferSelectMoveDown",
		},
		["k"] = {
			description = "Move up",
			action = "bufferSelectMoveUp",
		},
		["l"] = {
			description = "Move right",
			action = "bufferSelectMoveRight",
		},
		["e"] = {
			description = "Move to end of word",
			action = "bufferSelectMoveWordForward",
		},
		["b"] = {
			description = "Move to beginning of word",
			action = "bufferSelectMoveWordBackward",
		},
		["0"] = {
			description = "Move to beginning of line",
			action = "bufferSelectMoveLineStart",
		},
		["$"] = {
			description = "Move to end of line",
			action = "bufferSelectMoveLineEnd",
		},
		["^"] = {
			description = "Move to beginning of line non blank",
			action = "bufferSelectMoveLineFirstNonBlank",
		},
		["gg"] = {
			description = "Move to top of page",
			action = "bufferSelectMoveDocStart",
		},
		["G"] = {
			description = "Move to bottom of page",
			action = "bufferSelectMoveDocEnd",
		},
		-- edits
		["d"] = {
			description = "Delete highlighted",
			action = "bufferSelectDelete",
		},
		["c"] = {
			description = "Change highlighted",
			action = "bufferSelectChange",
		},
		-- yank
		["y"] = {
			description = "Yank highlighted",
			action = "bufferSelectYank",
		},
	},
	visual = {
		["?"] = {
			description = "Show help",
			action = "showHelp",
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
			action = "yankHighlighted",
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
