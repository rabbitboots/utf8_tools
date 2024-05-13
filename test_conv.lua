local path = ... and (...):match("(.-)[^%.]+$") or ""

local strict = require(path .. "test.lib.strict")

local utf8Conv = require(path .. "utf8_conv")
local utf8Tools = require(path .. "utf8_tools")

local errTest = require(path .. "test.lib.err_test")
local hexStrCore = require(path .. "test.lib.util.hexstr_core")


-- (This is only here because Lua 5.1 does not have the '\xff' hex literal escapes for strings.)
local hex = string.char


local function readFile(path)

	local file = io.open(path, "rb")
	if not file then
		error("failed to open file: " .. path)
	end

	local str = file:read("a") -- 5.1 needs "*a" I think
	if not str then
		error("unable to read file contents: " .. path)
	end

	file:close()
	return str
end


-- Latin 1
do
	print("\nTest: " .. errTest.register(utf8Conv.utf8_latin1, "utf8Conv.utf8_latin1"))

	local ok, res

	print("\n[-] arg #1 bad type")
	errTest.expectFail(utf8Conv.utf8_latin1, nil)

	print("\n[+] arg #1 empty string")

	print("\n[ad hoc] arg #1 has code points that are unsupported in Latin 1, and we didn't provide a stand-in string.")
	print(utf8Conv.utf8_latin1("a灷b灷c灷"))
	print("")

	print("\n[ad hoc] ...and with a stand-in string (\"?\"):")
	print(utf8Conv.utf8_latin1("a灷b灷c灷", "?"))
	print("")

	ok, res = errTest.okErrExpectPass(utf8Conv.utf8_latin1, ""); print("Should be an empty string -> |" .. ok .. "|")

	local sample1 = [[abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ LÖVE !@~ ¡Æø]]

	print("\n[+] general UTF-8 to Latin 1 test.")
	ok, res = errTest.okErrExpectPass(utf8Conv.utf8_latin1, sample1); print(sample1); print(ok);
	local to_latin1 = ok

	print("\nTest: " .. errTest.register(utf8Conv.latin1_utf8, "utf8Conv.latin1_utf8"))

	print("\n[-] arg #1 bad type")
	errTest.expectFail(utf8Conv.latin1_utf8, nil)

	print("\n[+] convert the previous Latin 1 output back to UTF-8.")
	ok, res = errTest.okErrExpectPass(utf8Conv.latin1_utf8, to_latin1); print(to_latin1); print(ok);

	print("\n[ad hoc] This function won't fail on any Lua string you give it, even if the input is garbage, because bytes 0-255 all correspond to valid code points.")
	local str0_255 = ""
	for i = 0, 255 do
		str0_255 = str0_255 .. string.char(i)
	end
	local test_all_bytes = utf8Conv.latin1_utf8(str0_255)
	print("(we won't print the results by default here because they mess up the appearance of the following test output.)\n")
	--print(test_all_bytes)
end


local function testStringConversion(str_comp, func, ...)

	local str, i, err = func(...)
	if not str then
		error("string conversion test failed: byte #" .. i .. ", message: " .. err)
	end
	print("(comp vs output):")
	hexStrCore.encodePrint(str_comp, true)
	print("---")
	hexStrCore.encodePrint(str, true)
	print("---")

	if str ~= str_comp then
		error("mismatch between converted string and comparison string.")
	end

	print("String comparison passed.")
end


-- UTF-16
do
	local ok, res

	-- We will use this string to test the Unicode conversions: lÖvE𐅀𐅁𐅅􏿿
	-- When encoded as UTF-16, it has a mix of single integers and surrogate pairs.

	local test_str_utf8 = "lÖvE𐅀𐅁𐅅􏿿"
	local test_str_utf16le = string.char(
		0x6C, 0x00, 0xD6, 0x00, 0x76, 0x00, 0x45, 0x00,
		0x00, 0xD8, 0x40, 0xDD, 0x00, 0xD8, 0x41, 0xDD,
		0x00, 0xD8, 0x45, 0xDD, 0xFF, 0xDB, 0xFF, 0xDF
	)
	local test_str_utf16be = string.char(
		0x00, 0x6C, 0x00, 0xD6, 0x00, 0x76, 0x00, 0x45,
		0xD8, 0x00, 0xDD, 0x40, 0xD8, 0x00, 0xDD, 0x41,
		0xD8, 0x00, 0xDD, 0x45, 0xDB, 0xFF, 0xDF, 0xFF
	)


	print("\nTest: " .. errTest.register(utf8Conv.utf16_utf8, "utf8Conv.utf16_utf8"))
	print("\n[-] arg #1 bad type")
	errTest.expectFail(utf8Conv.utf16_utf8, nil)

	print("\n(Don't bother type-checking arg #2 (big_endian).)")

	-- Using variations of: ff db ff df (UTF-16LE for U+10FFFF, the highest valid code point)

	print("\n[ad hoc] String is too short to hold any valid UTF-16 data.")
	print(utf8Conv.utf16_utf8(string.char(0x00)))

	print("\n[ad hoc] first integer of a surrogate pair is out of range (greater than 0xdbff).")
	print(utf8Conv.utf16_utf8(string.char(0xff, 0xff, 0x00, 0xdc)))

	print("\n[ad hoc] input string is too short for a surrogate pair.")
	print(utf8Conv.utf16_utf8(string.char(0xff, 0xdb), false))

	print("\n[ad hoc] second integer of a surrogate pair is out of range (0xdc00 - 0xdfff).")
	print(utf8Conv.utf16_utf8(string.char(0xff, 0xdb, 0xff, 0xff)))

	print("\n[ad hoc] Convert test string from UTF-16LE to UTF-8.")
	testStringConversion(test_str_utf8, utf8Conv.utf16_utf8, test_str_utf16le, false)

	print("\n[ad hoc] Convert test string from UTF-16BE to UTF-8.")
	testStringConversion(test_str_utf8, utf8Conv.utf16_utf8, test_str_utf16be, true)


	print("\nTest: " .. errTest.register(utf8Conv.utf8_utf16, "utf8Conv.utf8_utf16"))

	print("\n[-] arg #1 bad type")
	errTest.expectFail(utf8Conv.utf8_utf16, nil)

	print("\n(Don't bother type-checking arg #2 (big_endian).)")

	print("\n[ad hoc] Bad input UTF-8.")
	print(utf8Conv.utf8_utf16(string.char(0xff)))

	print("\n[ad hoc] Convert test string from UTF-8 to UTF-16LE.")
	testStringConversion(test_str_utf16le, utf8Conv.utf8_utf16, test_str_utf8, false)

	print("\n[ad hoc] Convert test string from UTF-8 to UTF-16BE.")
	testStringConversion(test_str_utf16be, utf8Conv.utf8_utf16, test_str_utf8, true)
end

