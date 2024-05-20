local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local strict = require(REQ_PATH .. "test.lib.strict")


local errTest = require(REQ_PATH .. "test.lib.err_test")
local utf8Tools = require(REQ_PATH .. "utf8_tools")


-- (This is only here because Lua 5.1 does not have the '\xff' hex literal escapes for strings.)
local hex = string.char


local samples = {
	-- Thanks: https://www.utf8-chartable.de/unicode-utf8-table.pl

	-- ONE BYTE
	-- U+0000 - U+007F: Basic Latin
	{"!", "U+0021"},
	{"@", "U+0040"},
	{"~", "U+007E"},

	-- TWO BYTES
	-- U+0080 - U+00FF: Latin-1 Supplement
	{"¡", "U+00A1"},
	{"Æ", "U+00C6"},
	{"ø", "U+00F8"},

	-- U+0100 - U+017F: Latin Extended-A
	{"ſ", "U+017F"},

	-- THREE BYTES
	-- U+31F) - U+31FF: Katakana Phonetic Extensions
	{"ㇱ", "U+31F1"},
	{"ㇹ", "U+31F9"},
	{"㈅", "U+3205"},

	-- U+A830 - U+A83F: Common Indic Number Forms
	{"꠲", "U+A832"},
	{"꠹", "U+A839"},

	-- FOUR-BYTES
	-- U+10140 - U+1018F: Ancient Greek Numbers
	{"𐅀", "U+10140"},
	{"𐅁", "U+10141"},
	{"𐅅", "U+10145"},

	-- U+30000 - U+3134F: <CJK Ideograph Extension G>
	{"𰀀", "U+30000"},
}


local cli_verbosity
for i = 0, #arg do
	if arg[i] == "--verbosity" then
		cli_verbosity = tonumber(arg[i + 1])
		if not cli_verbosity then
			error("invalid verbosity value")
		end
	end
end


local self = errTest.new("utf8Tools", cli_verbosity)


