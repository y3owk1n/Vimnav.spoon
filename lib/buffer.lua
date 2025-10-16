---@diagnostic disable: undefined-global
local M = {}

---Tracks the current element
---@type string|table|nil
M.currentElement = nil

---Tracks the selected text range
---@type Hs.Vimnav.Buffer.SelectedTextRange
M.selectedTextRange = {}

---Tracks the visible text range
---@type Hs.Vimnav.Buffer.SelectedTextRange
M.visibleTextRange = {}

---Tracks the full text
---@type string
M.fullText = ""

---Tracks if the buffer is started
---@type boolean
M._isStarted = false

---Tracks the visual anchor
---@type number
M._visualAnchor = nil

---Creates a new buffer
---@return nil
function M:new()
	if self._isStarted then
		return
	end

	self.currentElement = require("lib.elements").getAxFocusedElement()
	if not self.currentElement then
		return
	end

	self.selectedTextRange = self.currentElement:attributeValue(
		"AXSelectedTextRange"
	) or {}
	self.visibleTextRange = self.currentElement:attributeValue(
		"AXVisibleCharacterRange"
	) or {}

	-- Get full text content for text object operations
	self.fullText = self.currentElement:attributeValue("AXValue") or ""

	self._isStarted = true
end

---Clears the buffer
---@return nil
function M:clear()
	self:exitVisualMode()

	self.currentElement = nil
	self.selectedTextRange = {}
	self.visibleTextRange = {}
	self.fullText = ""
	self._isStarted = false
end

---Start visual mode
---@return boolean success
function M:startVisualMode()
	self._visualAnchor = self:getCursorPosition()
	return true
end

---Exit visual mode
---@return boolean success
function M:exitVisualMode()
	if self._visualAnchor then
		self:setCursorPosition(self._visualAnchor)
	end
	self._visualAnchor = nil
	return true
end

---Returns the current element
---@return string|table|nil
function M:getCurrentElement()
	return self.currentElement
end

---Returns the selected text range
---@return Hs.Vimnav.Buffer.SelectedTextRange
function M:getSelectedTextRange()
	return self.selectedTextRange
end

---Returns the visible text range
---@return Hs.Vimnav.Buffer.SelectedTextRange
function M:getVisibleTextRange()
	return self.visibleTextRange
end

---Returns the cursor position
---@return number
function M:getCursorPosition()
	return self.selectedTextRange.location or 0
end

---Sets the cursor position
---@param position number Position to set
---@return boolean success
function M:setCursorPosition(position)
	if not self.currentElement then
		return false
	end

	if not self.currentElement:isAttributeSettable("AXSelectedTextRange") then
		return false
	end

	-- Clamp position to valid range
	local maxPos = #self.fullText
	position = math.max(0, math.min(position, maxPos))

	self.selectedTextRange = { location = position, length = 0 }
	self.currentElement:setAttributeValue(
		"AXSelectedTextRange",
		self.selectedTextRange
	)
	return true
end

---Sets the selection
---@param startPos number Start position
---@param length number Length
---@return boolean success
function M:setSelection(startPos, length)
	if not self.currentElement then
		return false
	end

	if not self.currentElement:isAttributeSettable("AXSelectedTextRange") then
		return false
	end

	-- Clamp to valid range
	local maxPos = #self.fullText
	startPos = math.max(0, math.min(startPos, maxPos))
	length = math.max(0, math.min(length, maxPos - startPos))

	self.selectedTextRange = { location = startPos, length = length }
	self.currentElement:setAttributeValue(
		"AXSelectedTextRange",
		self.selectedTextRange
	)
	return true
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

---Helper function to check if character is a word character
---@param char string Character to check
---@return boolean
local function isWordChar(char)
	return char:match("[%w_]") ~= nil
end

---Helper function to find next word boundary
---@param text string Text to search in
---@param pos number Start position
---@return number|nil Position of the next word boundary or nil if not found
local function findNextWord(text, pos)
	local len = #text
	if pos > len then
		return len
	end

	local char = text:sub(pos, pos)

	-- If we're on whitespace, skip it first
	if char:match("%s") then
		while pos <= len and text:sub(pos, pos):match("%s") do
			pos = pos + 1
		end
		return pos
	end

	-- If we're on a word character, skip to end of word
	if isWordChar(char) then
		while pos <= len and isWordChar(text:sub(pos, pos)) do
			pos = pos + 1
		end
	else
		-- We're on punctuation, skip it
		while
			pos <= len
			and not isWordChar(text:sub(pos, pos))
			and not text:sub(pos, pos):match("%s")
		do
			pos = pos + 1
		end
	end

	-- Skip any whitespace after
	while pos <= len and text:sub(pos, pos):match("%s") do
		pos = pos + 1
	end

	return pos
