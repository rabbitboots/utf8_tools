# utf8Tools Changelog

# v1.2.3 (20 May 2024)

**NOTE:** This is an API-breaking update.

* `utf8Tools.step()` used to return `nil` if 1) the string was empty, 2) the position was one past the end of the string, or 3) no start octet was found from the initial position through to the end. It will now return `#str + 1` in all of these cases. This change simplifies usage in *while* loops.

* Added `utf8_conv.lua`, which provides a few supplemental text encoding conversion functions:
  * `utf8Conv.latin1_utf8()`
  * `utf8Conv.utf8_latin1()`
  * `utf8Conv.utf16_utf8()`
  * `utf8Conv.utf8_utf16()`

* Added `test_conv.lua` to test *utf8Conv* functions.

* Fixed an accidental global variable declaration in `test_utf8.lua`.

* Fixed a documentation error in the example for `utf8Tools.step()`.


## Upgrade Guide From v1.2.2 to v1.2.3

* Check usage of `utf8Tools.step()`, as it no longer returns `nil` in cases where a start octet is not found.


# v1.2.2 (30 Nov 2023)

* Changed `utf8Tools.step(str, pos)` to accept `pos` values that are one byte-index greater than `#str`.

* Fixed `utf8Tools.check()` crashing on empty strings.

* Rewrote the LÖVE test (`main.lua`), as it took significantly longer to complete in the dev version of LÖVE 12.0 than it did in 11.4. Instead of testing all combinations of 0-4 byte strings, it now just tests a few known good and bad strings.

* Minor source code style changes. All hex literals (like `0xc0`) are now in lower case.


# v1.2.1 (14 Nov 2023)

* Added first, last byte index parameters to `utf8Check.check()`.

* `_getCodePointFromString()`: removed an unnecessary call to `math.min()` within a call to `string.byte()`.


# v1.2.0 (23 Sept 2023)

**NOTE:** This is an API-breaking update.

* Removed the search string patterns, and rewrote functions that relied on them to use `string.byte()` instead.

* Merged `utf8Tools.invalidByteCheck()` and `utf8Tools.hasMalformedUCStrings()` into `utf8Tools.check()`.

* `utf8Tools.ucStringToCodePoint` now takes a second argument, `pos`, and no longer limits `str` to 4 bytes max.

* Renamed `options.match_exclude` to `options.exclude_invalid_octets`. The option now applies to all invalid UTF-8 octet checks.

* Fixed `_codePointToBytes()` / `utf8Tools.codePointToUCString()` not handling code point U+10FFFF.

* Updated source code formatting style. Removed function comments that are already covered in the README.

* Changed title, version, license, etc., module strings to comments.


## Upgrade Guide From v1.1.0 to v1.2.0

* Replace any external references to the now-removed search string patterns. They are pasted below for reference:

```lua
utf8Tools.charpattern = "[%z\x01-\x7F\xC2-\xFD][\x80-\xBF]*"

utf8Tools.u8_oct_1 = "[%z\x01-\x7F\xC2-\xFD]"

utf8Tools.u8_ptn_t = {
	"^[%z\x01-\x7F]",
	"^[\xC0-\xDF][\x80-\xBF]",
	"^[\xE0-\xEF][\x80-\xBF][\x80-\xBF]",
	"^[\xF0-\xF7][\x80-\xBF][\x80-\xBF][\x80-\xBF]",
}

utf8Tools.u8_ptn_excl_t = {
	"^[%z\x01-\x7F]",
	"^[\xC2-\xDF][\x80-\xBF]",
	"^[\xE0-\xEF][\x80-\xBF][\x80-\xBF]",
	"^[\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF]",
}
```

* Update and adjust any calls to `utf8Tools.invalidByteCheck()` or `utf8Tools.hasMalformedUCStrings()` with `utf8Tools.check()`.

* Calls to `utf8Tools.ucStringToCodePoint` must now provide a second argument, `pos`.

* Update any external instances of `utf8Tools.options.match_exclude` to be `utf8Tools.options.exclude_invalid_octets`.


# v1.1.0 (19 Sept 2023)

**NOTE:** This is an API-breaking update.

* (#1) Fixed incorrect usage of the term *code unit* in source code and documentation. Renamed functions with the term `CodeUnit` to use `UCString` instead, where *UCString* refers to a single Unicode Code Point encoded in UTF-8 and stored as a Lua string. (*Code Unit* refers to the bytes in a code point encoded as UTF-8.) In some other cases (comments and error messages), *UTF-8 sequence* is used. See *Upgrade Guide From v1.0.0 to v1.1.0* for a list of affected public functions.

* `utf8Tools.step()` will return nil if the provided string is empty and the start position is 1.

* Updated and reformatted README.md. Minor updates to source comments.

* Started changelog.


## Upgrade Guide From v1.0.0 to v1.1.0

* Update any calls to these functions (they behave the same as before):
  * `utf8Tools.getCodeUnit(str, pos)` -> `utf8Tools.getUCString(str, pos)`
  * `utf8Tools.hasMalformedCodeUnits(str)` -> `utf8Tools.hasMalformedUCStrings(str)`
  * `utf8Tools.u8CodePointToUnit(code_point_num)` -> `utf8Tools.codePointToUCString(code_point_num)`
  * `utf8Tools.u8UnitToCodePoint(unit_str)` -> `utf8Tools.ucStringToCodePoint(u_str)`
