-- errTest2 v2.0.0 (prerelease)
-- https://github.com/rabbitboots/err_test

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


local errTest = {}


errTest.lang = {
	assert_arg_bad_type = "argument #$1: bad type (expected $2, got $3)",
	err_dupe_job = "attempt to run job twice.",
	err_add_dupe_job = "tried to add a duplicate job function",
	err_missing_func = "no job function at index $1",
	fail_eq = "expected value equality",
	fail_bool_false = "expected boolean false",
	fail_bool_true = "expected boolean true",
	fail_eval_false = "expected false evaluation (falsy)",
	fail_eval_true = "expected true evaluation (truthy)",
	fail_missing_nan = "expected NaN value",
	fail_neq = "expected inequality",
	fail_nil = "expected nil",
	fail_not_nil = "expected not nil",
	fail_unwanted_nan = "unwanted NaN value",
	fail_type_check = "expected type $1, got $2",
	fail_not_type_check = "expected not to receive type $1, got $2",
	job_msg_post = "[$1]",
	job_msg_pre = "($1/$2) $3: ",
	msg_warn = "[warn]: $1",
	res_fail = "fail",
	res_pass = "pass",
	test_begin = "<Begin test: $1>",
	test_end = "<End test: $1>",
	test_expect_pass = "[+] $1: $2 ($3): ",
	test_expect_pass_failed = "Expected passing call failed:",
	test_expect_fail = "[-] $1: $2 ($3): ",
	test_expect_fail_passed = "Expected failing call passed:",
	test_totals = "Passed: $1/$2, Warnings: $3",
}
local lang = errTest.lang


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


local _mt_test = {}
_mt_test.__index = _mt_test


local function _checkMultiType(val, list)
	for w in list:gmatch("(%w+)") do
		if type(val) == w then
			return true
		end
	end
end


local function _assertArgType(arg_n, val, expected)
	if not _checkMultiType(val, expected) then
		error(interp(lang.assert_arg_bad_type, arg_n, expected, type(val)), 2)
	end
end


local function varargsToString(self, ...)
	local n_args = select("#", ...)
	if n_args == 0 then
		return ""
	end

	local temp = {...}
	for i = 1, n_args do
		temp[i] = tostring(temp[i])
	end

	return table.concat(temp, ", ")
end


local function getLabel(self, func)
	return self.reg[func] or ""
end


function errTest.new(name, verbosity)
	_assertArgType(1, name, "nil/string")
	_assertArgType(2, verbosity, "nil/number")

	local self = {
		name = name or "",
		verbosity = verbosity or 4,

		reg = {},
		jobs = {},

		counters = {
			pass = 0,
			warn = 0,
		}
	}

	return setmetatable(self, _mt_test)
end


function _mt_test:registerFunction(label, func)
	_assertArgType(1, label, "nil/string")
	_assertArgType(2, func, "function")

	self.reg[func] = label
end


function _mt_test:registerJob(desc, func)
	_assertArgType(1, desc, "nil/string")
	_assertArgType(2, func, "function")

	for i, job in ipairs(self.jobs) do
		if job[2] == func then
			error(lang.err_add_dupe_job)
		end
	end

	table.insert(self.jobs, {desc or "", func})
end


