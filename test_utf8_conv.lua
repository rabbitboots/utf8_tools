local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local strict = require(REQ_PATH .. "test.strict")


local errTest = require(REQ_PATH .. "test.err_test")
local utf8Conv = require(REQ_PATH .. "utf8_conv")
local utf8Tools = require(REQ_PATH .. "utf8_tools")


-- (This is only here because Lua 5.1 does not have the '\xff' hex literal escapes for strings.)
local hex = string.char


local cli_verbosity
for i = 0, #arg do
	if arg[i] == "--verbosity" then
		cli_verbosity = tonumber(arg[i + 1])
		if not cli_verbosity then
			error("invalid verbosity value")
		end
	end
end


local self = errTest.new("utf8Conv", cli_verbosity)


-- Latin 1 test string
local sample1_utf8 = "abc ABC ÖÆø"
local sample1_latin1 = string.char(
	0x61, 0x62, 0x63, 0x20,
	0x41, 0x42, 0x43, 0x20,
	0xd6, 0xc6, 0xf8
)


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


-- [===[
self:registerFunction("utf8Conv.utf8_latin1", utf8Conv.utf8_latin1)

self:registerJob("utf8Conv.utf8_latin1", function(self)
	self:expectLuaError("arg #1 bad type", utf8Conv.utf8_latin1, nil)

	do
		self:print(3, "[+] arg #1 empty string")
		local ok, err, err_i = utf8Conv.utf8_latin1("")
		self:print(4, ok, err, err_i)
		self:isEqual(ok, "")
		self:lf(4)
	end

	do
		self:print(3, "[-] arg #1 has code points that are unsupported in Latin 1, and we didn't provide a stand-in string.")
		local ok, err, err_i = utf8Conv.utf8_latin1("a灷b灷c灷")
		self:print(4, ok, err, err_i)
		self:isEvalFalse(ok)
		self:lf(4)
	end

	do
		self:print(3, "\n[+] arg #1 with a stand-in string (\"?\"):")
		local ok, err, err_i = utf8Conv.utf8_latin1("a灷b灷c灷", "?")
		self:print(4, ok, err, err_i)
		self:isType(ok, "string")
		self:lf(4)
	end

	do
		self:print(3, "[+] general UTF-8 to Latin 1 test.")
		local ok, err, err_i = utf8Conv.utf8_latin1(sample1_utf8)
		self:print(4, ok, err, err_i)
		self:isEqual(ok, sample1_latin1)
		self:lf(4)
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Conv.latin1_utf8", utf8Conv.latin1_utf8)

self:registerJob("utf8Conv.latin1_utf8", function(self)
	self:expectLuaError("arg #1 bad type", utf8Conv.latin1_utf8, nil)

	do
		self:print(3, "[+] convert Latin 1 to UTF-8")
		local ok, err, err_i = utf8Conv.latin1_utf8(sample1_latin1)
		self:print(4, ok, err, err_i)
		self:isEqual(ok, sample1_utf8)
		self:lf(4)

		-- NOTE: latin1_utf8 won't fail on any Lua string, even if the input is garbage, because bytes 0-255 all correspond to valid code points.
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Conv.utf16_utf8", utf8Conv.utf16_utf8)

self:registerJob("utf8Conv.utf16_utf8", function(self)
	self:expectLuaError("arg #1 bad type", utf8Conv.utf16_utf8, nil)
	-- (Don't bother type-checking arg #2 (big_endian)

	-- Using variations of: 0xff 0xdb 0xff 0xdf (UTF-16LE for U+10FFFF, the highest valid code point)

	do
		self:print(3, "[-] String is too short to hold any valid UTF-16 data.")
		local ok, err, err_i = utf8Conv.utf16_utf8(string.char(0x00))
		self:print(4, ok, err, err_i)
		self:isEvalFalse(ok)
		self:lf(4)
	end

	do
		self:print(3, "[+] Empty string in -> empty string out.")
		local ok, err, err_i = utf8Conv.utf16_utf8("")
		self:print(4, ok, err, err_i)
		self:isEqual(ok, "")
		self:lf(4)
	end

	do
		self:print(3, "[-] first integer of a surrogate pair is out of range (greater than 0xdbff)")
		local ok, err, err_i = utf8Conv.utf16_utf8(string.char(0xff, 0xff, 0x00, 0xdc))
		self:print(4, ok, err, err_i)
		self:isEvalFalse(ok)
		self:lf(4)
	end

	do
		self:print(3, "[-] input string is too short for a surrogate pair.")
		local ok, err, err_i = utf8Conv.utf16_utf8(string.char(0xff, 0xdb), false)
		self:print(4, ok, err, err_i)
		self:isEvalFalse(ok)
		self:lf(4)
	end

	do
		self:print(3, "[-] second integer of a surrogate pair is out of range (0xdc00 - 0xdfff).")
		local ok, err, err_i = utf8Conv.utf16_utf8(string.char(0xff, 0xdb, 0xff, 0xff))
		self:print(4, ok, err, err_i)
		self:isEvalFalse(ok)
		self:lf(4)
	end

	do
		self:print(3, "[+] Convert test string from UTF-16LE to UTF-8.")
		local ok, err, err_i = utf8Conv.utf16_utf8(test_str_utf16le, false)
		self:print(4, ok, err, err_i)
		self:isEqual(ok, test_str_utf8)
		self:lf(4)
	end

	do
		self:print(3, "[+] Convert test string from UTF-16BE to UTF-8.")
		local ok, err, err_i = utf8Conv.utf16_utf8(test_str_utf16be, true)
		self:print(4, ok, err, err_i)
		self:isEqual(ok, test_str_utf8)
		self:lf(4)
	end

	do
		self:print(3, "[-] Convert test string, but mix up the UTF-16 endianness.")
		local ok, err, err_i = utf8Conv.utf16_utf8(test_str_utf16le, true)
		self:print(4, ok, err, err_i)
		self:isNotEqual(ok, test_str_utf8)
		self:lf(4)
	end
end
)
--]===]


-- [===[
self:registerFunction("utf8Conv.utf8_utf16", utf8Conv.utf8_utf16)

self:registerJob("utf8Conv.utf8_utf16", function(self)
	self:expectLuaError("arg #1 bad type", utf8Conv.utf8_utf16, nil)
	-- Don't bother type-checking arg #2 (big_endian).

	do
		self:print(3, "[-] Bad input UTF-8.")
		local ok, err, err_i = utf8Conv.utf8_utf16(string.char(0xff))
		self:print(4, ok, err, err_i)
		self:isEvalFalse(ok)
		self:lf(4)
	end

	-- These are cut short when printing in Lua 5.1.
	-- Maybe the MSB zero bytes are being treated as Nul?
	-- The equality checks against still pass, though, and the string lengths are the expected numbers...
	do
		self:print(3, "[+] Convert from UTF-8 to UTF-16LE.")
		local ok, err, err_i = utf8Conv.utf8_utf16(test_str_utf8, false)
		self:print(4, ok, err, err_i)
		self:isEqual(ok, test_str_utf16le)
		self:isEqual(#ok, #test_str_utf16le)
		self:lf(4)
	end

	do
		self:print(3, "[+] Convert from UTF-8 to UTF-16BE.")
		local ok, err, err_i = utf8Conv.utf8_utf16(test_str_utf8, true)
		self:print(4, ok, err, err_i)
		self:isEqual(ok, test_str_utf16be)
		self:isEqual(#ok, #test_str_utf16be)
		self:lf(4)
	end
end
)
--]===]


self:runJobs()