-- [===[
self:registerFunction("utf8Tools.getUCString", utf8Tools.getUCString)

self:registerJob("utf8Tools.getUCString", function(self)
	self:expectLuaError("arg #1 bad type", utf8Tools.getUCString, nil, 1)
	self:expectLuaError("arg #2 bad type", utf8Tools.getUCString, "foobar", false)

	local test_str = "@Æㇹ𐅀"

	do
		self:print(2, "[+] Test at least one code point from every UTF-8 byte-length class.")
		local i = 1
		while i < #test_str do
			local ok, err = utf8Tools.getUCString(test_str, i)
			self:print(4, ok, err)
			self:isEvalTrue(ok)
			i = i + #ok
		end
	end

	do
		self:print(2, "[-] Test a bad byte offset.")
		local ok, err = utf8Tools.getUCString(test_str, 3)
		self:print(4, ok, err)
		self:isEvalFalse(ok)
	end

	do
		self:print(2, "[-] byte index is < 1")
		local ok, err = utf8Tools.getUCString(test_str, 0)
		self:print(4, ok, err)
		self:isEvalFalse(ok)
	end

	do
		self:print(2, "[-] byte index is > #test_str")
		local ok, err = utf8Tools.getUCString(test_str, #test_str + 1)
		self:print(4, ok, err)
		self:isEvalFalse(ok)
	end

	do
		self:print(2, "[-] input string contains Nul as continuation byte (\\0)")
		local bad_string = "aaaa" .. hex(0xc3, 0x0) .. "aaaa" -- corrupted Æ. should be 0xc3, 0x86
		local ok, err = utf8Tools.getUCString(bad_string, 5)
		self:print(4, ok, err)
		self:isEvalFalse(ok)
	end

	do
		self:print(2, "[+] input string with an acceptable use of Nul (\\0)")
		local ok_nul = "aaaa\000aaaa"
		local ok, err = utf8Tools.getUCString(ok_nul, 5)
		self:print(4, ok, err)
		self:isEvalTrue(ok)
	end

	do
		self:print(2, "[-] input string contains surrogate range code points")
		local surr = "a" .. hex(0xed, 0xa0, 0x80) .. "b"
		local ok, err = utf8Tools.getUCString(surr, 2)
		self:print(4, ok, err)
		self:isEvalFalse(ok)
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.step", utf8Tools.step)

self:registerJob("utf8Tools.step", function(self)
	self:expectLuaError("arg #1 bad type", utf8Tools.step, nil, 1)
	self:expectLuaError("arg #2 bad type", utf8Tools.step, "foobar", nil)
	self:expectLuaError("arg #2 out of bounds (too low)", utf8Tools.step, "foobar", 0)
	self:expectLuaError("arg #2 out of bounds (too high)", utf8Tools.step, "foobar", #"foobar" + 2)
	self:expectLuaError("arg #2 not an integer", utf8Tools.step, "foobar", 0.5)

	local test_str = "@Æㇹ𐅀"

	do
		self:print(2, "[+] Step through this test string: " .. test_str .. " (length: " .. #test_str .. ")")
		local expected_i = {1, 2, 4, 7, 11}

		local i, c = 1, 1
		while true do
			self:print(4, "utf8Tools.step()", i)
			if i > #test_str then
				break
			end
			self:isEqual(i, expected_i[c])
			i = utf8Tools.step(test_str, i + 1)
			c = c + 1
		end
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.check", utf8Tools.check)

self:registerJob("utf8Tools.check", function(self)
	self:expectLuaError("arg #1 bad type", utf8Tools.check, nil)

	do
		self:print(2, "[-] corrupt UTF-8 detection")
		local ok, i, err = utf8Tools.check("goodgoodgoodgoodgoodb" .. hex(0xf0, 0x80, 0xe0) .. "d (should return true)")
		self:print(4, "(should return false, 22, and some error message)")
		self:print(4, ok, i, err)
		self:isEvalFalse(ok)
		self:isEqual(i, 22)
	end

	do
		self:print(2, "[+] good UTF-8 detection")
		local ok, i, err = utf8Tools.check("!@~¡Æøſㇱㇹ㈅꠲꠹𐅀𐅁𐅅𰀀")
		self:print(4, ok, i, err)
		self:isEvalTrue(ok)
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.ucStringToCodePoint", utf8Tools.ucStringToCodePoint)

self:registerJob("utf8Tools.ucStringToCodePoint", function(self)
	self:expectLuaError("arg #1 bad type", utf8Tools.ucStringToCodePoint, nil)
	self:expectLuaError("arg #1 string too short", utf8Tools.ucStringToCodePoint, "", 1)
	self:expectLuaError("arg #2 bad type", utf8Tools.ucStringToCodePoint, "12345", false)
	self:expectLuaError("arg #2 too low", utf8Tools.ucStringToCodePoint, "12345", 0)
	self:expectLuaError("arg #2 too high", utf8Tools.ucStringToCodePoint, "12345", 99)
	self:expectLuaError("arg #2 not an integer", utf8Tools.ucStringToCodePoint, "12345", 0.333)

	do
		self:print(2, "[+] Expected behavior.")
		local good_point = utf8Tools.ucStringToCodePoint("Æ", 1)
		self:print(4, good_point)
		local ok, err = utf8Tools.codePointToUCString(good_point)
		self:print(4, ok, err)
		self:isEvalTrue(ok)
	end

	do
		self:print(2, "[-] Pass in bad data.")
		local bad_point, bad_err = utf8Tools.ucStringToCodePoint(hex(0xf0, 0x80, 0xe0), 1)
		self:print(4, bad_point, bad_err)
		self:isEvalFalse(bad_point)
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.codePointToUCString", utf8Tools.codePointToUCString)

self:registerJob("utf8Tools.codePointToUCString", function(self)
	self:expectLuaError("arg #1 bad type", utf8Tools.codePointToUCString, nil)

	do
		self:print(2, "[-] invalid negative code point")
		local ok, res = utf8Tools.codePointToUCString(-11111)
		self:print(4, ok, res)
		self:isEvalFalse(ok)
	end

	do
		self:print(2, "[-] overlarge code point")
		local ok, res = utf8Tools.codePointToUCString(2^32)
		self:print(4, ok, res)
		self:isEvalFalse(ok)
	end

	do
		self:print(2, "[+] expected behavior")
		local ch
		ch = utf8Tools.codePointToUCString(33)
		self:print(4, ch)
		self:isEqual(ch, "!")

		ch = utf8Tools.codePointToUCString(198)
		self:print(4, ch)
		self:isEqual(ch, "Æ")

		ch = utf8Tools.codePointToUCString(12793)
		self:print(4, ch)
		self:isEqual(ch, "ㇹ")
	end
end
)
--]===]


self:runJobs()


return self:allGood() and 0 or -1