end

---Helper function to find previous word boundary
---@param text string Text to search in
---@param pos number Start position
---@return number|nil Position of the previous word boundary or nil if not found
local function findPrevWord(text, pos)
	if pos <= 1 then
		return 1
	end

	pos = pos - 1

	-- Skip whitespace
	while pos > 1 and text:sub(pos, pos):match("%s") do
		pos = pos - 1
	end

	-- Skip to start of word
	while pos > 1 and isWordChar(text:sub(pos - 1, pos - 1)) do
		pos = pos - 1
	end

	return pos
end

---Helper function to find matching brackets
---@param text string Text to search in
---@param startPos number Start position
---@param openChar string Opening character
---@param closeChar string Closing character
---@return number|nil Position of the matching bracket or nil if not found
local function findMatchingBracket(text, startPos, openChar, closeChar)
	local depth = 0
	local len = #text

	for i = startPos, len do
		local char = text:sub(i, i)
		if char == openChar then
			depth = depth + 1
		elseif char == closeChar then
			depth = depth - 1
			if depth == 0 then
				return i
			end
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- Normal Movements
--------------------------------------------------------------------------------

---@param steps number can be negative or positive
---@return boolean success
function M:moveCursorX(steps)
	if not self.currentElement then
		return false
	end

	local pos = self:getCursorPosition()
	local newPos = pos + steps

	-- Don't allow moving cursor past boundaries
	if newPos < 0 or newPos > #self.fullText then
		return false
	end

	return self:setCursorPosition(newPos)
end

---Move to the next word
---@return boolean success
function M:moveWordForward()
	local pos = self:getCursorPosition()
	local newPos = findNextWord(self.fullText, pos + 1)
	return self:setCursorPosition(newPos - 1)
end

---Move to the previous word
---@return boolean success
function M:moveWordBackward()
	local pos = self:getCursorPosition()
	local newPos = findPrevWord(self.fullText, pos + 1)
	return self:setCursorPosition(newPos - 1)
end

---Move to the end of the word
---@return boolean success
function M:moveWordEnd()
	local pos = self:getCursorPosition()
	local text = self.fullText
	local len = #text

	-- Convert from 0-based to 1-based for Lua string operations
	pos = pos + 1

	-- Move forward one character to start
	pos = pos + 1
	if pos > len then
		return self:setCursorPosition(len)
	end

	-- Skip whitespace
	while pos <= len and text:sub(pos, pos):match("%s") do
		pos = pos + 1
	end

	if pos > len then
		return self:setCursorPosition(len)
	end

	-- Now find end of word
	local char = text:sub(pos, pos)
	if isWordChar(char) then
		while pos < len and isWordChar(text:sub(pos + 1, pos + 1)) do
			pos = pos + 1
		end
	else
		-- Punctuation
		while
			pos < len
			and not isWordChar(text:sub(pos + 1, pos + 1))
			and not text:sub(pos + 1, pos + 1):match("%s")
		do
			pos = pos + 1
		end
	end

	-- Convert back to 0-based - we're now at the last char of the word
	return self:setCursorPosition(pos)
end

---Move to the start of the line
---@return boolean success
function M:moveLineStart()
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find previous newline
	local lineStart = 0
	for i = pos, 1, -1 do
		if text:sub(i, i) == "\n" then
			lineStart = i
			break
		end
	end

	return self:setCursorPosition(lineStart)
end

---Move to the end of the line
---@return boolean success
function M:moveLineEnd()
	local pos = self:getCursorPosition()
	local text = self.fullText
	local len = #text

	-- Find next newline
	local lineEnd = len
	for i = pos + 1, len do
		if text:sub(i, i) == "\n" then
			lineEnd = i - 1
			break
		end
	end

	return self:setCursorPosition(lineEnd)
end

