local M = {}

---@class Hs.Vimnav.Config
---@field logLevel? string Log level to show in the console
---@field hints? Hs.Vimnav.Config.Hints Settings for hints
---@field focus? Hs.Vimnav.Config.Focus Focus settings
---@field mapping? Hs.Vimnav.Config.Mapping Mappings to use
---@field scroll? Hs.Vimnav.Config.Scroll Scroll settings
---@field axRoles? Hs.Vimnav.Config.AxRoles Roles to use for AXUIElement
---@field applicationGroups? Hs.Vimnav.Config.ApplicationGroups App groups to work with vimnav
---@field menubar? Hs.Vimnav.Config.Menubar Configure menubar indicator
---@field overlay? Hs.Vimnav.Config.Overlay Configure overlay indicator
---@field leader? Hs.Vimnav.Config.Leader Configure leader key
---@field whichkey? Hs.Vimnav.Config.Whichkey Configure which-key popup
---@field enhancedAccessibility? Hs.Vimnav.Config.EnhancedAccessibility Configure enhanced accessibility

---@class Hs.Vimnav.Config.EnhancedAccessibility
---@field enableForChromium? boolean Enable enhanced accessibility for Chromium (This sets AXEnhancedUserInterface = true)
---@field chromiumApps? string[] Apps to enable enhanced accessibility for Chromium
---@field enableForElectron? boolean Enable enhanced accessibility for Electron (This sets AXManualAccessibility = true (preferred))
---@field electronApps? string[] Apps to enable enhanced accessibility for Electron

---@class Hs.Vimnav.Config.Whichkey
---@field enabled? boolean Enable which-key popup
---@field delay? number Delay in seconds before which-key popup shows
---@field fontSize? number Font size for which-key popup
---@field textFont? string Text font for which-key popup
---@field minRowsPerCol? number Minimum rows per column for which-key popup
---@field colors? Hs.Vimnav.Config.Whichkey.Colors Colors for which-key popup

---@class Hs.Vimnav.Config.Whichkey.Colors
---@field background? string Background color for which-key popup
---@field backgroundAlpha? number Background alpha for which-key popup
---@field border? string Border color for which-key popup
---@field borderWidth? number Border width for which-key popup
---@field description? string Color of description text for which-key popup
---@field key? string Color of key text for which-key popup
---@field separator? string Color of separator text for which-key popup

---@class Hs.Vimnav.Config.Focus
---@field checkInterval? number Focus check interval in seconds (e.g. 0.5 for 500ms)

---@class Hs.Vimnav.Config.Leader
---@field key? string Leader key

---@class Hs.Vimnav.Config.ApplicationGroups
---@field exclusions? string[] Apps to exclude from Vimnav (e.g. Terminal)
---@field browsers? string[] Browsers to to detect for browser specific actions (e.g. Safari)
---@field launchers? string[] Launchers to to detect for launcher specific actions (e.g. Spotlight)

---@class Hs.Vimnav.Config.AxRoles
---@field editable? string[] Roles for detect editable inputs
---@field jumpable? string[] Roles for detect jumpable inputs (links and more)

---@class Hs.Vimnav.Config.Hints
---@field chars? string Link hint characters
---@field fontSize? number Font size for link hints
---@field textFont? string Text font for hints
---@field depth? number Maximum depth to search for elements
---@field colors? Hs.Vimnav.Config.Hints.Colors Colors for link hints

---@class Hs.Vimnav.Config.Hints.Colors
---@field from? string BG gradient `from` color for hints
---@field to? string BG gradient `to` color for hints
---@field angle? number Angle for gradient
---@field border? string Border color for hints
---@field borderWidth? number Border width for hints
---@field textColor? string Text color for hints

---@class Hs.Vimnav.Config.Scroll
---@field scrollStep? number Scroll step in pixels
---@field scrollStepHalfPage? number Scroll step in pixels for half page
---@field scrollStepFullPage? number Scroll step in pixels for full page
---@field smoothScroll? boolean Enable/disable smooth scrolling
---@field smoothScrollFramerate? number Smooth scroll framerate in frames per second

---@class Hs.Vimnav.Config.Menubar
---@field enabled? boolean Enable menubar indicator

