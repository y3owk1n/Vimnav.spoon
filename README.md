# Vimnav.spoon

**Vim navigation for your entire Mac.** Navigate any macOS application with Vim-like keybindings using Hammerspoon. Think Vimium, but system-wide.

<p align="left">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" alt="Platform: macOS">
  <img src="https://img.shields.io/badge/requires-Hammerspoon-blue" alt="Requires: Hammerspoon">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
</p>

## Why Vimnav?

Stop reaching for your mouse. Navigate Safari, Mail, Finder, or any macOS app with the same muscle memory you use in Vim. Vimnav brings powerful keyboard-driven navigation to your entire desktop.

**Key highlights:**

- Works across **all native macOS apps** (Safari, Mail, Finder, System Settings, etc.)
- **Smart mode switching** — automatically enters insert mode in text fields
- **Visual link hints** — click anything without touching your mouse
- **Performance optimized** — async traversal, spatial indexing, memory pooling
- **Highly customizable** — keybindings, callbacks, excluded apps

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

| Icon   | Mode        | When                          |
| ------ | ----------- | ----------------------------- |
| **N**  | Normal      | Default navigation mode       |
| **I**  | Insert      | Auto-activated in text fields |
| **IP** | Passthrough | Manual activation (press `i`) |
| **L**  | Links       | Showing link hints            |
| **M**  | Multi       | Multi-key input (e.g., `gg`)  |
| **X**  | Disabled    | In excluded apps              |

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
    }
}):start()
```

### Integration with Other Spoons

Vimnav provides callbacks for seamless integration:

```lua
local VimMode = hs.loadSpoon('VimMode')
local vim = VimMode:new()

spoon.Vimnav:configure({
    -- Enable VimMode when entering text fields
    enterEditableCallback = function()
        vim:enable()
    end,

    -- Disable VimMode when exiting text fields
    exitEditableCallback = function()
        vim:disable()
    end,

    -- Handle force unfocus (double Esc in browser)
    forceUnfocusCallback = function()
        vim:exit()
        vim:disable()
    end,
}):start()
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
    -- Elements treated as text inputs
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

### Utilities

- `cmdCopyPageUrlToClipboard` — Copy page URL (browser)
- `cmdCopyLinkUrlToClipboard` — Copy link URL (browser)
- `cmdDownloadImage` — Save images (browser)
- `cmdMoveMouseToCenter` — Center cursor
- `cmdNextPage/PrevPage` — Navigate pagination (browser)

### Mode Control

- `cmdPassthroughMode` — Enter passthrough mode
- `cmdNormalMode` — Return to normal mode
- `cmdInsertMode` — Enter insert mode

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

    -- Callbacks
    enterEditableCallback = function() end,  -- Called when entering text field
    exitEditableCallback = function() end,   -- Called when exiting text field
    forceUnfocusCallback = function() end,   -- Called on double-escape in browser

    -- Keybindings (see Default Mapping section)
    mapping = { ... }
}
```

</details>

## Troubleshooting

### Vimnav isn't working

1. **Check Accessibility permissions**: System Settings → Privacy & Security → Accessibility → Enable Hammerspoon
2. **Verify installation**: `ls ~/.hammerspoon/Spoons/` should show `Vimnav.spoon`

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

## Known Limitations

- **Electron apps**: Limited or no support due to poor accessibility
- **Web extensions**: May conflict with browser's native Vim extensions
- **Modal dialogs**: Some system dialogs block accessibility APIs

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

Vimnav is based on [Vifari](https://github.com/dzirtusss/vifari) by dzirtuss, extensively rewritten for system-wide support, performance optimization, and enhanced features.

## License

MIT License — See [LICENSE](LICENSE) file for details.

<p align="center">
  Made with ⌨️  by developers who never touch their mouse
</p>
