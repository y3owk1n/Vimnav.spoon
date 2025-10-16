---@diagnostic disable: undefined-global
local M = {}

M.currentElement = nil
M.selectedTextRange = {}
M.visibleTextRange = {}
M.fullText = ""
M._isStarted = false
M._visualAnchor = nil

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

function M:clear()
	self.currentElement = nil
	self.selectedTextRange = {}
	self.visibleTextRange = {}
	self.fullText = ""
	self._isStarted = false

	self:exitVisualMode()
end

function M:getCurrentElement()
	return self.currentElement
end

function M:getSelectedTextRange()
	return self.selectedTextRange
end

function M:getVisibleTextRange()
	return self.visibleTextRange
end

function M:getCursorPosition()
	return self.selectedTextRange.location or 0
end

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

-- Helper function to find character in text
local function findChar(text, startPos, char, forward)
	if forward then
		local pos = text:find(char, startPos + 1, true)
		return pos
	else
		for i = startPos - 1, 1, -1 do
			if text:sub(i, i) == char then
				return i
			end
		end
		return nil
	end
end

-- Helper function to check if character is a word character
local function isWordChar(char)
	return char:match("[%w_]") ~= nil
end

-- Helper function to find next word boundary
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

-- Helper function to find previous word boundary
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

-- Vim movement: w (next word)
function M:moveWordForward()
	local pos = self:getCursorPosition()
	local newPos = findNextWord(self.fullText, pos + 1)
	return self:setCursorPosition(newPos - 1)
end

-- Vim movement: b (previous word)
function M:moveWordBackward()
	local pos = self:getCursorPosition()
	local newPos = findPrevWord(self.fullText, pos + 1)
	return self:setCursorPosition(newPos - 1)
end

-- Vim movement: e (end of word)
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

-- Vim movement: 0 (start of line)
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

-- Vim movement: $ (end of line)
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

-- Vim movement: ^ (first non-blank character)
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

-- Vim movement: j (down)
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

-- Vim movement: k (up)
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

-- Vim movement: f{char} (find character forward)
function M:findCharForward(char)
	local pos = self:getCursorPosition()
	local found = findChar(self.fullText, pos + 1, char, true)
	if found then
		return self:setCursorPosition(found - 1)
	end
	return false
end

-- Vim movement: F{char} (find character backward)
function M:findCharBackward(char)
	local pos = self:getCursorPosition()
	local found = findChar(self.fullText, pos + 1, char, false)
	if found then
		return self:setCursorPosition(found - 1)
	end
	return false
end

-- Vim movement: gg (start of document)
function M:moveDocStart()
	return self:setCursorPosition(0)
end

-- Vim movement: G (end of document)
function M:moveDocEnd()
	return self:setCursorPosition(#self.fullText)
end

-- Text object: iw (inner word)
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

-- Text object: aw (a word, including whitespace)
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

-- Text object helper: find matching brackets
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

-- Text object: i( or i) or ib (inner parentheses)
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

-- Text object: a( or a) or ab (around parentheses)
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

-- Text object: i{ or i} or iB (inner braces)
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

-- Text object: a{ or a} or aB (around braces)
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

-- Text object: i[ or i] (inner brackets)
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

-- Text object: a[ or a] (around brackets)
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

-- Text object: i" or i' or i` (inner quotes)
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

-- Text object: a" or a' or a` (around quotes)
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

-- Helper function to get current line boundaries
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

function M:startVisualMode()
	self._visualAnchor = self:getCursorPosition()
	return true
end

function M:exitVisualMode()
	if self._visualAnchor then
		self:setCursorPosition(self._visualAnchor)
	end
	self._visualAnchor = nil
	return true
end

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

-- Visual mode movements (these extend selection instead of moving cursor)
function M:visualMoveRight()
	return self:extendSelection(1)
end

function M:visualMoveLeft()
	return self:extendSelection(-1)
end

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
end

function M:visualMoveDocStart()
	local ok = self:moveDocStart()
	local anchor = self._visualAnchor
	self:setSelection(0, anchor)

	return ok
end

function M:visualMoveDocEnd()
	local docEnd = #self.fullText
	local anchor = self._visualAnchor
	return self:setSelection(anchor, docEnd - anchor)
end

return M
