# ⌨️ Vimnav.spoon

> **Vim navigation for your entire Mac.** Navigate any macOS application with Vim-like keybindings using Hammerspoon. Think Vimium, but system-wide.

<p align="left">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" alt="Platform: macOS">
  <img src="https://img.shields.io/badge/requires-Hammerspoon-blue" alt="Requires: Hammerspoon">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
</p>

![vimnav-demo](https://github.com/user-attachments/assets/b32374e0-5446-46f8-99d2-bfae1bc90799)

## ✨ Why Vimnav?

Stop reaching for your mouse. Navigate Safari, Mail, Finder, or any macOS app with the same muscle memory you use in Vim.

**🎯 Key Features:**

- 🌐 Works across **all native macOS apps** (Safari, Mail, Finder, System Settings)
- 🎨 **Visual link hints** — click anything without touching your mouse
- ⚡ **Smart mode switching** — auto-enters insert mode in text fields
- ✍️ \*Modal text editing\*\* — Normal and Visual modes inside text field (Only for those mappable shortcuts)
- 🚀 **Performance optimized** — async traversal, spatial indexing, memory pooling
- 🎛️ **Highly customizable** — keybindings, launchers, excluded apps
- 🔌 **Supports leader key** — use `<leader>` in any variant of normal mode

> [!NOTE]
> Modal text editing is best effort to imitate vim keybinding with simple shortcuts available in macOS.
> It's better than nothing but I have no intention to build a full accessibility detection, unless someone is interested
> to help out.

## 🚀 Quick Start

### Installation

1. **Install Hammerspoon** → [Download here](https://www.hammerspoon.org/)
2. **Enable Accessibility** → System Settings → Privacy & Security → Accessibility
3. **Download Vimnav** → Place `Vimnav.spoon` in `~/.hammerspoon/Spoons/`
4. **Configure** → Add to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Vimnav")
spoon.Vimnav:start()
```

5. **Reload** Hammerspoon

### 🎓 First Steps

Press `f` in Safari to see link hints overlay on all clickable elements. Type the letters shown to click!

**Try these basics:**

- `j`/`k` → scroll down/up
- `gg`/`G` → jump to top/bottom
- `f` → show clickable elements
- `gi` → jump to first input field
- Click in a text field, press `Esc` to enter Insert Normal mode

## 📖 Features

### 🧭 Core Navigation

| Key             | Action    | Description                                               |
| --------------- | --------- | --------------------------------------------------------- |
| `h`/`j`/`k`/`l` | Scroll    | Vim-style directional movement                            |
| `C-d`/`C-u`     | Half page | Fast vertical scrolling                                   |
| `gg`/`G`        | Jump      | Top or bottom of page                                     |
| `H`/`L`         | History   | Back/forward (⌘[ / ⌘])                                    |
| `/`             | Search    | Search in page                                            |
| `n`             | Next      | Search next (need to do a `tab` press if right after `/`) |
| `N`             | Prev      | Search previous                                           |

### ❌ Passthrough Mode

Press `i` to enter passthrough mode from normal mode. In this mode, every key press is sent to the app.

To back to normal mode, press `Shift-Esc`.

### 🎯 Link Hints Mode

Press `f` to enter link hints mode. Interactive elements get labeled:

```
[AA] Sign In    [AB] Register    [AC] Learn More
[AD] Products   [AE] Pricing     [AF] Contact
```

Type the letters (e.g., `AA`) to click that element instantly!

| Key          | Action                | Works In |
| ------------ | --------------------- | -------- |
| `f`          | Click element         | All apps |
| `F`          | Double Click element  | All apps |
| `<leader>f`  | Open in new tab       | Browsers |
| `r`          | Right-click element   | All apps |
| `gi`         | Jump to input field   | All apps |
| `gf`         | Move mouse to element | All apps |
| `<leader>yf` | Copy link URL         | Browsers |
| `Esc`        | Exit link             | All apps |

### ✍️ Text Editing Modes

When you focus a text field, Vimnav automatically enters **Insert mode**. Press `Esc` to unlock Vim-like editing!

#### 📝 Insert Normal Mode (`Esc` from Insert)

Navigate and manipulate text without leaving the input field:

**Movement:**

| Key  | Action            | Description            |
| ---- | ----------------- | ---------------------- |
| `h`  | ← cursor left     | Move left              |
| `l`  | → cursor right    | Move right             |
| `j`  | ↓ cursor down     | Move down              |
| `k`  | ↑ cursor up       | Move up                |
| `e`  | ⌥→ word end       | Jump to end of word    |
| `b`  | ⌥← word back      | Jump to start of word  |
| `0`  | ⌘← line start     | Jump to line start     |
| `$`  | ⌘→ line end       | Jump to line end       |
| `gg` | ⌘↑ document start | Jump to document start |
| `G`  | ⌘↓ document end   | Jump to document end   |

**Editing:**

| Key   | Action            | Description               |
| ----- | ----------------- | ------------------------- |
| `diw` | Delete inner word | Delete word under cursor  |
| `ciw` | Change inner word | Delete word + insert mode |
| `yiw` | Yank inner word   | Copy word                 |
| `dd`  | Delete line       | Delete current line       |
| `cc`  | Change line       | Delete line + insert mode |
| `yy`  | Yank line         | Copy current line         |
| `u`   | Undo              | Undo last change (⌘Z)     |
| `C-r` | Redo              | Redo last change (⌘⇧Z)    |
| `p`   | Paste             | Paste from clipboard (⌘V) |

**Mode Switching:**

| Key         | Action                | Description                  |
| ----------- | --------------------- | ---------------------------- |
| `i`         | Insert mode           | Return to insert mode        |
| `o`         | Insert new line below | New line below + insert mode |
| `O`         | Insert new line above | New line above + insert mode |
| `A`         | Insert at line end    | Jump to end + insert mode    |
| `I`         | Insert at line start  | Jump to start + insert       |
| `v`         | Visual mode           | Enter visual mode            |
| `V`         | Visual line mode      | Select entire line           |
| `Shift-Esc` | Force unfocus         | Exit field completely        |

#### 🎨 Insert Visual Mode (`v` from Insert Normal)

Select text visually with Vim motions:

| Key         | Action                | Description              |
| ----------- | --------------------- | ------------------------ |
| `h`         | ⇧← extend left        | Extend selection left    |
| `l`         | ⇧→ extend right       | Extend selection right   |
| `j`         | ⇧↓ extend down        | Extend selection down    |
| `k`         | ⇧↑ extend up          | Extend selection up      |
| `e`         | ⇧⌥→ extend word end   | Extend to word end       |
| `b`         | ⇧⌥← extend word back  | Extend to word start     |
| `0`         | ⇧⌘← extend line start | Extend to line start     |
| `$`         | ⇧⌘→ extend line end   | Extend to line end       |
| `gg`        | ⇧⌘↑ extend doc start  | Extend to document start |
| `G`         | ⇧⌘↓ extend doc end    | Extend to document end   |
| `d`         | Delete selection      | Delete highlighted text  |
| `c`         | Change selection      | Delete + insert mode     |
| `y`         | Yank selection        | Copy highlighted text    |
| `Esc`       | Exit visual           | Back to insert normal    |
| `Shift-Esc` | Force unfocus         | Exit field completely    |

**🔄 Mode Flow:**

```
Insert → [Esc] → Insert Normal → [v/V] → Insert Visual
                      ↑                          ↓
                      └────────[Esc]─────────────┘
```

### 🌐 Browser-Specific Features

Enhanced functionality in Safari, Chrome, Firefox, Edge, Brave, and Zen:

By default, browser features are mapped to `<leader>` key. You can change this in the configuration.

| Key                     | Action                    |
| ----------------------- | ------------------------- |
| `<leader>yy`            | Copy current page URL     |
| `<leader>yf`            | Copy link URL (after `f`) |
| `<leader>f`             | Open link in new tab      |
| `<leader>di`            | Download image            |
| `<leader>]`/`<leader>[` | Next/previous page        |
| `Shift-Esc`             | Force unfocus from forms  |

### 🎭 Modes Overview

Vimnav operates in different modes, shown in the menu bar:

| Icon   | Mode          | When                              |
| ------ | ------------- | --------------------------------- |
| **N**  | Normal        | Default navigation mode           |
| **I**  | Insert        | Auto-activated in text fields     |
| **IN** | Insert Normal | Vim navigation within text fields |
| **IV** | Insert Visual | Vim visual selection in fields    |
| **P**  | Passthrough   | Manual activation (press `i`)     |
| **L**  | Links         | Showing link hints                |
| **X**  | Disabled      | In excluded apps                  |

## ⚙️ Configuration

### 🎛️ Basic Setup

```lua
hs.loadSpoon("Vimnav")
spoon.Vimnav
 :configure({
  leader = {
   key = " ", -- space
   timeout = 0.5,
  },

  scroll = {
   scrollStep = 100, -- Faster scrolling
   smoothScroll = true, -- Smooth animations
  },

  hints = {
   chars = "asdfghjkl", -- Home row only
  },

  applicationGroups = {
   exclusions = { -- Don't run in these apps
    "Terminal",
    "iTerm2",
    "VSCode",
   },
  },
 })
 :start()
```

### ⌨️ Custom Keybindings

Map any key to any command or native keystroke or any function or disable it:

```lua
spoon.Vimnav
 :configure({
  mapping = {
   normal = {
    -- Commands
    ["j"] = "scrollDown",

    -- Multi-character combos
    ["gg"] = "scrollToTop",

    -- Control key combos
    ["C-f"] = "scrollHalfPageDown",

    -- Native keystrokes
    ["t"] = { "cmd", "t" }, -- ⌘T (new tab)

    -- Map to other keystrokes
    ["h"] = { "shift", "4" }, -- map to `$` key

    -- Custom function
    ["Q"] = function()
     -- this is just an example, you can do anything
     hs.alert.show("Hello from Vimnav!")
    end,

    -- Disable mapping and pass through to the app
    ["/"] = "noop",

    -- Use <leader> key
    ["<leader>g"] = "anyCommandYouLike",
   },
  },
 })
 :start()
```

### 📊 Visual Indicators

#### 📍 Menubar Indicator

<https://github.com/user-attachments/assets/671cc359-3500-4baa-baa5-1582d39c8986>

Shows current mode in your menu bar (enabled by default):

```lua
spoon.Vimnav:configure({
 menubar = { enabled = false } -- Disable if preferred
})
```

#### 🎯 Overlay Indicator

Show a floating overlay on your screen:

<https://github.com/user-attachments/assets/a43af6b7-0947-4e2b-bc91-9b8cf969ee28>

```lua
spoon.Vimnav:configure({
 menubar = { enabled = false },
 overlay = {
  enabled = true,
  position = "top-center",    -- Position on screen
  size = 25,                  -- Indicator size
  padding = 4,                -- Padding around screen frame
  textFont = ".AppleSystemUIFontHeavy", -- Text font
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

You can run `hs.inspect(hs.styledtext.fontNames())` in Hammerspoon console to see all available fonts.

### 🔧 Advanced Configuration

#### Configure hints style

By default, the hints are shown like vimium's design. Gradient yellow with black border.

You can change them if you want to:

```lua
spoon.Vimnav:configure({
 hints = {
  fontSize = 12, -- Font size
  textFont = ".AppleSystemUIFontHeavy", -- Text font
  colors = {
   from = "#FFF585", -- Background gradient from color
   to = "#FFC442", -- Background gradient to color
   angle = 45, -- Background gradient angle
   border = "#000000", -- Border color
   borderWidth = 1, -- Border width (0 for no border)
   textColor = "#000000", -- Text color
  },
 },
})
```

#### Array Extension Behavior

By default, array configs **extend** the defaults:

```lua
-- This ADDS to the default excluded apps
spoon.Vimnav:configure({
 applicationGroups = {
  exclusions = { "VSCode", "Emacs" }
 }
})
-- Result: includes defaults + your additions
```

To **replace** instead of extend:

```lua
spoon.Vimnav:configure({
 applicationGroups = {
  exclusions = { "VSCode" }, -- Only exclude VSCode
 },
}, { extend = false })
```

#### 🎯 Accessibility Roles

Control which UI elements are detected:

```lua
spoon.Vimnav:configure({
 axRoles = {
  -- Elements treated as text inputs
  editable = {
   "AXTextField",
   "AXComboBox",
   "AXTextArea",
   "AXSearchField",
  },

  -- Elements shown in link hints
  jumpable = {
   "AXLink",
   "AXButton",
   "AXPopUpButton",
   "AXCheckBox",
   "AXRadioButton",
   "AXMenuItem",
  },
 },
})
```

#### ⚡ Performance Tuning

```lua
spoon.Vimnav:configure({
 hints = {
  depth = 15, -- Max element depth (lower = faster)
 },
 focusCheckInterval = 0.2, -- Focus detection frequency
 scroll = {
  smoothScrollFramerate = 60, -- Lower FPS for less CPU
 },
})

```

## 🎮 Available Commands

There are lots of commands available, but you can also use any key combination you want.

Check out the source code for all available commands and their usage or use this function to get all the defaults.

```lua
print(hs.inspect(spoon.Vimnav:getDefaultConfig()))
```

## 🔧 API Reference

### Methods

```lua
-- Lifecycle
spoon.Vimnav:init()                      -- Initialize
spoon.Vimnav:configure(config, opts)     -- Set configuration
spoon.Vimnav:start()                     -- Start Vimnav
spoon.Vimnav:stop()                      -- Stop Vimnav
spoon.Vimnav:restart()                   -- Restart Vimnav

-- Status
spoon.Vimnav:isRunning()                 -- Returns boolean

-- Utility
spoon.Vimnav:debug()                     -- Returns state and config
spoon.Vimnav:getDefaultConfig()          -- Returns default config
```

### Configuration Options

<details>
<summary><b>📋 Full Configuration Reference</b></summary>

```lua
{
 -- Logging
 logLevel = "warning",

 -- Leader key
 leader = {
  key = " ", -- space
  timeout = 0.5,
 },

 -- Link Hints
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

 -- Timing
 focusCheckInterval = 0.1,

 -- Keybindings
 mapping = {
  normal = { ... },
  insertNormal = { ... },
  insertVisual = { ... },
 },

 -- Scrolling
 scroll = {
  scrollStep = 50,
  scrollStepHalfPage = 500,
  scrollStepFullPage = 1e6,
  smoothScroll = true,
  smoothScrollFramerate = 120,
 },

 -- Accessibility Roles
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
   "AXMenuBarItem",
   "AXMenuItem",
   "AXRow",
  },
 },

 -- Application Lists
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

 -- Indicators
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
  },
 },
}
```

</details>

## 🐛 Troubleshooting

### ❌ Vimnav isn't working

**Check these first:**

1. ✅ **Accessibility permissions** enabled (System Settings → Privacy & Security)
2. ✅ **Installation path** correct (`~/.hammerspoon/Spoons/Vimnav.spoon`)
3. ✅ **Hammerspoon console** shows no errors

### ⌨️ Text editing commands not working

- Ensure you're in Insert Normal mode (press `Esc` once in a text field)
- Verify the text field is focused
- Some apps have limited accessibility API support

### 🐌 Performance issues

**Try these optimizations:**

- Reduce element depth: `depth = 10`
- Increase check interval: `focusCheckInterval = 0.3`
- Disable smooth scrolling: `scroll.smoothScroll = false`
- Exclude problematic apps

### 🎯 Link hints not showing

- App may not expose accessibility elements (common in Electron apps)
- Try pressing `f` multiple times
- Adjust `axRoles.jumpable` configuration
- Some web content needs time to load

### 🚫 Keys not working / conflicts

- Check for conflicts with other Hammerspoon modules
- Verify app isn't in `applicationGroups.exclusions`
- Try passthrough mode (`i`) to temporarily bypass

### 🔍 Launcher detection issues

Add problematic launchers to excluded apps:

```lua
applicationGroups = {
 exclusions = { "Spotlight", "Raycast", "Alfred" }
}
```

## ⚠️ Known Limitations

- **Electron apps** — Limited or no support due to poor accessibility
- **Web extensions** — May conflict with browser Vim extensions
- **Modal dialogs** — Some system dialogs block accessibility APIs
- **Complex editing** — Vim macros and registers not supported

## ⚡ Performance & Architecture

Vimnav is built for speed:

- 🔄 **Async coroutines** — Non-blocking element traversal
- 📍 **Spatial indexing** — Only processes visible elements
- 🎱 **Object pooling** — Minimizes GC pressure
- 💾 **Smart caching** — Accessibility queries cached intelligently
- 📦 **Batch processing** — Elements processed in optimized chunks

**Performance:** Link hints typically appear in <100ms on most pages.

## 🤝 Contributing

Contributions are welcome!

> **Note:** This is a personal project maintained on a best-effort basis. PRs are more likely to be reviewed than feature requests.

**How to contribute:**

1. 🍴 Fork the repository
2. 🌿 Create a feature branch
3. ✨ Make your changes with clear commits
4. 🧪 Test thoroughly on multiple apps
5. 📬 Submit a PR with a clear description

## 🙏 Credits

Vimnav is based on [Vifari](https://github.com/dzirtusss/vifari) by dzirtuss, extensively rewritten for system-wide support, performance optimization, and enhanced features including full modal text editing.

## 📄 License

MIT License — See [LICENSE](LICENSE) file for details.

<p align="center">
  <b>Made with ⌨️  by developers who never touch their mouse</b>
  <br><br>
  ⭐ Star this repo if you find it useful!
</p>
