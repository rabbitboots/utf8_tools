--[[
utf8Tools.check() / utf8Tools.checkAlt() + LÖVE UTF-8 encoding tester.

Checks some known good and bad strings. If utf8Tools.check() or utf8Tools.checkAlt() pass a string that LÖVE rejects, the test is
considered a failure. The first results of check() and checkAlt() must also agree.

Output is printed to the console. If all goes well, the program automatically terminates.
--]]


love.window.setTitle("utf8Tools.check + LÖVE test")


local utf8 = require("utf8")


local utf8Tools = require("utf8_tools")


local font = love.graphics.newFont(16)


local function hexString(str)

	local out = ""
	for i = 1, #str do
		local byte = string.byte(str, i)
		out = out .. string.format("%x", byte)
		if i < #str then
			out = out .. " "
		end
	end

	return out
end


local function testString(str)

	print("Test String: " .. hexString(str))

	local font_getWidth = font.getWidth
	local love_ok, love_err = pcall(font_getWidth, font, str)

	local uc_ok, uc_err, uc_pos = utf8Tools.check(str)
	local uc_ok2, uc_err2, uc_pos2 = utf8Tools.checkAlt(str)

	if not love_ok then
		print("\tLÖVE error: " .. love_err)
	end

	if not uc_ok then
		print("\tUC error: " .. uc_pos or "...", uc_err)
	end

	if not uc_ok2 then
		print("\tUC2 error: " .. uc_pos2 or "...", uc_err2)
	end

	if uc_ok ~= uc_ok2 then
		error("disagreement in the results of utf8Tools.check() and utf8Tools.checkAlt()")
	end

	-- NOTE: error strings from utf8Tools.check() and utf8Tools.checkAlt() are not identical.

	if not love_ok and uc_ok then
		error("utf8Tools.check passed a string that LÖVE rejected")
	end
end


local sc = string.char

print("\n[OK] Empty string.")
testString("")

print("\n[OK] Nul byte string.")
testString(sc(0x0))

print("\n[OK] ASCII string.")
testString("foobar")

print("\n[ERR] (0x80-0xbf) are continuation bytes.")
testString(sc(0x80))
testString(sc(0xbf))

print("\n[ERR] Invalid octets which should never appear in a UTF-8 string.")
testString(sc(0xc0))
testString(sc(0xc1))
testString(sc(0xf5))
testString(sc(0xf6))
testString(sc(0xf7))
testString(sc(0xf8))
testString(sc(0xf9))
testString(sc(0xfa))
testString(sc(0xfb))
testString(sc(0xfc))
testString(sc(0xfd))
testString(sc(0xfe))
testString(sc(0xff))

print("\n[OK] Multi-byte characters: ö, ㇱ, 𐅀")
testString(sc(0xc3, 0xb6)) -- ö
testString(sc(0xe3, 0x87, 0xb1)) -- "ㇱ"
testString(sc(0xf0, 0x90, 0x85, 0x80)) -- "𐅀"

print("\n[ERR] Multi-byte characters are too short.")
testString(sc(0xc3))
testString(sc(0xe3))
testString(sc(0xe3, 0x87))
testString(sc(0xf0))
testString(sc(0xf0, 0x90))
testString(sc(0xf0, 0x90, 0x85))

print("\n[ERR] Bad 'following' values in multi-byte slots.")
testString(sc(0xc3, 0x79)) -- 2/2 low
testString(sc(0xc3, 0xc2)) -- 2/2 high

testString(sc(0xe3, 0x79, 0xb1)) -- 2/3 low
testString(sc(0xe3, 0xc2, 0xb1)) -- 2/3 high
testString(sc(0xe3, 0x87, 0x79)) -- 3/3 low
testString(sc(0xe3, 0x87, 0xc2)) -- 3/3 high

testString(sc(0xf0, 0x79, 0x85, 0x80)) -- 2/4 low
testString(sc(0xf0, 0xc2, 0x85, 0x80)) -- 2/4 high
testString(sc(0xf0, 0x90, 0x79, 0x80)) -- 3/4 low
testString(sc(0xf0, 0x90, 0xc2, 0x80)) -- 3/4 high
testString(sc(0xf0, 0x90, 0x85, 0x79)) -- 4/4 low
testString(sc(0xf0, 0x90, 0x85, 0xc2)) -- 4/4 high

print("\n[ERR] Surrogate range values (0xd800 - 0xdfff).")
testString("a" .. sc(0xed, 0xa0, 0x80) .. "b")

print("\n[ERR] Code point is too large.")
testString(sc(0xf4, 0xbf, 0xbf, 0xbf))

print("\n[OK] String with mixed byte-length characters (a, ö, ㇱ, 𐅀).")
testString("aöㇱ𐅀aaööㇱㇱ𐅀𐅀aaaöööㇱㇱㇱ𐅀𐅀𐅀")

print("\nAll tests passed.\n")

love.event.quit()
