# ⌨️ Vimnav.spoon

> **System-wide Vim navigation for macOS.** Use Vim keybindings in any application with Hammerspoon—think Vimium, but everywhere.

<p align="left">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" alt="Platform: macOS">
  <img src="https://img.shields.io/badge/requires-Hammerspoon-blue" alt="Requires: Hammerspoon">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
</p>

![vimnav-demo](https://github.com/user-attachments/assets/b32374e0-5446-46f8-99d2-bfae1bc90799)

## Why Vimnav?

Navigate Safari, Mail, Finder, or any macOS app with the same Vim keybindings you already know. No more reaching for your mouse.

**Key Features:**

- Works across all native macOS apps
- Visual link hints for mouse-free clicking
- Vim-style modal editing in text fields
- Smart mode switching (auto-enters insert mode in inputs)
- Performance optimized with async processing
- Highly customizable keybindings and behavior
- Simple which-key support

> [!NOTE]
> This is a personal project maintained on a best-effort basis. PRs are more likely to be reviewed than feature requests or issues, unless I am facing the same problem.

## Quick Start

### Prerequisites

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) installed
- Accessibility permissions enabled (System Settings → Privacy & Security → Accessibility)

### Installation

1. **Download** the [latest release](https://github.com/y3owk1n/vimnav.spoon/releases/latest) or clone this repo
2. **Place** `Vimnav.spoon` in `~/.hammerspoon/Spoons/`
3. **Add to** `~/.hammerspoon/init.lua`:

    ```lua
    hs.loadSpoon("Vimnav")
    spoon.Vimnav:start()
    ```

4. **Reload** Hammerspoon

### First Steps

Try these basics to get started:

- Press `f` in Safari to see link hints on clickable elements
- Type the hint letters to click
- Use `j`/`k` to scroll down/up
- Press `Esc` in a text field to enter Insert Normal mode for Vim-style editing

## How It Works

Vimnav uses **modal editing** like Vim. Different modes handle different tasks, and you can see the current mode in your menu bar (or on-screen overlay).

### Understanding Modes

#### **Normal Mode (N)** - The default state

- Active when no text field is focused and not excluded
- All navigation and link hint commands available
- Press `i` to enter Passthrough mode (sends all keys to app)
- Press `f` to show link hints
- Focus any text field to auto-switch to Insert mode

#### **Insert Mode (I)** - Text input

- Auto-activated when you focus a text field (Best effort with accessibility detection)
- Keys behave normally (typing works as expected without lag)
- Press `Esc` once to enter Insert Normal mode
- Press `Shift-Esc` to force unfocus and return to Normal mode

#### **Insert Normal Mode (IN)** - Vim editing in text fields

- Activated by pressing `Esc` from Insert mode
- Allows Vim-style navigation and editing without leaving the text field
- Press `i`, `a`, `o`, `O`, `A`, or `I` to return to Insert mode
- Press `v` or `V` to enter Insert Visual mode
- Press `Shift-Esc` to force unfocus and return to Normal mode

#### **Insert Visual Mode (IV)** - Visual selection in text fields

- Activated by pressing `v` or `V` from Insert Normal mode
- Extend selections with Vim motions, then `y`/`d`/`c` to act on them
- Press `Esc` once to return to Insert Normal mode
- Press `Shift-Esc` to force unfocus and return to Normal mode

#### **Links Mode (L)** - Interactive element selection

- Activated by pressing `f` (or `F`, `r`, etc.) from Normal mode
- Shows labeled hints on all clickable elements
- Type the hint letters to interact with that element
- Press `Esc` to cancel and return to Normal mode

#### **Passthrough Mode (P)** - Vimnav disabled temporarily

- Activated by pressing `i` from Normal mode
- All keys are sent directly to the application
- Useful when Vimnav conflicts with app shortcuts
- If this happens often, recommend to just add it to the exclusion list
- Press `Shift-Esc` to return to Normal mode

#### **Disabled Mode (X)** - Vimnav inactive

- Automatically activated in excluded apps (Terminal, iTerm2, etc.)
- Vimnav does nothing in this mode

### Key Insight: `Esc` vs `Shift-Esc`

This is crucial to understand:

- **`Esc`** = Navigate between Insert modes (Insert ↔ Insert Normal ↔ Insert Visual)
- **`Shift-Esc`** = Force unfocus from text field and return to Normal mode

When in a text field:

- `Esc` keeps you in the field but gives you Vim navigation
- `Shift-Esc` exits the field completely

## Core Features

### Navigation (Normal Mode)

Basic movement:

- `h`/`j`/`k`/`l` - Scroll left/down/up/right
- `C-d`/`C-u` - Half page down/up
- `gg`/`G` - Jump to top/bottom
- `H`/`L` - Browser back/forward

Search:

- `/` - Search in page
- `n`/`N` - Next/previous result (To use this, you will need to press `tab` key after done searching in `/`)

### Help (Which key)

- `?` - Show help in which-key popup in any `normal` variant mode

### Hints

Click anything without your mouse by using hints:

- `f` - Click element
- `F` - Double-click element (useful in Finder.app)
- `r` - Right-click element
- `gi` - Input fields
- `gf` - Move mouse to element
- `Esc` - Cancel

**Browser-specific** (with `<leader>` prefix):

- `<leader>f` - Open link in new tab
- `<leader>yf` - Copy link URL
- `<leader>di` - Download image
- `<leader>yy` - Copy current page URL
- `<leader>]`/`[` - Next/previous page

### Text Editing

When focused in a text field, press `Esc` to unlock Vim-style editing:

**Insert Normal Mode:**

Movement:

- `h`/`j`/`k`/`l` - Character/line navigation
- `e`/`b` - Word end/beginning
- `0`/`$` - Line start/end
- `gg`/`G` - Document start/end

Text operations:

- `diw`/`ciw`/`yiw` - Delete/change/yank word (Not exactly true textobject, the `i` key is more for muscle memory only)
- `dd`/`cc`/`yy` - Delete/change/yank line
- `u`/`C-r` - Undo/redo
- `p` - Paste

Mode switching:

- `i` - Return to Insert mode
- `o`/`O` - Insert new line below/above
- `A`/`I` - Insert at line end/start
- `v`/`V` - Enter Visual/Visual Line mode

**Insert Visual Mode:**

- `h`/`j`/`k`/`l` - Extend selection
- `e`/`b` - Extend by word
- `0`/`$` - Extend to line start/end
- `d`/`c`/`y` - Delete/change/yank selection

> [!NOTE]
> Modal text editing mimics Vim using macOS shortcuts. It won't be as complete as Vim, but it's much better than nothing.

### Passthrough Mode

Press `i` in Normal mode to send all keys to the application. Press `Shift-Esc` to return to Normal mode.

## Configuration

The defaults are sane enough and you shouldn't need to configure anything to use it. The below are just example.

```lua
hs.loadSpoon("Vimnav")
spoon.Vimnav:configure({
  leader = {
    key = " ", -- space as leader
  },
  scroll = {
    scrollStep = 100,
    smoothScroll = true,
  },
  hints = {
    chars = "asdfghjkl", -- home row only
  },
  applicationGroups = {
    exclusions = {
      "Terminal",
      "iTerm2",
      "VSCode",
    },
  },
}):start()
```

### Custom Keybindings

Map keys to commands, native keystrokes, or custom functions:

```lua
spoon.Vimnav:configure({
 mapping = {
  normal = {
   -- Map to built-in commands
   ["j"] = {
    description = "Scroll down",
    action = "scrollDown",
   },

   -- Map to native keystrokes
   ["t"] = {
    description = "New Tab",
    action = { "cmd", "t" },
   },

   -- Map to custom functions
   ["Q"] = {
    description = "Custom action",
    action = function()
     hs.alert.show("Custom action!")
    end,
   },

   -- Disable a mapping
   ["/"] = {
    description = "Noop",
    action = "noop",
   },

   -- Use leader key
   ["<leader>g"] = {
    description = "Anything",
    action = "anythingAsAbove",
   },
  },
 },
})
```

Default mapped bindings can be found by running in your hammerspoon console:

```lua
print(hs.inspect(spoon.Vimnav:getDefaultConfig().mapping))
```

The default leader key is `space`. To change it, set `leader.key` to the desired character.

```lua
spoon.Vimnav:configure({
  leader = {
    key = " ", -- space as leader
  },
})
```

### Hints customisation

Hints can be customised by changing the `hints` table:

```lua
spoon.Vimnav:configure({
 hints = {
  chars = "abcdefghijklmnopqrstuvwxyz", -- characters to make hints combination
  fontSize = 12, -- font size for hints
  depth = 20, -- depth for traversing axelements
  textFont = ".AppleSystemUIFontHeavy", -- font for hints text
  colors = {
   from = "#FFF585", -- background gradient color (from)
   to = "#FFC442", -- background gradient color (to)
   angle = 45, -- background gradient angle
   border = "#000000", -- border color
   borderWidth = 1, -- border width (set to 0 to disable)
   textColor = "#000000", -- text color for the hint
  },
 },
})
```

You can run `hs.inspect(hs.styledtext.fontNames())` in Hammerspoon console to see all available fonts.

### Focus watcher

The focus watcher will watch for focus changes and update the mode accordingly. It will also update the mode when the focused element is editable.

The default `0.1` interval makes the focus react as fast as possible, but it can be configured with `focus.checkInterval`:

```lua
spoon.Vimnav:configure({
  focus = {
    checkInterval = 0.1, -- focus check interval in seconds
  },
})
```

### Scrolling configuration

Scrolling behaviour can also be configured as below:

```lua
spoon.Vimnav:configure({
  scroll = {
    scrollStep = 50, -- scroll step in pixels
    scrollStepHalfPage = 500, -- scroll step in pixels for half page
    scrollStepFullPage = 1e6, -- scroll step in pixels for full page
    smoothScroll = true, -- enable/disable smooth scrolling
    smoothScrollFramerate = 120, -- smooth scroll framerate in frames per second
  },
})
```

### Accessibility Roles

Control which UI elements are detected:

```lua
spoon.Vimnav:configure({
 axRoles = {
  -- AXRoles that should be consider as `insert` mode
  editable = {
   "AXTextField",
   "AXComboBox",
   "AXTextArea",
   "AXSearchField",
  },
  -- AXRoles that can be used for jumping links
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
   "AXMenuBarItem",
   "AXMenuItem",
   "AXRow",
  },
 },
})
```

### Application Groups

Exclude apps from Vimnav, and they will all be in `disabled` mode when switched to:

```lua
spoon.Vimnav:configure({
 applicationGroups = {
  exclusions = {
   "Terminal",
   "Alacritty",
   "iTerm2",
   "Kitty",
   "Ghostty",
  },
 },
})
```

Launchers are also excluded by default, but you can add more. They are detected by `hs.window.filter` with best effort. Only tested with `Spotlight` and it's working fine.

```lua
spoon.Vimnav:configure({
 applicationGroups = {
  launchers = {
   "Spotlight",
   "Raycast",
   "Alfred",
  },
 },
})
```

List of browsers to tell Vimnav that they are browser and can do some browser specific actions:

```lua
spoon.Vimnav:configure({
 applicationGroups = {
  browsers = {
   "Safari",
   "Google Chrome",
   "Firefox",
   "Microsoft Edge",
   "Brave Browser",
   "Zen",
  },
 },
})
```

### Visual Indicators

**Menu Bar** (enabled by default):

```lua
spoon.Vimnav:configure({
  menubar = { enabled = true } -- disable if preferred
})
```

<https://github.com/user-attachments/assets/671cc359-3500-4baa-baa5-1582d39c8986>

**On-Screen Overlay:**

<https://github.com/user-attachments/assets/a43af6b7-0947-4e2b-bc91-9b8cf969ee28>

```lua
spoon.Vimnav:configure({
 overlay = {
  enabled = true,
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
  },
 },
})
```

### Which-Key

Which-key popup can be enabled by setting `enabled` to `true` in the config:

![which-key](https://github.com/user-attachments/assets/753f640f-6ba2-4223-a025-5dea5a9dbae7)

![which-key-prefix](https://github.com/user-attachments/assets/134afc1e-fa6b-41a6-87f4-f21a7f6af853)

```lua
spoon.Vimnav:configure({
 whichkey = {
  enabled = false, -- enable which-key popup if true
  delay = 0.25, -- delay to show which-key popup in seconds
  fontSize = 14, -- font size for which-key popup
  textFont = ".AppleSystemUIFontHeavy", -- font for which-key popup
  minRowsPerCol = 8, -- minimum rows per column for which-key popup to move to next column
  colors = {
   background = "#1e1e2e",
   backgroundAlpha = 0.8,
   border = "#1e1e2e",
   key = "#f9e2af",
   separator = "#6c7086",
   description = "#cdd6f4",
  },
 },
})
```

### Logging

Vimnav uses [Hammerspoon's built-in logger](https://www.hammerspoon.org/docs/hs.logger.html) to log messages.

You can configure the log level by setting `logLevel` in the config:

```lua
spoon.Vimnav:configure({
 logLevel = "warning", -- one of 'nothing', 'error', 'warning', 'info', 'debug', or 'verbose'
})
```

### Full Configuration Reference

See all available options:

```lua
print(hs.inspect(spoon.Vimnav:getDefaultConfig()))
```

## API Reference

```lua
-- Initialize the module, you don't need to call this if you're using the spoon
spoon.Vimnav:init()

-- Configure the module
---@class Hs.Vimnav.Config.SetOpts
---@field extend? boolean Whether to extend the config or replace it, true = extend, false = replace

---@param userConfig Hs.Vimnav.Config
---@param opts? Hs.Vimnav.Config.SetOpts
spoon.Vimnav:configure(userConfig, opts)

-- Starts the module
spoon.Vimnav:start()

-- Stops the module
spoon.Vimnav:stop()

-- Restarts the module
spoon.Vimnav:restart()

-- Returns current running state
spoon.Vimnav:isRunning()

-- Returns state and current config information
spoon.Vimnav:debug()

-- Returns default config
spoon.Vimnav:getDefaultConfig()
```

## Known Limitations

- **Electron apps** - Limited support due to poor accessibility APIs
- **Web extensions** - May conflict with browser Vim extensions
- **Modal dialogs** - Some system dialogs block accessibility
- **Complex editing** - Vim macros and registers not supported

## Performance

Vimnav is optimized for speed:

- Async coroutines for non-blocking traversal
- Spatial indexing for viewport culling
- Object pooling to minimize GC pressure
- Smart caching of accessibility queries

Link hints typically appear in under 100ms on most pages.

## Contributing

Contributions welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commits
4. Test thoroughly across multiple apps
5. Submit a PR with a clear description

## Credits

Based on [Vifari](https://github.com/dzirtusss/vifari) by dzirtuss, extensively rewritten for system-wide support, performance optimization, and modal text editing.

## License

MIT License - See [LICENSE](LICENSE) file.

---

**Made by developers who never touch their mouse**

⭐ Star this repo if you find it useful!