---Move to the first non-blank character of the line
---@return boolean success
function M:moveLineFirstNonBlank()
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find start of line
	local lineStart = 0
	for i = pos, 1, -1 do
		if text:sub(i, i) == "\n" then
			lineStart = i
			break
		end
	end

	-- Find first non-blank
	local firstNonBlank = lineStart
	for i = lineStart + 1, #text do
		local char = text:sub(i, i)
		if char == "\n" then
			break
		elseif not char:match("%s") then
			firstNonBlank = i - 1
			break
		end
	end

	return self:setCursorPosition(firstNonBlank)
end

---Move down one line
---@return boolean success
function M:moveLineDown()
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find current line start
	local lineStart = 0
	for i = pos, 1, -1 do
		if text:sub(i, i) == "\n" then
			lineStart = i
			break
		end
	end

	local columnOffset = pos - lineStart

	-- Find current line end (next newline)
	local nextLineStart = #text
	for i = pos + 1, #text do
		if text:sub(i, i) == "\n" then
			nextLineStart = i
			break
		end
	end

	-- Find end of next line
	local nextLineEnd = #text
	for i = nextLineStart + 1, #text do
		if text:sub(i, i) == "\n" then
			nextLineEnd = i - 1
			break
		end
	end

	-- Try to maintain column position
	local newPos = math.min(nextLineStart + columnOffset, nextLineEnd)
	return self:setCursorPosition(newPos)
end

---Move up one line
---@return boolean success
function M:moveLineUp()
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find current line start
	local lineStart = 0
	for i = pos, 1, -1 do
		if text:sub(i, i) == "\n" then
			lineStart = i
			break
		end
	end

	if lineStart == 0 then
		return false -- Already at first line
	end

	local columnOffset = pos - lineStart

	-- Find previous line start
	local prevLineStart = 0
	for i = lineStart - 1, 1, -1 do
		if text:sub(i, i) == "\n" then
			prevLineStart = i
			break
		end
	end

	-- Try to maintain column position
	local newPos = math.min(prevLineStart + columnOffset, lineStart - 1)
	return self:setCursorPosition(newPos)
end

---Move to the start of the document
---@return boolean success
function M:moveDocStart()
	return self:setCursorPosition(0)
end

