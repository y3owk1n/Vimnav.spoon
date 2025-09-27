# Vimnav.spoon

**System-wide Vim navigation for macOS** — Navigate any macOS application with Vim-like keybindings using Hammerspoon. Think Vimium, but for your entire desktop.

> [!NOTE]
> If you like this, please help out with the project instead of just asking for features and fixes. I probably do not
> have extra time to maintain this project as long as it works for me.

## Features

### Core Navigation

- **Vim-style scrolling** — `hjkl` for directional movement, `C-d`/`C-u` for half-page scrolling
- **Link hints** — Visual overlay marks for instant clicking on any interactive element
- **Smart mode detection** — Automatically switches to insert mode when text fields are focused
- **Universal compatibility** — Works across all macOS applications (except Terminal by default)

### Advanced Interactions

- **Multiple link modes** — Open links in current window (`f`) or new tabs (`F`)
- **Right-click support** — Context menus with `r`
- **Input field navigation** — Jump directly to text fields with `gi`
- **Image downloading** — Save images directly with `di` (browser only)
- **URL copying** — Copy page or link URLs to clipboard
- **Mouse control** — Move cursor to elements or center screen

### Performance Optimized

- **Async element traversal** — Non-blocking UI with coroutine-based processing
- **Spatial indexing** — Viewport culling for faster element detection
- **Memory pooling** — Efficient mark rendering with object reuse
- **Smart caching** — Cached accessibility queries with automatic cleanup

## Installation

### Prerequisites

