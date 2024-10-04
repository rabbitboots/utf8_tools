local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local strict = require(PATH .. "test.strict")


local errTest = require(PATH .. "test.err_test")
local utf8Tools = require(PATH .. "utf8_tools")


local function resetOpts()
	utf8Tools.setCheckSurrogates(true)
end


-- (This is only here because Lua 5.1 does not have the '\xff' hex literal escapes for strings.)
local hex = string.char


local surr_0xd800 = hex(0xed, 0xa0, 0x80)
local str_invalid_byte = hex(0xc0)


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


--[[
Functions affected by options:

| Function                   | check_surrogates |
+----------------------------+------------------+
| utf8Tools.check()          | Yes              |
| utf8Tools.checkAlt()       | No               |
| utf8Tools.codeFromString() | Yes              |
| utf8Tools.codes()          | Yes              |
| utf8Tools.concatCodes()    | Yes              |
| utf8Tools.reverse()        | Yes              |
| utf8Tools.step()           | No               |
| utf8Tools.stringFromCode() | Yes              |
--]]


-- [===[
self:registerFunction("utf8Tools.codeFromString", utf8Tools.codeFromString)

self:registerJob("utf8Tools.codeFromString", function(self)
	resetOpts()

	self:expectLuaError("arg #1 bad type", utf8Tools.codeFromString, nil, 1)
	self:expectLuaError("arg #1 string too short", utf8Tools.codeFromString, "", 1)

	self:expectLuaError("arg #2 bad type", utf8Tools.codeFromString, "foobar", false)
	self:expectLuaError("arg #2 too low", utf8Tools.codeFromString, "12345", 0)
	self:expectLuaError("arg #2 too high", utf8Tools.codeFromString, "12345", 99)
	self:expectLuaError("arg #2 not an integer", utf8Tools.codeFromString, "12345", 0.333)

	local test_str = "@Æㇹ𐅀"

	do
		self:print(3, "[+] Test at least one code point from every UTF-8 byte-length class.")
		local i = 1
		local code, u8_str

		code, u8_str = utf8Tools.codeFromString(test_str, i)
		self:print(4, code, u8_str)
		self:isEqual(code, 0x40)
		self:isEqual(u8_str, "@")
		i = i + #u8_str
		self:lf(4)

		code, u8_str = utf8Tools.codeFromString(test_str, i)
		self:print(4, code, u8_str)
		self:isEqual(code, 0xc6)
		self:isEqual(u8_str, "Æ")
		i = i + #u8_str
		self:lf(4)

		code, u8_str = utf8Tools.codeFromString(test_str, i)
		self:print(4, code, u8_str)
		self:isEqual(code, 0x31f9)
		self:isEqual(u8_str, "ㇹ")
		i = i + #u8_str
		self:lf(4)

		code, u8_str = utf8Tools.codeFromString(test_str, i)
		self:print(4, code, u8_str)
		self:isEqual(code, 0x10140)
		self:isEqual(u8_str, "𐅀")
		i = i + #u8_str
		self:lf(4)
	end

	do
		self:print(3, "[-] Pass in bad data.")
		local code, u8_str = utf8Tools.codeFromString(hex(0xf0, 0x80, 0xe0), 1)
		self:print(4, code, u8_str)
		self:isEvalFalse(code)
		self:lf(4)
	end


	do
		self:print(3, "[-] Test a bad byte offset.")
		local code, u8_str = utf8Tools.codeFromString(test_str, 3)
		self:print(4, code, u8_str)
		self:isEvalFalse(code)
		self:lf(4)
	end

	do
		self:print(3, "[-] input string contains Nul as continuation byte (\\0)")
		local bad_string = "aaaa" .. hex(0xc3, 0x0) .. "aaaa" -- corrupted Æ. should be 0xc3, 0x86
		local code, u8_str = utf8Tools.codeFromString(bad_string, 5)
		self:print(4, code, u8_str)
		self:isEvalFalse(code)
		self:lf(4)
	end

	do
		self:print(3, "[+] input string with an acceptable use of Nul (\\0)")
		local ok_nul = "aaaa\000aaaa"
		local code, u8_str = utf8Tools.codeFromString(ok_nul, 5)
		self:print(4, code, u8_str)
		self:isEqual(code, 0)
		self:lf(4)
	end

	do
		self:print(3, "[-] invalid surrogate pair")
		resetOpts()
		local code, u8_str = utf8Tools.codeFromString(surr_0xd800)
		self:print(4, code, u8_str)
		self:isEvalFalse(code)
		self:lf(4)
	end

	do
		self:print(3, "[+] with 'check_surrogates' disabled")
		utf8Tools.setCheckSurrogates(false)
		local code, u8_str = utf8Tools.codeFromString(surr_0xd800)
		self:print(4, code, u8_str)
		self:isEvalTrue(code)
		resetOpts()
		self:lf(4)
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.step", utf8Tools.step)

self:registerJob("utf8Tools.step", function(self)
	resetOpts()

	self:expectLuaError("arg #1 bad type", utf8Tools.step, nil, 1)

	self:expectLuaError("arg #2 bad type", utf8Tools.step, "foobar", nil)
	self:expectLuaError("arg #2 out of bounds (too low)", utf8Tools.step, "foobar", -1)
	self:expectLuaError("arg #2 out of bounds (too high)", utf8Tools.step, "foobar", #"foobar" + 1)
	self:expectLuaError("arg #2 not an integer", utf8Tools.step, "foobar", 0.5)

	local test_str = "@Æㇹ𐅀"

	do
		self:print(3, "[+] Step forward through this test string: " .. test_str .. " (length: " .. #test_str .. ")")
		local expected_i = {1, 2, 4, 7}

		local i, c = 0, 0
		while i do
			self:print(4, "utf8Tools.step()", i)
			i = utf8Tools.step(test_str, i)
			c = c + 1
			self:isEqual(i, expected_i[c])
		end
		self:lf(4)
	end
end
)


-- [===[
self:registerFunction("utf8Tools.stepBack", utf8Tools.stepBack)

self:registerJob("utf8Tools.stepBack", function(self)
	resetOpts()

	self:expectLuaError("arg #1 bad type", utf8Tools.stepBack, nil, 1)

	self:expectLuaError("arg #2 bad type", utf8Tools.stepBack, "foobar", nil)
	self:expectLuaError("arg #2 out of bounds (too low)", utf8Tools.stepBack, "foobar", 0)
	self:expectLuaError("arg #2 out of bounds (too high)", utf8Tools.stepBack, "foobar", #"foobar" + 2)
	self:expectLuaError("arg #2 not an integer", utf8Tools.stepBack, "foobar", 0.5)

	local test_str = "@Æㇹ𐅀"

	do
		self:print(3, "[+] Step backwards through this test string: " .. test_str .. " (length: " .. #test_str .. ")")
		local expected_i = {1, 2, 4, 7}

		local i, c = #test_str + 1, #expected_i + 1
		while i do
			self:print(4, "utf8Tools.stepBack()", i)
			i = utf8Tools.stepBack(test_str, i)
			c = c - 1
			self:isEqual(i, expected_i[c])
		end
		self:lf(4)
	end
end
)


-- [===[
self:registerFunction("utf8Tools.check", utf8Tools.check)

self:registerJob("utf8Tools.check", function(self)
	resetOpts()

	self:expectLuaError("arg #1 bad type", utf8Tools.check, nil)

	self:expectLuaError("arg #2 bad type", utf8Tools.check, "foobar", {})
	self:expectLuaError("arg #2 not an integer", utf8Tools.check, "foobar", 1.1)
	self:expectLuaError("arg #2 too low", utf8Tools.check, "foobar", -1)
	self:expectLuaError("arg #2 too high", utf8Tools.check, "foobar", 10000)

	self:expectLuaError("arg #3 bad type", utf8Tools.check, "foobar", 1, {})
	self:expectLuaError("arg #3 not an integer", utf8Tools.check, "foobar", 1, 1.1)
	self:expectLuaError("arg #3 too low", utf8Tools.check, "foobar", 1, -1)
	self:expectLuaError("arg #3 too high", utf8Tools.check, "foobar", 1, 10000)

	do
		self:print(3, "[-] corrupt UTF-8 detection")
		local n_codes, err, i = utf8Tools.check("goodgoodgoodgoodgoodb" .. hex(0xf0, 0x80, 0xe0) .. "d")
		self:print(4, "(should return nil, 22, and some error message)")
		self:print(4, n_codes, i, err)
		self:isEvalFalse(n_codes)
		self:isEqual(i, 22)
		self:lf(4)
	end

	do
		self:print(3, "[+] good UTF-8 detection")
		local n_codes, err, i = utf8Tools.check("!@~¡Æøſㇱㇹ㈅꠲꠹𐅀𐅁𐅅𰀀")
		self:print(4, n_codes, i, err)
		self:isEqual(n_codes, 16) -- 16 code points
		self:lf(4)

	end

	do
		self:print(3, "[+] good UTF-8 detection of a substring")
		local n_codes, err, i = utf8Tools.check("!@~¡Æøſㇱㇹ㈅꠲꠹𐅀𐅁𐅅𰀀", 2, 3) -- "@~"
		self:print(4, n_codes, i, err)
		self:isEqual(n_codes, 2) -- 2 code points
		self:lf(4)
	end

	do
		self:print(3, "[-] invalid surrogate pair")
		resetOpts()
		local n_codes, err, i = utf8Tools.check("foo" .. surr_0xd800 .. "bar")
		self:print(4, n_codes, i, err)
		self:isEvalFalse(n_codes)
		self:lf(4)
	end

	do
		self:print(3, "[+] with 'check_surrogates' disabled")
		resetOpts()
		utf8Tools.setCheckSurrogates(false)
		local n_codes, err, i = utf8Tools.check("foo" .. surr_0xd800 .. "bar")
		self:print(4, n_codes, i, err)
		self:isEqual(n_codes, 7)
		resetOpts()
		self:lf(4)
	end

	do
		self:print(3, "[-] invalid UTF-8 byte")
		local n_codes, err, i = utf8Tools.check("foo" .. str_invalid_byte .. "bar")
		self:print(4, n_codes, i, err)
		self:isEvalFalse(n_codes)
		self:lf(4)
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.checkAlt", utf8Tools.check)

self:registerJob("utf8Tools.checkAlt", function(self)
	resetOpts()

	self:expectLuaError("arg #1 bad type", utf8Tools.checkAlt, nil)

	self:expectLuaError("arg #2 bad type", utf8Tools.checkAlt, "foobar", {})
	self:expectLuaError("arg #2 not an integer", utf8Tools.checkAlt, "foobar", 1.1)
	self:expectLuaError("arg #2 too low", utf8Tools.checkAlt, "foobar", -1)
	self:expectLuaError("arg #2 too high", utf8Tools.checkAlt, "foobar", 10000)

	do
		self:print(3, "[-] corrupt UTF-8 detection")
		local n_codes, err, i = utf8Tools.checkAlt("goodgoodgoodgoodgoodb" .. hex(0xf0, 0x80, 0xe0) .. "d")
		self:print(4, "(should return nil, 22)")
		self:print(4, n_codes, i)
		self:isEvalFalse(n_codes)
		self:isEqual(i, 22)
		self:lf(4)
	end

	do
		self:print(3, "[+] good UTF-8 detection")
		local n_codes, err, i = utf8Tools.checkAlt("!@~¡Æøſㇱㇹ㈅꠲꠹𐅀𐅁𐅅𰀀")
		self:print(4, n_codes, i)
		self:isEqual(n_codes, 16) -- 16 code points
		self:lf(4)

	end

	do
		self:print(3, "[+] good UTF-8 detection starting after byte 1")
		local n_codes, err, i = utf8Tools.checkAlt("!@~¡Æøſㇱㇹ㈅꠲꠹𐅀𐅁𐅅𰀀", 2) -- "@~..."
		self:print(4, n_codes, i)
		self:isEqual(n_codes, 15) -- 15 code points
		self:lf(4)
	end

	do
		self:print(3, "[-] invalid surrogate pair")
		resetOpts()
		local n_codes, err, i = utf8Tools.checkAlt("foo" .. surr_0xd800 .. "bar")
		self:print(4, n_codes, i)
		self:isEvalFalse(n_codes)
		self:lf(4)
	end

	-- utf8Tools.checkAlt() always rejects surrogate values.

	do
		self:print(3, "[-] invalid UTF-8 byte")
		local n_codes, err, i = utf8Tools.checkAlt("foo" .. str_invalid_byte .. "bar")
		self:print(4, n_codes, i)
		self:isEvalFalse(n_codes)
		self:lf(4)
	end
end
)
--]===]



-- [===[
self:registerFunction("utf8Tools.scrub", utf8Tools.scrub)

self:registerJob("utf8Tools.scrub", function(self)
	resetOpts()

	self:expectLuaError("arg #1 bad type", utf8Tools.scrub, nil, "x")
	self:expectLuaError("arg #2 bad type", utf8Tools.scrub, "foo", nil)
	-- don't type-check arg 3 (alt).

	do
		self:print(3, "[+] Good input, nothing to scrub")
		local good_str = "The good string."
		local str = utf8Tools.scrub(good_str, "x")
		self:isEqual(str, good_str)
		self:lf(4)
	end

	do
		self:print(3, "[+] Good input, nothing to scrub (alt)")
		local good_str = "The good string."
		local str = utf8Tools.scrub(good_str, "x", true)
		self:isEqual(str, good_str)
		self:lf(4)
	end

	do
		self:print(3, "[+] Malformed input, replace invalid bytes")
		local bad_str = "The b" .. hex(0xff, 0xff, 0xff) .. "d string."
		local str = utf8Tools.scrub(bad_str, "x")
		self:isEqual(str, "The bxd string.")
		self:lf(4)
	end

	do
		self:print(3, "[+] Malformed input, replace invalid bytes (alt)")
		local bad_str = "The b" .. hex(0xff, 0xff, 0xff) .. "d string."
		local str = utf8Tools.scrub(bad_str, "x", true)
		self:isEqual(str, "The bxd string.")
		self:lf(4)
	end

	do
		self:print(3, "[+] Malformed input, delete invalid bytes")
		local bad_str = "The b" .. hex(0xff, 0xff, 0xff) .. "d string."
		local str = utf8Tools.scrub(bad_str, "")
		self:isEqual(str, "The bd string.")
		self:lf(4)
	end

	do
		self:print(3, "[+] Malformed input, delete invalid bytes (alt)")
		local bad_str = "The b" .. hex(0xff, 0xff, 0xff) .. "d string."
		local str = utf8Tools.scrub(bad_str, "", true)
		self:isEqual(str, "The bd string.")
		self:lf(4)
	end

	do
		self:print(3, "[+] Input with surrogate pair; replace")
		resetOpts()
		local surr_str = "abc" .. surr_0xd800 .. "def"
		local str = utf8Tools.scrub(surr_str, "_")
		self:isEqual(str, "abc_def")
		resetOpts()
		self:lf(4)
	end

	do
		self:print(3, "[+] Input with surrogate pair; replace (alt)")
		resetOpts()
		local surr_str = "abc" .. surr_0xd800 .. "def"
		local str = utf8Tools.scrub(surr_str, "_", true)
		self:isEqual(str, "abc_def")
		resetOpts()
		self:lf(4)
	end

	do
		self:print(3, "[+] Input with surrogate pair: ignore")
		resetOpts()
		utf8Tools.setCheckSurrogates(false)
		local surr_str = "abc" .. surr_0xd800 .. "def"
		local str = utf8Tools.scrub(surr_str, "_")
		self:isEqual(str, surr_str)
		resetOpts()
		self:lf(4)
	end

	-- checkAlt() always rejects surrogate pairs.
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.stringFromCode()", utf8Tools.stringFromCode)

self:registerJob("utf8Tools.stringFromCode", function(self)
	resetOpts()

	self:expectLuaError("arg #1 bad type", utf8Tools.stringFromCode, nil)

	do
		self:print(3, "[-] invalid negative code point")
		local u8_str, err = utf8Tools.stringFromCode(-11111)
		self:print(4, u8_str, err)
		self:isEvalFalse(u8_str)
		self:lf(4)
	end

	do
		self:print(3, "[-] overlarge code point")
		local u8_str, err = utf8Tools.stringFromCode(2^32)
		self:print(4, u8_str, err)
		self:isEvalFalse(u8_str)
		self:lf(4)
	end

	do
		self:print(3, "[+] expected behavior")
		local u8_str, err
		u8_str, err = utf8Tools.stringFromCode(33)
		self:print(4, u8_str, err)
		self:isEqual(u8_str, "!")
		self:lf(4)

		u8_str, err = utf8Tools.stringFromCode(198)
		self:print(4, u8_str, err)
		self:isEqual(u8_str, "Æ")
		self:lf(4)

		u8_str, err = utf8Tools.stringFromCode(12793)
		self:print(4, u8_str, err)
		self:isEqual(u8_str, "ㇹ")
		self:lf(4)
	end

	do
		self:print(3, "[-] invalid surrogate pair")
		resetOpts()
		local u8_str, err = utf8Tools.stringFromCode(0xd800)
		self:print(4, u8_str, err)
		self:isEvalFalse(u8_str)
		self:lf(4)
	end

	do
		self:print(3, "[+] with 'check_surrogates' disabled")
		resetOpts()
		utf8Tools.setCheckSurrogates(false)
		local u8_str, err = utf8Tools.stringFromCode(0xd800)
		self:print(4, u8_str, err)
		self:isEvalTrue(u8_str)
		resetOpts()
		self:lf(4)
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.codes() (iterator)", utf8Tools.codes)

self:registerJob("utf8Tools.codes", function(self)
	resetOpts()

	local func = function(s)
		for i, c, u in utf8Tools.codes(s) do
			self:print(4, "i,c,u", i, c, u)
		end
	end
	local bad_string = "aaaa" .. hex(0xc3, 0x0) .. "aaaa" -- corrupted Æ. should be 0xc3, 0x86
	local good_string = "!@~¡Æøſㇱㇹ㈅꠲꠹𐅀𐅁𐅅𰀀"

	self:expectLuaError("arg #1 bad type", func, {})
	self:expectLuaError("arg #1 invalid encoding", func, bad_string)
	self:expectLuaReturn("arg #1 expected behavior", func, "!@~¡Æøſㇱㇹ㈅꠲꠹𐅀𐅁𐅅𰀀")

	resetOpts()
	self:expectLuaError("surrogate byte (excluded)", func, "foo" .. surr_0xd800 .. "bar")

	utf8Tools.setCheckSurrogates(false)
	self:expectLuaReturn("surrogate byte (allowed)", func, "foo" .. surr_0xd800 .. "bar")
	resetOpts()
end
)
--]===]


-- [===[
self:registerFunction("utf8Tools.concatCodes()", utf8Tools.concatCodes)

self:registerJob("utf8Tools.concatCodes", function(self)
	resetOpts()

	self:expectLuaError("bad type in args", utf8Tools.concatCodes, 0x40, {}, 0x40)
	self:expectLuaError("invalid code point (too big) in args", utf8Tools.concatCodes, 0x40, 2^30, 0x40)
	self:expectLuaError("invalid code point (negative) in args", utf8Tools.concatCodes, 0x40, -33, 0x40)

	self:expectLuaReturn("no args, no problem (makes an empty string)", utf8Tools.concatCodes)

	do
		self:print(3, "[+] expected behavior")
		local good_string = "!@~¡Æøſㇱㇹ㈅꠲꠹𐅀𐅁𐅅𰀀"
		local str = utf8Tools.concatCodes(
			0x21, 0x40, 0x7e, 0xa1, 0xc6, 0xf8,
			0x17f, 0x31f1, 0x31f9, 0x3205, 0xa832,
			0xa839, 0x10140, 0x10141, 0x10145, 0x30000
		)
		self:print(4, str, #str)
		self:print(4, good_string, #good_string)
		self:print(4, str == good_string)
		self:isEqual(str, good_string)
		self:lf(4)
	end

	resetOpts()
	self:expectLuaError("surrogate byte (excluded)", utf8Tools.concatCodes, 0x40, 0xd800, 0x40)

	utf8Tools.setCheckSurrogates(false)
	self:expectLuaReturn("surrogate byte (allowed)", utf8Tools.concatCodes, 0x40, 0xd800, 0x40)
	resetOpts()
	self:lf(4)
end
)
--]===]


self:runJobs()