---@class Hs.Vimnav.Config.Overlay
---@field enabled? boolean Enable overlay mode indicator
---@field position? "top-left"|"top-center"|"top-right"|"bottom-left"|"bottom-center"|"bottom-right"|"left-top"|"left-center"|"left-bottom"|"right-top"|"right-center"|"right-bottom" Position of overlay indicator
---@field size? number Size of overlay indicator in pixels
---@field padding? number Padding of overlay indicator in pixels from the screen frame
---@field colors? Hs.Vimnav.Config.Overlay.Colors Colors of overlay indicator
---@field textFont? string Text font for overlay indicator

---@class Hs.Vimnav.Config.Overlay.Colors
---@field disabled? string Color of disabled mode indicator
---@field normal? string Color of normal mode indicator
---@field insert? string Color of insert mode indicator
---@field insertNormal? string Color of insert normal mode indicator
---@field insertVisual? string Color of insert visual mode indicator
---@field links? string Color of links mode indicator
---@field passthrough? string Color of passthrough mode indicator
---@field visual? string Color of visual mode indicator

---@class Hs.Vimnav.Config.Mapping
---@field normal? table<string, string|table|function|"noop"> Normal mode mappings
---@field visual? table<string, string|table|function|"noop"> Visual mode mappings
---@field insertNormal? table<string, string|table|function|"noop"> Insert normal mode mappings
---@field insertVisual? table<string, string|table|function|"noop"> Insert visual mode mappings

---@class Hs.Vimnav.Config.Mapping.Keyset
---@field description string Description of the keyset
---@field action string|table|function|"noop"

---@class Hs.Vimnav.State
---@field mode number Vimnav mode
---@field keyCapture string|nil Multi character input
---@field marks table<number, table<string, table|nil>> Marks
---@field linkCapture string Link capture state
---@field lastEscape number Last escape key press time
---@field mappingPrefixes Hs.Vimnav.State.MappingPrefixes Mapping prefixes
---@field allCombinations string[] All combinations
---@field markCanvas table|nil Canvas
---@field onClickCallback fun(any)|nil On click callback for marks
---@field cleanupTimer table|nil Cleanup timer
---@field focusCachedResult boolean Focus cached result
---@field focusLastElement table|string|nil Focus last element
---@field maxElements number Maximum elements to search for (derived from config)
---@field leaderPressed boolean Leader key was pressed
---@field leaderCapture string Captured keys after leader
---@field whichkeyTimer table|nil Which-key popup timer
---@field whichkeyCanvas table|nil Which-key popup canvas
---@field showingHelp boolean Whether the help popup is currently showing
---@field focusCheckTimer table|nil Focus check timer
---@field menubarItem table|nil Menubar item
---@field overlayCanvas table|nil Overlay canvas

---@class Hs.Vimnav.State.MappingPrefixes
---@field normal table<string, boolean> Normal mode mappings
---@field visual table<string, boolean> Visual mode mappings
---@field insertNormal table<string, boolean> Insert normal mode mappings
---@field insertVisual table<string, boolean> Insert visual mode mappings

---@class Hs.Vimnav.Elements.IsInViewportOpts
---@field fx number
---@field fy number
---@field fw number
---@field fh number
---@field viewport table

---@class Hs.Vimnav.Async.TraversalOpts
---@field matcher fun(element: table): boolean
---@field callback fun(results: table)
---@field maxResults number

---@class Hs.Vimnav.Async.WalkElementOpts
---@field depth number
---@field matcher fun(element: table): boolean
---@field callback fun(element: table): boolean
---@field viewport table

---@class Hs.Vimnav.Marks.ShowOpts
---@field withUrls? boolean
---@field elementType "link"|"input"|"image"

---@class Hs.Vimnav.Elements.FindElementsOpts
---@field callback fun(elements: table)

---@class Hs.Vimnav.Elements.FindClickableElementsOpts: Hs.Vimnav.Elements.FindElementsOpts
---@field withUrls boolean

---@class Hs.Vimnav.Actions.SmoothScrollOpts
---@field x? number|nil
---@field y? number|nil
---@field smooth? boolean

---@class Hs.Vimnav.Actions.TryClickOpts
---@field type? string "left"|"right"
---@field doubleClick? boolean

---@class Hs.Vimnav.EventHandler.HandleVimInputOpts
---@field modifiers? table

---@alias Hs.Vimnav.Element table|string

---@alias Hs.Vimnav.Modifier "cmd"|"ctrl"|"alt"|"shift"|"fn"

return M
