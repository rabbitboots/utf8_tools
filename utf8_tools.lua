-- utf8Tools v1.2.3
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


local utf8Tools = {}


utf8Tools.options = {
	check_surrogates = true,
	exclude_invalid_octets = true,
}
local options = utf8Tools.options


utf8Tools.lang = {
	arg_bad_type = "argument #$1: bad type (expected $2, got $3)",
	arg_bad_int = "argument #$1: expected integer",
	arg_bad_int_range = "argument #$1: expected integer in range ($2-$3)",
	arg_expect_int = "argument #$1: expected integer",
	arg_empty_str = "argument #$1: string must contain at least one character",
	arg_start_end_oob = "start index is greater than end index",
	str_i_oob = "string index is out of bounds",
	invalid_b = "invalid octet value ($1) in byte #$2",
	err_surrogate = "UTF-8 prohibits values between 0xd800 and 0xdfff (surrogate range). Received: $1",
	cp_negative = "code point is negative",
	cp_too_big = "code point is too large",
	len_mismatch = "$1-octet length mismatch. Got: $2, must be in this range: $3 - $4",
	trailing_1st = "trailing octet (2nd, 3rd or 4th) receieved as 1st",
	len_unknown = "unable to determine octet length indicator in first byte of UTF-8 value",
	octet_nil = "octet #$1 is nil",
	octet_invalid_value = "invalid octet value ($1) in byte #$2",
	octet_too_low = "byte #$1 is too low ($2) for multi-byte encoding. Min: 0x80",
	octet_too_high = "byte #$1 is too high ($2) for multi-byte encoding. Max: 0xbf",
}
local lang = utf8Tools.lang


local interp -- v v01
do
	local v, c = {}, function(t) for k in pairs(t) do t[k] = nil end end
	interp = function(s, ...)
		c(v)
		for i = 1, select("#", ...) do
			v[tostring(i)] = select(i, ...)
		end
		local r = s:gsub("%$(%d+)", v):gsub("%$;", "$")
		c(v)
		return r
	end
end
utf8Tools._interp = interp


-- Octets 0xc0, 0xc1, and (0xf5 - 0xff) should never appear in a UTF-8 value.
utf8Tools.lut_invalid_octet = {}
for i, v in ipairs({0xc0, 0xc1, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff}) do
	utf8Tools.lut_invalid_octet[v] = true
end


-- Used to verify number length against allowed octet ranges (1, 2, 3, 4).
local lut_oct_min_max = {{0x00000, 0x00007f}, {0x00080, 0x0007ff}, {0x00800, 0x00ffff}, {0x10000, 0x10ffff}}


function utf8Tools._assertArgType(arg_n, var, expected)
	if type(var) ~= expected then
		error(interp(lang.arg_bad_type, arg_n, expected, type(var)), 2)
	end
end
local _assertArgType = utf8Tools._assertArgType


local function _assertInt(arg_n, v)
	if type(v) ~= "number" or math.floor(v) ~= v then
		error(interp(lang.arg_bad_int, arg_n), 2)
	end
end

local function _assertIntRange(arg_n, v, min, max)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min or v > max then
		error(interp(lang.arg_bad_int_range, arg_n, min, max), 2)
	end
end


-- Checks octets 2-4 in a multi-octet code point.
local function _checkFollowingOctet(octet, position, n_octets)
	-- NOTE: Do not call on the first octet.
	if not octet then
		return interp(lang.octet_nil, position)

	-- Check some bytes which are prohibited in any position in a UTF-8 code point
	elseif options.exclude_invalid_octets and utf8Tools.lut_invalid_octet[octet] then
		return interp(octet_invalid_value, octet, position)

	-- Verify "following" byte mark	
	-- < 1000:0000
	elseif octet < 0x80 then
		return interp(lang.octet_too_low, position, octet)

	-- >= 1100:0000
	elseif octet >= 0xc0 then
		return interp(lang.octet_too_high, position, octet)
	end
end


local function _getLengthMarker(byte)
	-- (returns a number on success, or error string on failure)
	return (byte < 0x80) and 1 -- 1 octet: 0000:0000 - 0111:1111
	or (byte >= 0xc0 and byte < 0xe0) and 2 -- 2 octets: 1100:0000 - 1101:1111
	or (byte >= 0xe0 and byte < 0xf0) and 3 -- 3 octets: 1110:0000 - 1110:1111
	or (byte >= 0xf0 and byte < 0xf8) and 4 -- 4 octets: 1111:0000 - 1111:0111
	or (byte >= 0x80 and byte < 0xbf) and lang.trailing_1st -- 1000:0000 - 1011:1111
	or lang.len_unknown
end


local function _checkCodePointIssue(code_point, u8_len)
	if options.check_surrogates then
		if code_point >= 0xd800 and code_point <= 0xdfff then
			return false, interp(lang.err_surrogate, string.format("0x%x", code_point))
		end
	end

	if code_point < 0 then
		return false, lang.cp_negative

	elseif code_point > 0x10ffff then
		return false, lang.cp_too_big
	end

	-- Look for overlong values based on the octet count.
	-- (Only applicable if known to have originated from a UTF-8 sequence.)
	if u8_len ~= false then
		local min_max = lut_oct_min_max[u8_len]
		if code_point < min_max[1] or code_point > min_max[2] then
			return false, interp(lang.len_mismatch, u8_len, code_point, min_max[1], min_max[2])
		end
	end

	return true
