# utf8Tools

Some UTF-8 utility functions for Lua.


## Supported Versions

* Tested on Lua 5.4.4, LuaJIT 2.1.0-beta3, and the LÖVE 11.4 Appimage (ebe628e).

* Will not work as-is with Lua 5.1, due to it having different search pattern escape codes.


## Terms

* Code point: A unicode "character". In this module, code points are stored as number values.

* Code unit: A UTF-8 encoded representation of a unicode code point, 1-4 bytes in size. In this module, individual code units are stored as strings.


## Public Functions

* `utf8Tools.getCodeUnit(str, pos)`: Get a UTF-8 code unit from `str` starting at byte-index `pos`. Returns the code unit in string form, or `nil` plus an error string if unsuccessful.

* `utf8Tools.step(str, pos)`: Searches `str` starting at `pos` for a byte which resembles the first octet of a UTF-8 code unit, returning the byte index if successful. Will return `nil` if it reaches the end of the string with no match. Does not validate the bytes between `pos` and the final index.

* `utf8Tools.invalidByteCheck(str)`: Checks if `str` contains at least one of a set of bytes which are invalid in UTF-8. Upon the first successful result, returns the index and bad byte. Returns `nil` if no bad bytes were found. Note that an absence of bad bytes does not necessarily mean that the text is valid UTF-8.

* `utf8Tools.hasMalformedCodeUnits(str)`: Checks `str` for malformed UTF-8 code units (forbidden bytes, code points in the surrogate range, and mismatches between length marker and number of bytes.) This is affected by the options `match_exclude` and `check_surrogates`, and both must be true for all checks to be performed.

* `utf8Tools.u8UnitToCodePoint(unit_str)`: Tries to convert a UTF-8 code unit in string form to a numeric Unicode code point. Returns either a number, or a number plus an error string. If the former, the module thinks this is a good code point. If the latter, the number is likely bad data, and the error string describes what went wrong in the conversion attempt. The caller is responsible for checking this, and deciding whether to move forward with the bad data or to discard it.

* `utf8Tools.u8CodePointToUnit(code_point_num)`: Tries to convert a Unicode code point in numeric form to a UTF-8 code unit string. Returns either a code unit string, or a code unit string plus an error string. Like with `u8UnitToCodePoint()`, the presence of a second return value means there was a problem in the conversion and the code unit is bad.


## Options

Only set these to false if you are confident that the incoming UTF-8 strings are valid, or if you have special requirements.

`utf8Tools.options.check_surrogates`: *(true)* Functions will check the Unicode surrogate range. Code points in this range are forbidden by the spec, but some decoders allow them through.

`options.match_exclude`: *(true)* Functions will exclude certain bytes that are forbidden by the spec when calling `getCodeUnit()`.


## Notes

* Should work with strict.lua active.