---Move to the end of the document
---@return boolean success
function M:moveDocEnd()
	return self:setCursorPosition(#self.fullText)
end

--------------------------------------------------------------------------------
-- Text Objects
--------------------------------------------------------------------------------

---Select the inner word (`iw`)
---@return boolean success
function M:selectInnerWord()
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find word boundaries
	local wordStart = pos
	while wordStart > 0 and isWordChar(text:sub(wordStart, wordStart)) do
		wordStart = wordStart - 1
	end
	if not isWordChar(text:sub(wordStart + 1, wordStart + 1)) then
		wordStart = wordStart + 1
	end

	local wordEnd = pos + 1
	while wordEnd <= #text and isWordChar(text:sub(wordEnd, wordEnd)) do
		wordEnd = wordEnd + 1
	end

	local length = wordEnd - wordStart - 1
	return self:setSelection(wordStart, length)
end

---Select the word (`aw`)
---@return boolean success
function M:selectAroundWord()
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find word boundaries
	local wordStart = pos
	while wordStart > 0 and isWordChar(text:sub(wordStart, wordStart)) do
		wordStart = wordStart - 1
	end
	if not isWordChar(text:sub(wordStart + 1, wordStart + 1)) then
		wordStart = wordStart + 1
	end

	local wordEnd = pos + 1
	while wordEnd <= #text and isWordChar(text:sub(wordEnd, wordEnd)) do
		wordEnd = wordEnd + 1
	end

	-- Include trailing whitespace
	while wordEnd <= #text and text:sub(wordEnd, wordEnd):match("%s") do
		wordEnd = wordEnd + 1
	end

	local length = wordEnd - wordStart - 1
	return self:setSelection(wordStart, length)
end

---Select the inner parentheses (`i(` or `i)`)
---@return boolean success
function M:selectInnerParens()
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find opening paren before cursor
	local openPos = nil
	for i = pos, 1, -1 do
		if text:sub(i, i) == "(" then
			openPos = i
			break
		end
	end

	if not openPos then
		return false
	end

	-- Find matching closing paren
	local closePos = findMatchingBracket(text, openPos + 1, "(", ")")
	if not closePos then
		return false
	end

	return self:setSelection(openPos, closePos - openPos - 1)
end

---Select the parentheses (`a(` or `a)`)
---@return boolean success
function M:selectAroundParens()
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find opening paren before cursor
	local openPos = nil
	for i = pos, 1, -1 do
		if text:sub(i, i) == "(" then
			openPos = i
			break
		end
	end

	if not openPos then
		return false
	end

	-- Find matching closing paren
	local closePos = findMatchingBracket(text, openPos + 1, "(", ")")
	if not closePos then
		return false
	end

	return self:setSelection(openPos - 1, closePos - openPos + 1)
end

---Select the braces (`i{` or `i}`)
---@return boolean success
function M:selectInnerBraces()
	local pos = self:getCursorPosition()
	local text = self.fullText

	local openPos = nil
	for i = pos, 1, -1 do
		if text:sub(i, i) == "{" then
			openPos = i
			break
		end
	end

	if not openPos then
		return false
	end

	local closePos = findMatchingBracket(text, openPos + 1, "{", "}")
	if not closePos then
		return false
	end

	return self:setSelection(openPos, closePos - openPos - 1)
end

---Select the braces (`a{` or `a}`)
---@return boolean success
function M:selectAroundBraces()
	local pos = self:getCursorPosition()
	local text = self.fullText

	local openPos = nil
	for i = pos, 1, -1 do
		if text:sub(i, i) == "{" then
			openPos = i
			break
		end
	end

	if not openPos then
		return false
	end

	local closePos = findMatchingBracket(text, openPos + 1, "{", "}")
	if not closePos then
		return false
	end

	return self:setSelection(openPos - 1, closePos - openPos + 1)
end

---Select the brackets (`i[` or `i]`)
---@return boolean success
function M:selectInnerBrackets()
	local pos = self:getCursorPosition()
	local text = self.fullText

	local openPos = nil
	for i = pos, 1, -1 do
		if text:sub(i, i) == "[" then
			openPos = i
			break
		end
	end

	if not openPos then
		return false
	end

	local closePos = findMatchingBracket(text, openPos + 1, "[", "]")
	if not closePos then
		return false
	end

	return self:setSelection(openPos, closePos - openPos - 1)
end

---Select the brackets (`a[` or `a]`)
---@return boolean success
function M:selectAroundBrackets()
	local pos = self:getCursorPosition()
	local text = self.fullText

	local openPos = nil
	for i = pos, 1, -1 do
		if text:sub(i, i) == "[" then
			openPos = i
			break
		end
	end

	if not openPos then
		return false
	end

	local closePos = findMatchingBracket(text, openPos + 1, "[", "]")
	if not closePos then
		return false
	end

	return self:setSelection(openPos - 1, closePos - openPos + 1)
end

---Select the quotes (`i"` or `i'`)
---@param quoteChar string Quote character
---@return boolean success
function M:selectInnerQuotes(quoteChar)
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find opening quote before cursor
	local openPos = nil
	for i = pos, 1, -1 do
		if text:sub(i, i) == quoteChar then
			openPos = i
			break
		end
	end

	if not openPos then
		return false
	end

	-- Find closing quote
	local closePos = nil
	for i = openPos + 1, #text do
		if text:sub(i, i) == quoteChar then
			closePos = i
			break
		end
	end

	if not closePos then
		return false
	end

	return self:setSelection(openPos, closePos - openPos - 1)
end

---Select the quotes (`a"` or `a'`)
---@param quoteChar string Quote character
---@return boolean success
function M:selectAroundQuotes(quoteChar)
	local pos = self:getCursorPosition()
	local text = self.fullText

	-- Find opening quote before cursor
	local openPos = nil
	for i = pos, 1, -1 do
		if text:sub(i, i) == quoteChar then
			openPos = i
			break
		end
	end

	if not openPos then
		return false
	end

	-- Find closing quote
	local closePos = nil
	for i = openPos + 1, #text do
		if text:sub(i, i) == quoteChar then
			closePos = i
			break
		end
	end

	if not closePos then
		return false
	end

	return self:setSelection(openPos - 1, closePos - openPos + 1)
end

--------------------------------------------------------------------------------
-- Lines
--------------------------------------------------------------------------------

---Get the current line boundaries
---@return number startPos
---@return number endPos
function M:getCurrentLineBounds()
	local pos = self:getCursorPosition()
	local text = self.fullText
	local len = #text

	-- Find start of current line
	local lineStart = 0
	for i = pos, 1, -1 do
		if text:sub(i, i) == "\n" then
			lineStart = i
			break
		end
	end

	-- Find end of current line
	local lineEnd = len
	for i = pos + 1, len do
		if text:sub(i, i) == "\n" then
			lineEnd = i - 1
			break
		end
	end

	return lineStart, lineEnd
end

--------------------------------------------------------------------------------
-- Selections
--------------------------------------------------------------------------------

---Select the current line
---@return boolean success
function M:selectLine()
	if not self.currentElement then
		return false
	end

	local lineStart, lineEnd = self:getCurrentLineBounds()
	local text = self.fullText

	-- Skip leading whitespace
	local contentStart = lineStart
	while
		contentStart < lineEnd
		and text:sub(contentStart + 1, contentStart + 1):match("%s")
	do
		contentStart = contentStart + 1
	end

	-- Skip trailing whitespace
	local contentEnd = lineEnd
	while
		contentEnd > contentStart
		and text:sub(contentEnd, contentEnd):match("%s")
	do
		contentEnd = contentEnd - 1
	end

	-- Select the line content without whitespace
	return self:setSelection(contentStart, contentEnd - contentStart + 1)
end

---Extend the selection left or right
---@param steps number can be negative or positive
function M:extendSelection(steps)
	if not self.currentElement then
		return false
	end
	if not self.currentElement:isAttributeSettable("AXSelectedTextRange") then
		return false
	end

	local cur = self:getSelectedTextRange()

	-- If no anchor is set, use current position as anchor
	if not self._visualAnchor then
		self._visualAnchor = cur.location or self:getCursorPosition()
	end

	local anchor = self._visualAnchor
	local currentPos = cur.location or self:getCursorPosition()
	local currentLength = cur.length or 0

	-- Determine which end of selection is the cursor
	-- If selection start is the anchor, cursor is at end
	-- If selection start is not the anchor, cursor is at start
	local cursorPos
	if currentLength == 0 then
		cursorPos = currentPos
	elseif currentPos == anchor then
		-- Anchor is at start, cursor is at end
		cursorPos = currentPos + currentLength
	else
		-- Anchor is at end, cursor is at start
		cursorPos = currentPos
	end

	-- Move the cursor
	local newCursorPos = cursorPos + steps

	-- Clamp to valid range
	local maxPos = #self.fullText
	newCursorPos = math.max(0, math.min(newCursorPos, maxPos))

	-- Calculate new selection from anchor to new cursor position
	local startPos, length
	if newCursorPos > anchor then
		-- Selection extends forward from anchor
		startPos = anchor
		length = newCursorPos - anchor
	elseif newCursorPos < anchor then
		-- Selection extends backward from anchor
		startPos = newCursorPos
		length = anchor - newCursorPos
	else
		-- Cursor is at anchor (no selection)
		startPos = anchor
		length = 0
	end

	-- Set the selection
	self.selectedTextRange.location = startPos
	self.selectedTextRange.length = length
	self.currentElement:setAttributeValue(
		"AXSelectedTextRange",
		self.selectedTextRange
	)

	return true
end

--------------------------------------------------------------------------------
-- Visual Movements
--------------------------------------------------------------------------------

---Extend the selection right
---@return boolean success
function M:visualMoveRight()
	return self:extendSelection(1)
end

---Extend the selection left
---@return boolean success
function M:visualMoveLeft()
	return self:extendSelection(-1)
end

---Extend the selection to the next word
---@return boolean success
function M:visualMoveWordForward()
	local cur = self:getSelectedTextRange()
	local currentPos = cur.location or self:getCursorPosition()
	local currentLength = cur.length or 0

	-- Determine cursor position
	local cursorPos
	if currentLength == 0 then
		cursorPos = currentPos
	elseif currentPos == self._visualAnchor then
		-- Anchor is at start, cursor is at end
		cursorPos = currentPos + currentLength
	else
		-- Anchor is at end, cursor is at start
		cursorPos = currentPos
	end

	-- Find next word position
	local newPos = findNextWord(self.fullText, cursorPos + 1) - 1
	local steps = newPos - cursorPos

	return self:extendSelection(steps)
end

---Extend the selection to the previous word
---@return boolean success
function M:visualMoveWordBackward()
	local cur = self:getSelectedTextRange()
	local currentPos = cur.location or self:getCursorPosition()
	local currentLength = cur.length or 0

	-- Determine cursor position
	local cursorPos
	if currentLength == 0 then
		cursorPos = currentPos
	elseif currentPos == self._visualAnchor then
		-- Anchor is at start, cursor is at end
		cursorPos = currentPos + currentLength
	else
		-- Anchor is at end, cursor is at start
		cursorPos = currentPos
	end

	-- Find previous word position
	local newPos = findPrevWord(self.fullText, cursorPos + 1) - 1
	local steps = newPos - cursorPos

	return self:extendSelection(steps)
end

---Extend the selection down one line
---@return boolean success
function M:visualMoveLineDown()
	local text = self.fullText
	local cur = self:getSelectedTextRange()
	local currentPos = cur.location or self:getCursorPosition()
	local currentLength = cur.length or 0

	-- Determine cursor position
	local cursorPos
	if currentLength == 0 then
		cursorPos = currentPos
	elseif currentPos == self._visualAnchor then
		cursorPos = currentPos + currentLength
	else
		cursorPos = currentPos
	end

	-- Find next newline
	local steps = 0
	for i = cursorPos + 2, #text + 1 do
		steps = steps + 1
		if i > #text or text:sub(i, i) == "\n" then
			break
		end
	end

	return self:extendSelection(steps)
end

---Extend the selection up one line
---@return boolean success
function M:visualMoveLineUp()
	local text = self.fullText
	local cur = self:getSelectedTextRange()
	local currentPos = cur.location or self:getCursorPosition()
	local currentLength = cur.length or 0

	-- Determine cursor position
	local cursorPos
	if currentLength == 0 then
		cursorPos = currentPos
	elseif currentPos == self._visualAnchor then
		cursorPos = currentPos + currentLength
	else
		cursorPos = currentPos
	end

	-- Find previous newline
	local steps = 0
	for i = cursorPos, 1, -1 do
		steps = steps - 1
		if text:sub(i, i) == "\n" then
			break
		end
	end

	return self:extendSelection(steps)
end

---Extend the selection to the start of the line
---@return boolean success
function M:visualMoveLineStart()
	local lineStart = self:moveLineStart()
	if lineStart then
		-- After moving, extend selection from anchor
		local cur = self:getSelectedTextRange()
		local anchor = self._visualAnchor
		local newPos = cur.location or self:getCursorPosition()

		if newPos < anchor then
			return self:setSelection(newPos, anchor - newPos)
		else
			return self:setSelection(anchor, newPos - anchor)
		end
	end

	return false
end

---Extend the selection to the end of the line
---@return boolean success
function M:visualMoveLineEnd()
	local lineEnd = self:moveLineEnd()
	if lineEnd then
		-- After moving, extend selection from anchor
		local cur = self:getSelectedTextRange()
		local anchor = self._visualAnchor
		local newPos = cur.location or self:getCursorPosition()

		if newPos > anchor then
			return self:setSelection(anchor, newPos - anchor + 1)
		else
			return self:setSelection(newPos, anchor - newPos + 1)
		end
	end

	return false
end

---Extend the selection to the first non-blank character of the line
---@return boolean success
function M:visualMoveLineFirstNonBlank()
	local lineStart = self:moveLineFirstNonBlank()
	if lineStart then
		-- After moving, extend selection from anchor
		local cur = self:getSelectedTextRange()
		local anchor = self._visualAnchor
		local newPos = cur.location or self:getCursorPosition()

		if newPos < anchor then
			return self:setSelection(newPos, anchor - newPos)
		else
			return self:setSelection(anchor, newPos - anchor)
		end
	end

	return false
end

---Extend the selection to the start of the document
---@return boolean success
function M:visualMoveDocStart()
	local ok = self:moveDocStart()
	local anchor = self._visualAnchor
	self:setSelection(0, anchor)

	return ok
end

---Extend the selection to the end of the document
---@return boolean success
function M:visualMoveDocEnd()
	local docEnd = #self.fullText
	local anchor = self._visualAnchor
	return self:setSelection(anchor, docEnd - anchor)
end

return M