end


local function _codePointToBytes(number)
	if number < 0x80 then
		return number

	elseif number < 0x800 then
		local b1 = 0xc0 + math.floor(number / 0x40)
		local b2 = 0x80 + (number % 0x40)

		return b1, b2

	elseif number < 0x10000 then
		local b1 = 0xe0 + math.floor(number / 0x1000)
		local b2 = 0x80 + math.floor( (number % 0x1000) / 0x40)
		local b3 = 0x80 + (number % 0x40)

		return b1, b2, b3

	elseif number <= 0x10ffff then
		local b1 = 0xf0 + math.floor(number / 0x40000)
		local b2 = 0x80 + math.floor( (number % 0x40000) / 0x1000)
		local b3 = 0x80 + math.floor( (number % 0x1000) / 0x40)
		local b4 = 0x80 + (number % 0x40)

		return b1, b2, b3, b4
	end
end


local function _bytesToUCString(b1, b2, b3, b4)
	if b4 then
		return string.char(b1, b2, b3, b4)

	elseif b3 then
		return string.char(b1, b2, b3)

	elseif b2 then
		return string.char(b1, b2)

	else
		return string.char(b1)
	end
end


local function _getCodePointFromString(str, pos)
	local b1, b2, b3, b4 = str:byte(pos, pos + 3)
	local u8_len = _getLengthMarker(b1)
	if type(u8_len) == "string" then
		return nil, u8_len

	elseif options.exclude_invalid_octets and utf8Tools.lut_invalid_octet[b1] then
		return nil, interp(lang.invalid_b, b1, 1)
	end

	local code_point
	local err_str

	if u8_len == 1 then
		code_point = b1

	elseif u8_len == 2 then
		err_str = _checkFollowingOctet(b2, 2, 2) if err_str then return nil, err_str end
		code_point = (b1 - 0xc0) * 0x40 + (b2 - 0x80)

	elseif u8_len == 3 then
		err_str = _checkFollowingOctet(b2, 2, 3) if err_str then return nil, err_str end
		err_str = _checkFollowingOctet(b3, 3, 3) if err_str then return nil, err_str end
		code_point = (b1 - 0xe0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80)

	elseif u8_len == 4 then
		err_str = _checkFollowingOctet(b2, 2, 4) if err_str then return nil, err_str end
		err_str = _checkFollowingOctet(b3, 3, 4) if err_str then return nil, err_str end
		err_str = _checkFollowingOctet(b4, 4, 4) if err_str then return nil, err_str end
		code_point = (b1 - 0xf0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + (b4 - 0x80)
	end

	local code_ok, code_err = _checkCodePointIssue(code_point, u8_len)
	if not code_ok then
		return nil, code_err
	end

	return code_point, u8_len
end


function utf8Tools.getUCString(str, pos)
	_assertArgType(1, str, "string")
	_assertArgType(2, pos, "number")

	if pos < 1 or pos > #str then
		return nil, lang.str_i_oob
	end

	local code_point, u8_len = _getCodePointFromString(str, pos)

	if not code_point then
		return nil, u8_len -- error string
	end

	return str:sub(pos, pos + u8_len - 1)
end


function utf8Tools.step(str, pos)
	_assertArgType(1, str, "string")
	_assertIntRange(2, pos, 1, #str + 1)

	while pos <= #str do
		local b1 = str:byte(pos)
		local u8_len = _getLengthMarker(b1)
		if type(u8_len) == "number" then
			return pos
		end
		pos = pos + 1
	end

	return #str + 1
end


function utf8Tools.check(str, i, j)
	_assertArgType(1, str, "string")

	local str_max = math.max(1, #str)
	if i == nil then i = 1 end
	if j == nil then j = str_max end

	_assertIntRange(2, i, 1, str_max)
	_assertIntRange(3, j, 1, str_max)
	if i > j then error(lang.arg_start_end_oob) end

	if #str == 0 then
		return true
	end

	while i <= j do
		local code_point, u8_len = _getCodePointFromString(str, i)

		if not code_point then
			return false, i, u8_len -- error string
		end
		i = i + u8_len
	end

	return true
end


function utf8Tools.ucStringToCodePoint(str, pos)
	_assertArgType(1, str, "string")
	if #str == 0 then error(interp(lang.arg_empty_str)) end
	_assertIntRange(2, pos, 1, #str)

	return _getCodePointFromString(str, pos)
end


function utf8Tools.codePointToUCString(code)
	_assertInt(1, code)

	local ok, err = _checkCodePointIssue(code, false)
	if not ok then
		return nil, err
	end

	local b1, b2, b3, b4 = _codePointToBytes(code)

	return _bytesToUCString(b1, b2, b3, b4)
end


return utf8Tools