- [Hammerspoon](https://www.hammerspoon.org/) installed
- Accessibility permissions enabled for Hammerspoon

### Setup

#### Manual

1. Download `Vimnav.spoon` and place it in `~/.hammerspoon/Spoons/`
2. Add to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Vimnav")
spoon.Vimnav:start()
```

3. Reload Hammerspoon configuration

#### Using [Pack.spoon](https://github.com/y3owk1n/pack.spoon)

```lua
---@type Hs.Pack.PluginSpec
return {
 name = "Vimnav",
 url = "https://github.com/y3owk1n/Vimnav.spoon.git",
 config = function()
  ---@type Hs.Vimnav.Config
  local vimnavConfig = {}

  spoon.Vimnav:start(vimnavConfig)
 end,
}
```

## Usage

### Modes

Vimnav operates in several modes, indicated by the menu bar icon:

- **N** — Normal mode (default navigation)
- **I** — Insert mode (automatically activated in text fields)
- **L** — Links mode (showing interactive elements)
- **M** — Multi-character input mode
- **X** — Disabled mode (in excluded applications)

### Default Keybindings

#### Movement

| Key   | Action                |
| ----- | --------------------- |
| `h`   | Scroll left           |
| `j`   | Scroll down           |
| `k`   | Scroll up             |
| `l`   | Scroll right          |
| `C-d` | Scroll half page down |
| `C-u` | Scroll half page up   |
| `G`   | Scroll to bottom      |
| `gg`  | Scroll to top         |

#### Navigation

| Key  | Action                       |
| ---- | ---------------------------- |
| `H`  | History back (Cmd+[)         |
| `L`  | History forward (Cmd+])      |
| `f`  | Show link hints for clicking |
| `F`  | Show link hints for new tab  |
| `gi` | Jump to input field          |
| `r`  | Right-click on element       |

#### Utilities

| Key  | Action                   |
| ---- | ------------------------ |
| `yy` | Copy page URL            |
| `yf` | Copy link URL            |
| `di` | Download image (browser) |
| `gf` | Move mouse to link       |
| `zz` | Center mouse on screen   |
| `]]` | Next page button         |
| `[[` | Previous page button     |

#### Mode Control

| Key       | Action                  |
| --------- | ----------------------- |
| `i`       | Enter insert mode       |
| `Esc`     | Return to normal mode   |
| `Esc Esc` | Force unfocus (browser) |

### Link Hints

When you press `f`, `F`, or similar commands, Vimnav overlays letter combinations on interactive elements:

1. Press the trigger key (`f`, `F`, etc.)
2. Type the letters shown on your target element
3. The action executes automatically

## Configuration

### Basic Configuration

```lua
spoon.Vimnav:start({
    logLevel = "warning",
    linkHintChars = "abcdefghijklmnopqrstuvwxyz",
    scrollStep = 50,
    smoothScroll = true,
    excludedApps = { "Terminal", "iTerm2" }
})
```

### Custom Keybindings

```lua
spoon.Vimnav:start({
    mapping = {
        ["j"] = "cmdScrollDown",
        ["k"] = "cmdScrollUp",
        ["C-f"] = "cmdScrollHalfPageDown",
        ["gg"] = "cmdScrollToTop",
        ["custom"] = { "cmd", "t" }, -- Custom key stroke
        -- Add your mappings here
    }
})
```

### Available Commands

| Command                       | Description              |
| ----------------------------- | ------------------------ |
| `cmdScrollLeft/Right/Up/Down` | Directional scrolling    |
| `cmdScrollHalfPageUp/Down`    | Half-page scrolling      |
| `cmdScrollToTop/Bottom`       | Jump to extremes         |
| `cmdGotoLink`                 | Show clickable links     |
| `cmdGotoLinkNewTab`           | Links for new tabs       |
| `cmdGotoInput`                | Show input fields        |
| `cmdRightClick`               | Show right-click targets |
| `cmdInsertMode`               | Switch to insert mode    |
| `cmdCopyPageUrlToClipboard`   | Copy current page URL    |
| `cmdCopyLinkUrlToClipboard`   | Copy link URLs           |
| `cmdDownloadImage`            | Download images          |
| `cmdMoveMouseToLink`          | Move cursor to links     |
| `cmdMoveMouseToCenter`        | Center cursor            |
| `cmdNextPage/PrevPage`        | Navigate pagination      |

### Configuration Options

#### Core Settings

```lua
{
    logLevel = "warning",              -- Log verbosity
    doublePressDelay = 0.3,           -- Double-press detection (seconds)
    focusCheckInterval = 0.5,          -- Focus detection interval
    depth = 20,                        -- Element traversal depth
}
```

#### Scrolling

```lua
{
    scrollStep = 50,                   -- Basic scroll distance
    scrollStepHalfPage = 500,         -- Half-page scroll distance
    scrollStepFullPage = 1000000,     -- Full-page scroll distance
    smoothScroll = true,               -- Enable smooth scrolling
    smoothScrollFramerate = 120,       -- Smooth scroll FPS
}
```

#### Application Lists

```lua
{
    excludedApps = { "Terminal" },     -- Apps to disable Vimnav
    browsers = {                       -- Browser detection for web features
        "Safari", "Google Chrome",
        "Firefox", "Microsoft Edge",
        "Brave Browser", "Zen"
    },
    launchers = {                      -- Launcher detection
        "Spotlight", "Raycast", "Alfred"
    }
}
```

#### Accessibility Roles

```lua
{
    axEditableRoles = {                -- Text input detection
        "AXTextField", "AXComboBox",
        "AXTextArea", "AXSearchField"
    },
    axJumpableRoles = {               -- Interactive element detection
        "AXLink", "AXButton", "AXPopUpButton",
        "AXComboBox", "AXCheckBox", "AXRadioButton"
        -- ... more roles
    }
}
```

## Browser Integration

Vimnav provides enhanced features when used with supported browsers:

- **URL operations** — Copy page/link URLs, open in new tabs
- **Image downloading** — Direct image saving to Downloads folder
- **Navigation helpers** — Next/previous page detection
- **Force unfocus** — Double-escape to exit web form focus

## Troubleshooting

### Performance Issues

- Reduce `depth` setting for faster element detection
- Adjust `focusCheckInterval` for less frequent focus checks
- Add problematic apps to `excludedApps`

### Accessibility Permissions

Ensure Hammerspoon has Full Disk Access and Accessibility permissions in System Preferences > Security & Privacy.

### Application Compatibility

Some Electron apps may have limited compatibility. Native macOS applications generally work best.

### Memory Usage

Vimnav includes automatic cleanup and memory pooling. If you experience issues, restart Hammerspoon.

## Technical Details

### Architecture

- **Coroutine-based traversal** — Non-blocking element discovery
- **Spatial indexing** — Viewport-aware element filtering
- **Object pooling** — Memory-efficient mark rendering
- **Caching layers** — Optimized accessibility queries

### Accessibility Integration

Uses macOS Accessibility APIs (AXUIElement) for universal application support. Elements are detected by role-based matching with configurable role lists.

### Performance Optimizations

- Viewport culling eliminates off-screen elements
- Attribute caching reduces redundant API calls
- Background processing prevents UI blocking
- Memory pools minimize garbage collection

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details.

## Acknowledgments

Based on the original [Vifari](https://github.com/dzirtusss/vifari) project with extensive modifications for system-wide support and performance improvements.