function _mt_test:runJobs()
	if self.verbosity >= 1 then
		print(interp(lang.test_begin, self.name))
	end

	local dupes = {}
	for i, job in ipairs(self.jobs) do
		local desc, func = job[1], job[2]

		if not func then
			error(interp(lang.err_missing_func, i))
		end

		if dupes[func] then
			error(lang.err_dupe_job)
		end
		dupes[func] = true

		if self.verbosity >= 2 then
			io.write(interp(lang.job_msg_pre, i, #self.jobs, desc))
			if self.verbosity >= 3 then
				io.write("\n")
			end
		end

		local counters = self.counters
		local ok, err = pcall(func, self)

		if ok then
			counters.pass = counters.pass + 1
		end

		if self.verbosity >= 2 then
			io.write(interp(lang.job_msg_post, lang.res_pass) .. "\t")
			if not ok then
				io.write(tostring(err) or "")
			end
			io.write("\n")
		end
	end

	if self.verbosity >= 1 then
		print(interp(lang.test_end, self.name))
		local cnt = self.counters
		print(interp(lang.test_totals, cnt.pass, #self.jobs, cnt.warn))
	end
end


function _mt_test:allGood()
	return self.counters.pass == #self.jobs
end


function _mt_test:print(level, ...)
	if self.verbosity >= level then
		print(...)
	end
end


function _mt_test:write(level, str)
	if self.verbosity >= level then
		io.write(str)
	end
end


function _mt_test:warn(str)
	self.counters.warn = self.counters.warn + 1
	if self.verbosity >= 2 then
		print(interp(lang.msg_warn, tostring(str)))
	end
end


function _mt_test:expectLuaReturn(desc, func, ...)
	_assertArgType(1, desc, "nil/string")
	_assertArgType(2, func, "function")

	if self.verbosity >= 3 then
		io.write(interp(lang.test_expect_pass, desc or "", getLabel(self, func), varargsToString(self, ...)))
		io.flush()
	end

	local ok, res = pcall(func, ...)
	if not ok then
		error(lang.test_expect_pass_failed .. "\n\t" .. tostring(res))
	else
		io.write(lang.res_pass)
	end

	return ok, res
end


function _mt_test:expectLuaError(desc, func, ...)
	_assertArgType(1, desc, "nil/string")
	_assertArgType(2, func, "function")

	if self.verbosity >= 3 then
		io.write(interp(lang.test_expect_fail, desc or "", getLabel(self, func), varargsToString(self, ...)))
		io.flush()
	end

	local ok, res = pcall(func, ...)
	if ok == true then
		error(lang.test_expect_fail_passed .. "\n\t" .. tostring(res))
	else
		if self.verbosity >= 3 then
			io.write(lang.res_fail .. "\n")
		end
		self:print(4, "->" .. tostring(res))
	end

	return ok, res
end


function _mt_test:isEqual(a, b) if a ~= b then error(lang.fail_eq, 2) else self:print(5, "isEqual()") end end
function _mt_test:isNotEqual(a, b) if a == b then error(lang.fail_neq, 2) else self:print(5, "isNotEqual()") end end

function _mt_test:isBoolTrue(a) if a ~= true then error(lang.fail_bool_true, 2) else self:print(5, "isBoolTrue()") end end
function _mt_test:isBoolFalse(a) if a ~= false then error(lang.fail_bool_false, 2) else self:print(5, "isBoolFalse()") end end

function _mt_test:isEvalTrue(a) if not a then error(lang.fail_eval_true, 2) else self:print(5, "isEvalTrue()") end end
function _mt_test:isEvalFalse(a) if a then error(lang.fail_eval_false, 2) else self:print(5, "isEvalFalse()") end end

function _mt_test:isNil(a) if a ~= nil then error(lang.fail_nil, 2) else self:print(5, "isNil()") end end
function _mt_test:isNotNil(a) if a == nil then error(lang.fail_not_nil, 2) else self:print(5, "isNotNil()") end end

function _mt_test:isNan(a) if a == a then error(lang.fail_missing_nan, 2) else self:print(5, "isNan()") end end
function _mt_test:isNotNan(a) if a ~= a then error(lang.fail_unwanted_nan, 2) else self:print(5, "isNotNan()") end end


function _mt_test:isType(val, expected)
	_assertArgType(1, expected, "string")

	if not _checkMultiType(val, expected) then
		error(interp(lang.fail_type_check, expected, type(val)), 2)
	else
		self:print(5, "isType", expected)
	end
end


function _mt_test:isNotType(val, not_expected)
	_assertArgType(1, not_expected, "string")
	if _checkMultiType(val, not_expected) then
		error(interp(lang.fail_not_type_check, not_expected, type(val)), 2)
	else
		self:print(5, "isNotType", not_expected)
	end
end


return errTest
