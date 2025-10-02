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
- ✍️ **Full modal text editing** — Normal and Visual modes inside text field (Only for those mappable shortcuts)
- 🚀 **Performance optimized** — async traversal, spatial indexing, memory pooling
- 🎛️ **Highly customizable** — keybindings, launchers, excluded apps

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

5. **Reload** → Press `⌘⌃R` in Hammerspoon

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

| Key             | Action    | Description                    |
| --------------- | --------- | ------------------------------ |
| `h`/`j`/`k`/`l` | Scroll    | Vim-style directional movement |
| `C-d`/`C-u`     | Half page | Fast vertical scrolling        |
| `gg`/`G`        | Jump      | Top or bottom of page          |
| `H`/`L`         | History   | Back/forward (⌘[ / ⌘])         |

### 🎯 Link Hints Mode

Press `f` to enter link hints mode. Interactive elements get labeled:

```
[AA] Sign In    [AB] Register    [AC] Learn More
[AD] Products   [AE] Pricing     [AF] Contact
```

Type the letters (e.g., `AA`) to click that element instantly!

| Key  | Action                | Works In |
| ---- | --------------------- | -------- |
| `f`  | Click element         | All apps |
| `F`  | Open in new tab       | Browsers |
| `r`  | Right-click element   | All apps |
| `gi` | Jump to input field   | All apps |
| `gf` | Move mouse to element | All apps |
| `yf` | Copy link URL         | Browsers |

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
| `p`   | Paste             | Paste from clipboard (⌘V) |

**Mode Switching:**

| Key   | Action               | Description               |
| ----- | -------------------- | ------------------------- |
| `i`   | Insert mode          | Return to insert mode     |
| `A`   | Insert at line end   | Jump to end + insert mode |
| `I`   | Insert at line start | Jump to start + insert    |
| `v`   | Visual mode          | Enter visual mode         |
| `V`   | Visual line mode     | Select entire line        |
| `Esc` | Force unfocus        | Exit field completely     |

#### 🎨 Insert Visual Mode (`v` from Insert Normal)

Select text visually with Vim motions:

| Key   | Action                | Description              |
| ----- | --------------------- | ------------------------ |
| `h`   | ⇧← extend left        | Extend selection left    |
| `l`   | ⇧→ extend right       | Extend selection right   |
| `j`   | ⇧↓ extend down        | Extend selection down    |
| `k`   | ⇧↑ extend up          | Extend selection up      |
| `e`   | ⇧⌥→ extend word end   | Extend to word end       |
| `b`   | ⇧⌥← extend word back  | Extend to word start     |
| `0`   | ⇧⌘← extend line start | Extend to line start     |
| `$`   | ⇧⌘→ extend line end   | Extend to line end       |
| `gg`  | ⇧⌘↑ extend doc start  | Extend to document start |
| `G`   | ⇧⌘↓ extend doc end    | Extend to document end   |
| `d`   | Delete selection      | Delete highlighted text  |
| `c`   | Change selection      | Delete + insert mode     |
| `y`   | Yank selection        | Copy highlighted text    |
| `Esc` | Exit visual           | Back to insert normal    |

**🔄 Mode Flow:**

```
Insert → [Esc] → Insert Normal → [v/V] → Insert Visual
                      ↑                          ↓
                      └────────[Esc]─────────────┘
```

### 🌐 Browser-Specific Features

Enhanced functionality in Safari, Chrome, Firefox, Edge, Brave, and Zen:

| Key       | Action                    |
| --------- | ------------------------- |
| `yy`      | Copy current page URL     |
| `yf`      | Copy link URL (after `f`) |
| `F`       | Open link in new tab      |
| `di`      | Download image            |
| `]]`/`[[` | Next/previous page        |
| `Esc Esc` | Force unfocus from forms  |

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
spoon.Vimnav:configure({
 scrollStep = 100,              -- Faster scrolling
 smoothScroll = true,           -- Smooth animations
 linkHintChars = "asdfghjkl",   -- Home row only
 excludedApps = {               -- Don't run in these apps
  "Terminal",
  "iTerm2",
  "VSCode"
 }
}):start()
```

### ⌨️ Custom Keybindings

Map any key to any command or native keystroke:

```lua
spoon.Vimnav:configure({
 mapping = {
  normal = {
   -- Commands
   ["j"] = "cmdScrollDown",
   ["k"] = "cmdScrollUp",
   ["f"] = "cmdGotoLink",

   -- Multi-character combos
   ["gg"] = "cmdScrollToTop",
   ["gt"] = "cmdGotoInput",

   -- Control key combos
   ["C-f"] = "cmdScrollHalfPageDown",
   ["C-b"] = "cmdScrollHalfPageUp",

   -- Native keystrokes
   ["t"] = { "cmd", "t" },     -- ⌘T (new tab)
   ["w"] = { "cmd", "w" },     -- ⌘W (close window)
  },
  insertNormal = {
   -- Customize text editing
   ["h"] = { {}, "left" },
   ["l"] = { {}, "right" },
   ["w"] = { "alt", "right" },
   ["b"] = { "alt", "left" },
  },
  insertVisual = {
   -- Customize visual selection
   ["h"] = { { "shift" }, "left" },
   ["l"] = { { "shift" }, "right" },
  }
 }
}):start()
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
  padding = 2,                -- Padding
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

