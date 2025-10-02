# Vimnav.spoon

**Vim navigation for your entire Mac.** Navigate any macOS application with Vim-like keybindings using Hammerspoon. Think Vimium, but system-wide.

<p align="left">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" alt="Platform: macOS">
  <img src="https://img.shields.io/badge/requires-Hammerspoon-blue" alt="Requires: Hammerspoon">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
</p>

![vimnav-demo](https://github.com/user-attachments/assets/b32374e0-5446-46f8-99d2-bfae1bc90799)

## Why Vimnav?

Stop reaching for your mouse. Navigate Safari, Mail, Finder, or any macOS app with the same muscle memory you use in Vim. Vimnav brings powerful keyboard-driven navigation to your entire desktop.

**Key highlights:**

- Works across **all native macOS apps** (Safari, Mail, Finder, System Settings, etc.)
- **Smart mode switching** — automatically enters insert mode in text fields
- **Vim text editing** — basic mappings for full modal editing inside text fields (Normal, Visual modes)
- **Visual link hints** — click anything without touching your mouse
- **Performance optimized** — async traversal, spatial indexing, memory pooling
- **Highly customizable** — keybindings, launchers, excluded apps

## Quick Start

### Installation

1. Install [Hammerspoon](https://www.hammerspoon.org/)
2. Enable **Accessibility permissions** for Hammerspoon in System Settings
3. Download and place `Vimnav.spoon` in `~/.hammerspoon/Spoons/`
4. Add to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Vimnav")
spoon.Vimnav:start()
```

5. Reload Hammerspoon (⌘⌃R)

### First Steps

Press `f` in Safari to see link hints overlay on all clickable elements. Type the letters shown to click. Press `Esc` to cancel.

Try these basics:

- `j`/`k` — scroll down/up
- `gg`/`G` — jump to top/bottom
- `f` — show clickable elements
- `gi` — jump to first input field
- Click in a text field, press `Esc` to enter Insert Normal mode, then `v` for Visual mode

## Features

### Core Navigation

| Key             | Action    | Description                    |
| --------------- | --------- | ------------------------------ |
| `h`/`j`/`k`/`l` | Scroll    | Vim-style directional movement |
| `C-d`/`C-u`     | Half page | Fast vertical scrolling        |
| `gg`/`G`        | Jump      | Top or bottom of page          |
| `H`/`L`         | History   | Back/forward (⌘[ / ⌘])         |

### Link Hints Mode

Press `f` to enter link hints mode. Interactive elements get labeled with letter combinations:

```
[AA] Sign In    [AB] Register    [AC] Learn More
[AD] Products   [AE] Pricing     [AF] Contact
```

Type the letters (e.g., `AA`) to click that element. No mouse needed.

| Key  | Action                | Works In |
| ---- | --------------------- | -------- |
| `f`  | Click element         | All apps |
| `F`  | Open in new tab       | Browsers |
| `r`  | Right-click element   | All apps |
| `gi` | Jump to input field   | All apps |
| `gf` | Move mouse to element | All apps |
| `yf` | Copy link URL         | Browsers |

### Text Editing Modes

When you focus a text field, Vimnav automatically enters **Insert mode**. Press `Esc` to enter **Insert Normal mode** for Vim-like editing:

#### Insert Normal Mode (`Esc` from Insert)

Navigate and manipulate text without leaving the input field:

| Key   | Action                    | Description                 |
| ----- | ------------------------- | --------------------------- |
| `h`   | ← cursor left             | Move left                   |
| `l`   | → cursor right            | Move right                  |
| `j`   | ↓ cursor down             | Move down                   |
| `k`   | ↑ cursor up               | Move up                     |
| `e`   | ⌥→ word end               | Jump to end of word         |
| `b`   | ⌥← word back              | Jump to start of word       |
| `0`   | ⌘← line start             | Jump to line start          |
| `$`   | ⌘→ line end               | Jump to line end            |
| `gg`  | ⌘↑ document start         | Jump to document start      |
| `G`   | ⌘↓ document end           | Jump to document end        |
| `diw` | Delete inner word         | Delete word under cursor    |
| `ciw` | Change inner word         | Delete word + insert mode   |
| `yiw` | Yank inner word           | Copy word                   |
| `dd`  | Delete line               | Delete current line         |
| `cc`  | Change line               | Delete line + insert mode   |
| `yy`  | Yank line                 | Copy current line           |
| `u`   | Undo                      | Undo last change (⌘Z)       |
| `i`   | Insert mode               | Return to insert mode       |
| `A`   | Insert at line end        | Jump to end + insert mode   |
| `I`   | Insert at line start      | Jump to start + insert mode |
| `v`   | Visual mode               | Enter visual mode           |
| `V`   | Visual line mode          | Select entire line          |
| `p`   | Paste                     | Paste from clipboard (⌘V)   |
| `Esc` | Force unfocus (2x in web) | Exit field completely       |

#### Insert Visual Mode (`v` from Insert Normal)

Select text visually with Vim motions:

| Key   | Action                  | Description                |
| ----- | ----------------------- | -------------------------- |
| `h`   | ⇧← extend left          | Extend selection left      |
| `l`   | ⇧→ extend right         | Extend selection right     |
| `j`   | ⇧↓ extend down          | Extend selection down      |
| `k`   | ⇧↑ extend up            | Extend selection up        |
| `e`   | ⇧⌥→ extend word end     | Extend to word end         |
| `b`   | ⇧⌥← extend word back    | Extend to word start       |
| `0`   | ⇧⌘← extend line start   | Extend to line start       |
| `$`   | ⇧⌘→ extend line end     | Extend to line end         |
| `gg`  | ⇧⌘↑ extend doc start    | Extend to document start   |
| `G`   | ⇧⌘↓ extend doc end      | Extend to document end     |
| `d`   | Delete selection        | Delete highlighted text    |
| `c`   | Change selection        | Delete + enter insert mode |
| `y`   | Yank selection          | Copy highlighted text      |
| `Esc` | Exit visual (→ IN mode) | Back to insert normal      |

**Mode transitions:**

- **Insert → Insert Normal**: Press `Esc` once
- **Insert Normal → Insert Visual**: Press `v` or `V`
- **Insert Visual → Insert Normal**: Press `Esc` once
- **Any Insert mode → Normal**: Press `Esc` twice (browsers: force unfocus)

### Browser-Specific Features

Enhanced functionality in Safari, Chrome, Firefox, Edge, Brave, and Zen:

| Key       | Action                       |
| --------- | ---------------------------- |
| `yy`      | Copy current page URL        |
| `yf`      | Copy link URL (after `f`)    |
| `F`       | Open link in new tab         |
| `di`      | Download image               |
| `]]`/`[[` | Next/previous page           |
| `Esc Esc` | Force unfocus from web forms |

### Modes

Vimnav operates in different modes, shown in the menu bar:

| Icon   | Mode          | When                                |
| ------ | ------------- | ----------------------------------- |
| **N**  | Normal        | Default navigation mode             |
| **I**  | Insert        | Auto-activated in text fields       |
| **IN** | Insert Normal | Vim navigation within text fields   |
| **IV** | Insert Visual | Vim visual selection in text fields |
| **P**  | Passthrough   | Manual activation (press `i`)       |
| **L**  | Links         | Showing link hints                  |
| **X**  | Disabled      | In excluded apps                    |

## Configuration

### Basic Setup

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

### Custom Keybindings

Map any key to any command or native keystroke:

```lua
spoon.Vimnav:configure({
    mapping = {
        normal = {
            -- Use commands
            ["j"] = "cmdScrollDown",
            ["k"] = "cmdScrollUp",
            ["f"] = "cmdGotoLink",

            -- Multi-character combos
            ["gg"] = "cmdScrollToTop",
            ["gt"] = "cmdGotoInput",

            -- Control key combos
            ["C-f"] = "cmdScrollHalfPageDown",
            ["C-b"] = "cmdScrollHalfPageUp",

            -- Pass through native keystrokes
            ["t"] = { "cmd", "t" },     -- ⌘T (new tab)
            ["w"] = { "cmd", "w" },     -- ⌘W (close window)
        },
        insertNormal = {
            -- Customize text editing keys
            ["h"] = { {}, "left" },
            ["l"] = { {}, "right" },
            ["w"] = { "alt", "right" },
            ["b"] = { "alt", "left" },
        },
        insertVisual = {
            -- Customize visual selection keys
            ["h"] = { { "shift" }, "left" },
            ["l"] = { { "shift" }, "right" },
        }
    }
}):start()
```

### Indicator

#### Menubar indicator

<https://github.com/user-attachments/assets/671cc359-3500-4baa-baa5-1582d39c8986>

By default, Vimnav shows a small indicator in the menu bar.

```lua
spoon.Vimnav:configure({
    menubar = { enabled = false } -- disable the menubar indicator
})
```

#### Overlay indicator

Vimnav can also show an overlay indicator in the certain position of the screen.

<https://github.com/user-attachments/assets/a43af6b7-0947-4e2b-bc91-9b8cf969ee28>

```lua
spoon.Vimnav:configure({
 menubar = {
  enabled = false, -- disable the menubar indicator
 },
 overlay = {
  enabled = true, -- enable the overlay indicator
  position = "top-center", -- pick a position, this is the default
  size = 25, -- pick a size, this is the default
  padding = 2, -- pick a padding, this is the default
  colors = { -- colors for different modes
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

### Advanced Configuration

#### Array Extension Behavior

By default, array configs **extend** the defaults:

```lua
-- This ADDS to the default excluded apps
spoon.Vimnav:configure({
    excludedApps = { "VSCode", "Emacs" }
})
-- Result: ["Terminal", "Alacritty", "iTerm2", "Kitty", "Ghostty", "VSCode", "Emacs"]
```

To **replace** instead of extend:

```lua
spoon.Vimnav:configure({
    excludedApps = { "VSCode" }  -- Only exclude VSCode
}, { extend = false })
```

#### Accessibility Roles

Control which UI elements are detected:

```lua
spoon.Vimnav:configure({
    -- Elements treated as text inputs (auto-enter Insert mode)
    axEditableRoles = {
        "AXTextField",
        "AXComboBox",
        "AXTextArea",
        "AXSearchField"
    },

    -- Elements shown in link hints mode
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

#### Performance Tuning

```lua
spoon.Vimnav:configure({
    depth = 15,                    -- Max element depth (lower = faster)
    focusCheckInterval = 0.2,      -- Focus detection frequency
    smoothScrollFramerate = 60,    -- Lower FPS for less CPU
})
```

## Available Commands

Use these in your `mapping` configuration:

### Navigation

- `cmdScrollLeft/Right/Up/Down` — Directional scrolling
- `cmdScrollHalfPageUp/Down` — Half-page jumps
- `cmdScrollToTop/Bottom` — Jump to extremes

### Link Hints

- `cmdGotoLink` — Click elements
- `cmdGotoLinkNewTab` — Open in new tab (browser)
- `cmdGotoInput` — Jump to input fields
- `cmdRightClick` — Show right-clickable elements
- `cmdMoveMouseToLink` — Move cursor to element

### Text Editing (Insert Normal Mode)

- `cmdDeleteWord/Line` — Delete operations
- `cmdChangeWord/Line` — Change operations (delete + insert)
- `cmdYankWord/Line` — Copy operations
- `cmdUndo` — Undo last change

### Text Editing (Insert Visual Mode)

- `cmdDeleteHighlighted` — Delete selection
- `cmdChangeHighlighted` — Change selection (delete + insert)
- `cmdYankHighlighted` — Copy selection

### Insert Mode Control

- `cmdInsertMode` — Enter insert mode
- `cmdInsertModeEnd` — Insert mode at line end
- `cmdInsertModeStart` — Insert mode at line start
- `cmdInsertVisualMode` — Enter visual mode
- `cmdInsertVisualLineMode` — Enter visual line mode

### Utilities

- `cmdCopyPageUrlToClipboard` — Copy page URL (browser)
- `cmdCopyLinkUrlToClipboard` — Copy link URL (browser)
- `cmdDownloadImage` — Save images (browser)
- `cmdMoveMouseToCenter` — Center cursor
- `cmdNextPage/PrevPage` — Navigate pagination (browser)

### Mode Control

- `cmdPassthroughMode` — Enter passthrough mode

## API Reference

### Methods

```lua
-- Lifecycle
spoon.Vimnav:init()                      -- Initialize (called automatically)
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
<summary><b>Full Configuration Reference</b></summary>

```lua
{
    -- Logging
    logLevel = "warning",                    -- "debug", "info", "warning", "error"

    -- Link Hints
    linkHintChars = "abcdefghijklmnopqrstuvwxyz",

    -- Timing
    doublePressDelay = 0.3,                  -- Double-press detection (seconds)
    focusCheckInterval = 0.1,                -- Focus check frequency (seconds)

    -- Scrolling
    scrollStep = 50,                         -- Basic scroll distance (pixels)
    scrollStepHalfPage = 500,               -- Half-page scroll (pixels)
    scrollStepFullPage = 1000000,           -- Full-page scroll (pixels)
    smoothScroll = true,                     -- Enable smooth scrolling
    smoothScrollFramerate = 120,             -- Smooth scroll FPS

    -- Performance
    depth = 20,                              -- Element traversal depth

    -- Application Lists
    excludedApps = {
        "Terminal", "Alacritty", "iTerm2", "Kitty", "Ghostty"
    },
    browsers = {
        "Safari", "Google Chrome", "Firefox",
        "Microsoft Edge", "Brave Browser", "Zen"
    },
    launchers = {
        "Spotlight", "Raycast", "Alfred"
    },

    -- Accessibility Roles
    axEditableRoles = {
        "AXTextField", "AXComboBox", "AXTextArea", "AXSearchField"
    },
    axJumpableRoles = {
        "AXLink", "AXButton", "AXPopUpButton", "AXComboBox",
        "AXTextField", "AXTextArea", "AXCheckBox", "AXRadioButton",
        "AXDisclosureTriangle", "AXMenuButton", "AXMenuBarItem", "AXMenuItem", "AXRow"
    },

    -- Keybindings
    mapping = {
        normal = { ... },        -- Normal mode mappings
        insertNormal = { ... },  -- Insert normal mode mappings
        insertVisual = { ... },  -- Insert visual mode mappings
    }
}
```

</details>

## Troubleshooting

### Vimnav isn't working

1. **Check Accessibility permissions**: System Settings → Privacy & Security → Accessibility → Enable Hammerspoon
2. **Verify installation**: `ls ~/.hammerspoon/Spoons/` should show `Vimnav.spoon`
3. **Check Hammerspoon console**: Look for error messages

### Text editing commands not working

- Ensure you're in Insert Normal mode (press `Esc` once in a text field)
- Check that the text field is actually focused
- Some apps may not fully support accessibility APIs

### Performance issues

- **Reduce depth**: `depth = 10` for faster element detection
- **Increase intervals**: `focusCheckInterval = 0.3` for less frequent checks
- **Disable smooth scrolling**: `smoothScroll = false`
- **Exclude problematic apps**: Add to `excludedApps`

### Link hints not showing

- App may not expose accessibility elements properly (common in Electron apps)
- Try pressing `f` multiple times or adjusting `axJumpableRoles`
- Some web content requires time to load

### Keys not working / conflicts

- Check if another Hammerspoon module is capturing the same keys
- Verify the app isn't in `excludedApps`
- Try passthrough mode (`i`) to bypass Vimnav temporarily

### Launcher detection issues

If Spotlight/Raycast/Alfred triggers Vimnav modes unexpectedly, add them to excluded apps:

```lua
excludedApps = { "Spotlight", "Raycast", "Alfred" }
```

## Known Limitations

- **Electron apps**: Limited or no support due to poor accessibility
- **Web extensions**: May conflict with browser's native Vim extensions
- **Modal dialogs**: Some system dialogs block accessibility APIs
- **Complex text editing**: Some Vim operations (macros, registers) aren't supported

## Performance & Architecture

Vimnav is built for speed and efficiency:

- **Async coroutines** — Element traversal doesn't block the UI
- **Spatial indexing** — Only processes visible viewport elements
- **Object pooling** — Mark elements are reused to minimize GC pressure
- **Smart caching** — Accessibility queries cached with automatic invalidation
- **Batch processing** — Elements processed in chunks with yielding

Typical performance: Link hints appear in <100ms on most pages.

## Contributing

Contributions are welcome! However, please note:

> This is a personal project maintained on a best-effort basis. If you find it useful, consider contributing fixes and features rather than just requesting them. PRs are more likely to be reviewed than feature requests.

**How to contribute:**

1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Test thoroughly on multiple apps
5. Submit a PR with a description of your changes

## Credits

Vimnav is based on [Vifari](https://github.com/dzirtusss/vifari) by dzirtuss, extensively rewritten for system-wide support, performance optimization, and enhanced features including full modal text editing.

## License

MIT License — See [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ⌨️  by developers who never touch their mouse
</p>
