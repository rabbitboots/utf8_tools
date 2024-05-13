-- needs (re-)testing

local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local script_name = "hexstr"
local license = [[
MIT License

Copyright (c) 2024 RBTS

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
SOFTWARE.]]


local hexStrCore = require(REQ_PATH .. "hexstr_core")
local util = require(REQ_PATH .. "util")


local self = util.new()


self.str_version = "hexstr.lua: version 0.1 (WIP)"


self.str_help = [[
hexstr.lua: convert a general string to hexadecimal format and back.

Supported Lua versions: TODO

Options:

--encode (default): Encode from a general string to printed hex.
--decode: Decode from printed hex to a general string.
--file <filename>: Use a file as input.
--input <...>: Use all remaining command line arguments as input. This is
  activated implicitly upon encountering the first unknown argument (unless --file
  has already been specified.)

Format options for --encode:

--space: Add spaces between printed hex bytes (but not at the end of rows).
--wrap <number>: Wrap lines after this number of printed characters.
  Use 0 (the default) to disable wrapping. If used with `--space`, an even number
  is recommended.

Info:

--help: Print this message.
--version: Print version string.

When using arguments as input, whitespace is truncated. File-as-input and
arguments-as-input are mutually exclusive.

Examples:

lua hexstr.lua foo bar
-> 666F6F20626172

lua hexstr.lua --decode 666F6F20626172
-> foo bar

]]


if self:checkHelpVerLic(arg[1]) then
	return 0
end


-- "encode", "decode"
local mode = "encode"

-- string from command line arguments or file, or false if no input.
local input = false

-- See: `--file`
local file_mode = false

-- See: `--wrap`. One hex byte is two printed characters. 0 == do not wrap.
local chars_per_row = 0

-- See: `--space`
local add_space = false


self.arg_handlers = {
	["--encode"] = function()

		mode = "encode"
		return 1
	end,

	["--decode"] = function()

		mode = "decode"
		return 1
	end,

	["--file"] = function(self, arguments, i)

		file_mode = true
		local file_path = util.assertArg(arguments, i + 1, "--file")
		input = util.assertReadFile(file_path)
		return 2
	end,

	["--wrap"] = function(self, arguments, i)

		local temp_wrap = util.assertArgToNumber(arguments, i + 1, "--wrap")
		chars_per_row = math.floor(math.max(0, temp_wrap))
		return 2
	end,

	["--space"] = function()

		add_space = true
		return 1
	end,
	
	-- If not in file mode, treat all remaining arguments as input.
	[false] = function(self, arguments, i)

		local str = arguments[i]

		if file_mode then
			if str == "--input" then
				print(script_name .. ": can't accept both file and command line input in the same invokation.")

			else
				print(script_name .. ": unknown argument: " .. str)
			end

			return false

		else
			local tmp = {}
			local id = "--input"

			-- Skip over explicit `--input` argument.
			if str == "--input" then
				id = "--input (implicit)"
				i = i + 1
			end
			input = util.concatArguments(arg, i, id, " ")

			return true
		end
	end,
}


if not self:checkArgs(arg) then
	return 1
end


if not input then
	print(script_name .. ": no input provided.")
	return 1
end


if mode == "encode" then
	hexStrCore.encodePrint(input, add_space, chars_per_row)

else -- "decode"
	local _, trailing = hexStrCore.decodePrint(input)

	if trailing then
		print("\n")
		print(script_name .. ": missing nibble of final byte.")
		return 1
	end
end


return 0

