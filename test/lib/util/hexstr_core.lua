-- needs testing

local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local hexStrCore = {}


-- Temporary workspace tables.
local temp, nums = {}, {}


local function emptyTable(t)
	for i = #t, 1, -1 do
		t[i] = nil
	end
end


local util = require(REQ_PATH .. "util")


local function checkHexChar(ch)

	if not string.find(ch, "^[0-9a-fA-F]") then
		error("invalid hex character: " .. tostring(ch))
	end
end


local function byteHexStr(byte)

	local chunk = string.format("%X", byte)
	if #chunk == 1 then
		chunk = "0" .. chunk
	end

	return chunk
end


local function _writeConcat(str)
	temp[#temp + 1] = str
end


local function _writeTerm(str)
	io.write(str)
end


local function _finishConcat()

	local str = table.concat(temp)
	emptyTable(temp)
	return str
end


local function _finishTerm()

end


local function encode(input, space, chars_per_row, fn_write, fn_finish)

	local cursor = 0

	for c in string.gmatch(input, ".") do

		local chunk = byteHexStr(string.byte(c))
		for h = 1, #chunk do
			fn_write(string.sub(chunk, h, h))
			cursor = cursor + 1
			if chars_per_row > 0 and cursor >= chars_per_row then
				cursor = 0
				fn_write("\n")
			end

			if space and h == #chunk and cursor ~= 0 then
				fn_write(" ")
			end
		end
	end

	if cursor ~= 0 then
		fn_write("\n")
	end

	return fn_finish()
end


function hexStrCore.encode(input, space, chars_per_row)

	space = space or false
	chars_per_row = chars_per_row or 80

	return encode(input, space, chars_per_row, _writeConcat, _finishConcat)
end


function hexStrCore.encodePrint(input, space, chars_per_row)

	space = space or false
	chars_per_row = chars_per_row or 80

	return encode(input, space, chars_per_row, _writeTerm, _finishTerm)
end


local function decode(input, fn_write, fn_finish)

	emptyTable(nums)

	for c in string.gmatch(input, ".") do

		-- Ignore ASCII whitespace.
		if c == "\n" or c == " " or c == "\t" or c == "\v" then
			-- (continue)

		elseif #nums < 2 then
			checkHexChar(c)
			nums[#nums + 1] = tonumber(c, 16)
		end

		if #nums == 2 then
			fn_write(string.char(nums[1] * 16 + nums[2]))
			emptyTable(nums)
		end
	end

	fn_write("\n")

	return fn_finish(), (#nums == 1)
end


function hexStrCore.decode(input)
	return decode(input, _writeConcat, _finishConcat)
end


function hexStrCore.decodePrint(input)
	return decode(input, _writeTerm, _finishTerm)
end


return hexStrCore
