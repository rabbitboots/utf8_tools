local path = ... and (...):match("(.-)[^%.]+$") or ""

local strict = require(path .. "test.lib.strict")

local utf8Tools = require(path .. "utf8_tools")

local errTest = require(path .. "test.lib.err_test")


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

do
	print("\nTest: " .. errTest.register(utf8Tools.getUCString, "utf8Tools.getUCString"))

	local ok, res

	print("\n[-] arg #1 bad type")
	errTest.expectFail(utf8Tools.getUCString, nil, 1)

	print("\n[-] arg #2 bad type")
	errTest.expectFail(utf8Tools.getUCString, "foobar", false)

	print("\n[ad hoc] expected behavior. Test at least one code point from every byte-length class.")
	local test_str = "@Æㇹ𐅀"
	local i = 1
	while i < #test_str do
		local ok, err = utf8Tools.getUCString(test_str, i)
		if not ok then
			error("expected passing getUCString() call failed: " .. err)
		end
		print(ok)
		i = i + #ok
	end

	print("\n[ad hoc] arg #2 misalignment (bad byte offset)")
	local ok, err = utf8Tools.getUCString(test_str, 3)
	if ok then
		print(ok, err)
		error("expected failing getUCString() call passed.")
	end
	print(err)

	print("\n[ad hoc] arg #2 < 1")
	local ok, err = utf8Tools.getUCString(test_str, 0)
	if ok then
		print(ok, err)
		error("expected failing getUCString() call passed.")
	end
	print(err)

	print("\n[ad hoc] arg #2 > #test_str")
	local ok, err = utf8Tools.getUCString(test_str, #test_str + 1)
	if ok then
		print(ok, err)
		error("expected failing getUCString() call passed.")
	end
	print(err)

	print("\n[-] Arg #1 contains Nul as continuation byte (\\0)")
	local ok_string  = "aaaa" .. hex(0xc3, 0x86) .. "aaaa" -- Æ
	ok, ret = errTest.okErrExpectPass(utf8Tools.getUCString, ok_string, 5); print(ok, ret)

	local bad_string = "aaaa" .. hex(0xc3, 0x0) .. "aaaa"
	ok, ret = errTest.okErrExpectFail(utf8Tools.getUCString, bad_string, 5); print(ok, ret)

	print("\n[+] Arg #1 acceptable use of Nul (\\0)")
	local ok_nul = "aaaa\000aaaa"
	ok, ret = errTest.okErrExpectPass(utf8Tools.getUCString, ok_nul, 5); print(ok, ret)

	print("\n[-] Arg #1 contains surrogate range code points")
	local surr = "a" .. hex(0xed, 0xa0, 0x80) .. "b"
	local ret1, ret2 = errTest.okErrExpectFail(utf8Tools.getUCString, surr, 2); print(i, ret1, ret2)
end


do
	print("\nTest: " .. errTest.register(utf8Tools.step, "utf8Tools.step"))

	local ok, res

	print("\n[-] arg #1 bad type")
	ok, ret = errTest.expectFail(utf8Tools.step, nil, 1)
	
	print("\n[-] arg #2 bad type")
	ok, ret = errTest.expectFail(utf8Tools.step, "foobar", nil)

	print("\n[-] arg #2 out of bounds")
	ok, ret = errTest.expectFail(utf8Tools.step, "foobar", 0)
	ok, ret = errTest.expectFail(utf8Tools.step, "foobar", #"foobar" + 2)

	print("\n[-] arg #2 not an integer")
	ok, ret = errTest.expectFail(utf8Tools.step, "foobar", 0.5)

	local test_str = "@Æㇹ𐅀"

	print("\n[ad hoc] Step through this test string: " .. test_str)

	local i = 1
	repeat
		print("utf8Tools.step()", i)
		i = utf8Tools.step(test_str, i + 1)
	until i > #test_str
end


do
	print("\nTest: " .. errTest.register(utf8Tools.check, "utf8Tools.check"))

	local ok, res

	print("\n[-] arg #1 bad type")
	ok, ret = errTest.expectFail(utf8Tools.check, nil)

	print("\n[ad hoc] expected behavior")
	print(utf8Tools.check("goodgoodgoodgoodgoodb" .. hex(0xf0, 0x80, 0xe0) .. "d (should return true, 22)"))
	print(utf8Tools.check("Should return nil"))
end

do
	print("\nTest: " .. errTest.register(utf8Tools.ucStringToCodePoint, "utf8Tools.ucStringToCodePoint"))

	local ok, res

	print("\n[-] arg #1 bad type")
	ok, ret = errTest.expectFail(utf8Tools.ucStringToCodePoint, nil)

	print("\n[-] arg #1 string too short")
	ok, ret = errTest.expectFail(utf8Tools.ucStringToCodePoint, "", 1)

	print("\n[-] arg #2 bad type")
	ok, ret = errTest.expectFail(utf8Tools.ucStringToCodePoint, "12345", false)

	print("\n[-] arg #2 too low")
	ok, ret = errTest.expectFail(utf8Tools.ucStringToCodePoint, "12345", 0)

	print("\n[-] arg #2 too high")
	ok, ret = errTest.expectFail(utf8Tools.ucStringToCodePoint, "12345", 99)

	print("\n[-] arg #2 not an integer")
	ok, ret = errTest.expectFail(utf8Tools.ucStringToCodePoint, "12345", 0.333)

	print("\n[ad hoc] Expected behavior.")
	local good_point = utf8Tools.ucStringToCodePoint("Æ", 1)
	print("good_point", good_point)
	local ok, err = utf8Tools.codePointToUCString(good_point)
	print("ok, err", ok, err)
	if err then
		error("Expected passing ad hoc test failed")
	end

	print("\n[ad hoc] Pass in bad data.")
	local bad_point, bad_err = utf8Tools.ucStringToCodePoint(hex(0xf0, 0x80, 0xe0), 1)
	print(bad_point, bad_err)
end


do
	print("\nTest: " .. errTest.register(utf8Tools.codePointToUCString, "utf8Tools.codePointToUCString"))

	local ok, res

	print("\n[-] arg #1 bad type")
	ok, res = errTest.expectFail(utf8Tools.codePointToUCString, nil)

	print("\n[ad hoc]: invalid negative code point")
	ok, res = utf8Tools.codePointToUCString(-11111)
	print(ok, res)

	print("\n[ad hoc]: overlarge code point")
	ok, res = utf8Tools.codePointToUCString(2^32)
	print(ok, res)
	
	print("\n[ad hoc] expected behavior")
	print(utf8Tools.codePointToUCString(33)) -- !
	print(utf8Tools.codePointToUCString(198)) -- Æ
	print(utf8Tools.codePointToUCString(12793)) -- ㇹ

	print("?", utf8Tools.codePointToUCString(0xfffd))
	print("\n[ad hoc] arg #1 bad input: obscenely large number. What happens?")
	print(utf8Tools.codePointToUCString(2^53))
end

