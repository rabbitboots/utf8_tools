--[[
util: some boilerplate code for Lua-based command line utilities.

Author: RBTS
Started: April 2024
Version: 0.1 (WIP)
License: MIT (NOTE: scripts which load this module may have different licenses.)

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
SOFTWARE.
--]]


local util = {}


local _mt_util = {}
_mt_util.__index = _mt_util


-- These args should be handled before the main options loop runs.
local args_to_ignore = {
	["--help"] = true,
	["--version"] = true,
	["--license"] = true,
}


--- Creates a new application object.
function util.new()

	local self = {}

	-- Handler functions for arguments.
	self.arg_handlers = {}

	return setmetatable(self, _mt_util)
	
	-- You should attach strings for the following options:
	-- "--help" -> self.str_help
	-- "--version" -> self.str_version
	-- "--license" -> self.str_license
end


--- Check for and handle `--help`, `--version` and `--license` arguments.
-- @param argument The argument string to check. This is usually `arg[1]`.
-- @return true if a help, version or license string was printed, nil if not. Terminating the process is left to the
-- main script.
function _mt_util:checkHelpVerLic(argument)

	if argument == "--help" then
		print(self.str_help or "No help string found.")
		return true

	elseif argument == "--version" then
		print(self.str_version or "No version string found.")
		return true

	elseif argument == "--license" then
		print(self.str_license or "No license string found.")
		return true
	end

	-- return nil
end


--- Arguments parsing loop. Place handlers for arguments in `self.arg_handlers`, where the argument name is the key, and
--  the value is a function taking self, the arguments list, and the current argument index. A handler for unspecified
--  arguments may be specified at `self.arg_handlers[false]`.
-- @param arguments The arguments list (typically the global `arg`).
-- @return true if arguments parsed successfully, false if a handler failed.
function _mt_util:checkArgs(arguments)

	local i = 1
	while i <= #arguments do
		local str = arguments[i]

		if not args_to_ignore[str] then
			local handler = self.arg_handlers[str] or self.arg_handlers[false]

			if handler then
				local result = handler(self, arguments, i)

				-- False: error state.
				if result == false then
					return false

				-- True: success, and no more parsing is needed.
				elseif result == true then
					return true

				-- Number: success, and skip ahead by a number of arguments.
				elseif type(result) == "number" then
					if result < 1 or result ~= math.floor(result) or result ~= result then
						error("bad numeric result (must be >= 1, must be a whole number, cannot be NaN: " .. tostring(result) .. ")")
					end
					i = i + result

				-- Anything else is invalid.
				else
					error("invalid return value: " .. tostring(result))
				end
			end
		end
	end

	return true
end


function util.assertArg(arguments, i, err_name)

	local a2 = arguments[i]
	if not a2 then
		error("missing value for option: " .. err_name .. " (item #" .. i .. ").")
	end

	return a2
end


function util.assertToNumber(n, i, err_name)

	local temp = tonumber(n)
	if not temp then
		error("couldn't convert string to number for option: " .. err_name .. "(item #" .. i .. ").")
	end

	return temp
end


function util.assertArgToNumber(arguments, i, err_name)
	
	local n = util.assertArg(arguments, i, err_name)
	n = util.assertToNumber(n, i, err_name)
	
	return n
end


function util.roundToZero(n)
	return (n >= 0) and math.floor(n) or math.ceil(n)
end


function util.concatArguments(arguments, i, err_name, space)

	local tmp = {}
	for j = i, #arguments do
		tmp[#tmp + 1] = arguments[j]
	end
	local str = table.concat(tmp, space)
	return str
end


function util.assertReadFile(path)

	local file = io.open(path, "rb")
	if not file then
		error("failed to open file: " .. path)
	end

	local str = file:read("a") -- 5.1 needs "*a" I think
	if not str then
		error("unable to read file contents: " .. path)
	end

	file:close()

	-- NOTE: Text files may include a hidden newline (0xa) at the very end.
	return str
end


return util