### 🔧 Advanced Configuration

#### Array Extension Behavior

By default, array configs **extend** the defaults:

```lua
-- This ADDS to the default excluded apps
spoon.Vimnav:configure({
    excludedApps = { "VSCode", "Emacs" }
})
-- Result: includes defaults + your additions
```

To **replace** instead of extend:

```lua
spoon.Vimnav:configure({
    excludedApps = { "VSCode" }  -- Only exclude VSCode
}, { extend = false })
```

#### 🎯 Accessibility Roles

Control which UI elements are detected:

```lua
spoon.Vimnav:configure({
 -- Elements treated as text inputs
 axEditableRoles = {
  "AXTextField",
  "AXComboBox",
  "AXTextArea",
  "AXSearchField"
 },

 -- Elements shown in link hints
 axJumpableRoles = {
  "AXLink",
  "AXButton",
  "AXPopUpButton",
  "AXCheckBox",
  "AXRadioButton",
  "AXMenuItem"
 }
})
```

#### ⚡ Performance Tuning

```lua
spoon.Vimnav:configure({
 depth = 15,                    -- Max element depth (lower = faster)
 focusCheckInterval = 0.2,      -- Focus detection frequency
 smoothScrollFramerate = 60,    -- Lower FPS for less CPU
})
```

## 🎮 Available Commands

Use these in your `mapping` configuration:

### 🧭 Navigation Commands

- `cmdScrollLeft/Right/Up/Down` — Directional scrolling
- `cmdScrollHalfPageUp/Down` — Half-page jumps
- `cmdScrollToTop/Bottom` — Jump to extremes

### 🎯 Link Hint Commands

- `cmdGotoLink` — Click elements
- `cmdGotoLinkNewTab` — Open in new tab (browser)
- `cmdGotoInput` — Jump to input fields
- `cmdRightClick` — Show right-clickable elements
- `cmdMoveMouseToLink` — Move cursor to element

### ✍️ Text Editing Commands (Insert Normal)

- `cmdDeleteWord/Line` — Delete operations
- `cmdChangeWord/Line` — Change operations (delete + insert)
- `cmdYankWord/Line` — Copy operations
- `cmdUndo` — Undo last change

### 🎨 Text Editing Commands (Insert Visual)

- `cmdDeleteHighlighted` — Delete selection
- `cmdChangeHighlighted` — Change selection
- `cmdYankHighlighted` — Copy selection

### 🔄 Mode Control Commands

- `cmdInsertMode` — Enter insert mode
- `cmdInsertModeEnd` — Insert at line end
- `cmdInsertModeStart` — Insert at line start
- `cmdInsertVisualMode` — Enter visual mode
- `cmdInsertVisualLineMode` — Enter visual line mode
- `cmdPassthroughMode` — Enter passthrough mode

### 🛠️ Utility Commands

- `cmdCopyPageUrlToClipboard` — Copy page URL (browser)
- `cmdCopyLinkUrlToClipboard` — Copy link URL (browser)
- `cmdDownloadImage` — Save images (browser)
- `cmdMoveMouseToCenter` — Center cursor
- `cmdNextPage/PrevPage` — Navigate pagination (browser)

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
```

### Configuration Options

<details>
<summary><b>📋 Full Configuration Reference</b></summary>

```lua
{
 -- Logging
 logLevel = "warning",

 -- Link Hints
 linkHintChars = "abcdefghijklmnopqrstuvwxyz",
 hintFontSize = 12,

 -- Timing
 doublePressDelay = 0.3,
 focusCheckInterval = 0.1,

 -- Scrolling
 scrollStep = 50,
 scrollStepHalfPage = 500,
 scrollStepFullPage = 1e6,
 smoothScroll = true,
 smoothScrollFramerate = 120,

 -- Performance
 depth = 20,

 -- Application Lists
 excludedApps = {
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
 launchers = {
  "Spotlight",
  "Raycast",
  "Alfred",
 },

 -- Accessibility Roles
 axEditableRoles = {
  "AXTextField",
  "AXComboBox",
  "AXTextArea",
  "AXSearchField",
 },
 axJumpableRoles = {
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

 -- Keybindings
 mapping = {
  normal = { ... },
  insertNormal = { ... },
  insertVisual = { ... },
 },

 -- Indicators
 menubar = {
  enabled = true,
 },
 overlay = {
  enabled = false,
  position = "top-center",
  size = 25,
  padding = 2,
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
- Disable smooth scrolling: `smoothScroll = false`
- Exclude problematic apps

### 🎯 Link hints not showing

- App may not expose accessibility elements (common in Electron apps)
- Try pressing `f` multiple times
- Adjust `axJumpableRoles` configuration
- Some web content needs time to load

### 🚫 Keys not working / conflicts

- Check for conflicts with other Hammerspoon modules
- Verify app isn't in `excludedApps`
- Try passthrough mode (`i`) to temporarily bypass

### 🔍 Launcher detection issues

Add problematic launchers to excluded apps:

```lua
excludedApps = { "Spotlight", "Raycast", "Alfred" }
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
