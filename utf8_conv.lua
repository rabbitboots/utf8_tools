-- Supplementary encoding functions for utf8Tools.
-- https://github.com/rabbitboots/utf8_tools


--[[
MIT License

Copyright (c) 2022 - 2024 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local utf8Conv = {}


local utf8Tools = require(REQ_PATH .. "utf8_tools")


local _assertArgType = utf8Tools._assertArgType


function utf8Conv.latin1_utf8(str)

	_assertArgType(1, str, "string")

	local temp = {}

	for i = 1, #str do
		temp[#temp + 1] = utf8Tools.codePointToUCString(string.byte(str:sub(i, i)))
	end

	local ret = table.concat(temp)
	return ret
end


function utf8Conv.utf8_latin1(str, unmappable)

	_assertArgType(1, str, "string")
	-- don't assert `unmappable`

	local temp = {}

	local i = 1
	while i <= #str do
		local code, err = utf8Tools.ucStringToCodePoint(str, i)
		if not code then
			return nil, i, err

		elseif code >= 255 then
			if type(unmappable) == "string" then
				temp[#temp + 1] = unmappable

			else
				return nil, i, "unsupported code point."
			end

		else
			temp[#temp + 1] = string.char(code)
		end
		i = utf8Tools.step(str, i + 1)
	end

	local ret = table.concat(temp)
	return ret
end


local function combine16Bit(str, i, big_endian)

	local b1, b2 = string.byte(str, i), string.byte(str, i + 1)

	if big_endian then
		b1 = b1 * 0x100

	else
		b2 = b2 * 0x100
	end

	return b1 + b2
end


function utf8Conv.utf16_utf8(str, big_endian)

	_assertArgType(1, str, "string")

	local temp = {}

	local i = 1
	while i <= #str do

		if i > #str - 1 then
			return nil, i, "not enough space to decode a 16-bit value."
		end

		local w1 = combine16Bit(str, i, big_endian)

		if w1 < 0xd800 or w1 > 0xdfff then
			temp[#temp + 1] = utf8Tools.codePointToUCString(w1)
			i = i + 2

		elseif w1 > 0xdbff then
			return nil, i, "first 16-byte value is out of range."

		else
			i = i + 2
			if i > #str - 1 then
				return nil, i, "not enough space to decode a second 16-bit value."
			end

			local w2 = combine16Bit(str, i, big_endian)

			if w2 < 0xdc00 and w2 > 0xdfff then
				return nil, i, "second 16-byte value is out of range."
			end

			local value = ((w1 % 0x400) * 0x400) + (w2 % 0x400) + 0x10000
			temp[#temp + 1] = utf8Tools.codePointToUCString(value)
			i = i + 2
		end
	end

	local ret = table.concat(temp)
	return ret
end


local function split16Bit(v, big_endian)

	if big_endian then
		return math.floor(v / 0x100), v % 0x100

	else
		return v % 0x100, math.floor(v / 0x100)
	end
end


function utf8Conv.utf8_utf16(str, big_endian)

	_assertArgType(1, str, "string")

	local temp = {}

	local i = 1
	while i <= #str do
		local c, err = utf8Tools.ucStringToCodePoint(str, i)
		if not c then
			return nil, i, "UTF-8 decoding error: " .. err
		end

		local  v1, v2
		if c < 0x10000 then
			v1, v2 = split16Bit(c, big_endian)
			temp[#temp + 1] = string.char(v1, v2)

		else
			c = c - 0x10000
			local w1 = 0xd800 + math.floor(c / 0x400)
			local w2 = 0xdc00 + (c % 0x400)

			v1, v2 = split16Bit(w1, big_endian)
			temp[#temp + 1] = string.char(v1, v2)

			v1, v2 = split16Bit(w2, big_endian)
			temp[#temp + 1] = string.char(v1, v2)
		end

		i = utf8Tools.step(str, i + 1)
	end

	local ret = table.concat(temp)
	return ret
end


return utf8Conv
