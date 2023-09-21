**Version:** 1.1.0. See CHANGELOG.md for API-breaking changes from 1.0.0.

# utf8Tools

Some UTF-8 utility functions for Lua.


# Supported Versions

* Tested with Lua 5.2.4, Lua 5.3.6, Lua 5.4.4 and LuaJIT 2.1.0-beta3 on Fedora 38.

* Will not work as-is with Lua 5.1, due to an incompatibility with its search pattern escape codes.


# Public Functions

## utf8Tools.getUCString

Gets a UTF-8 sequence from a string.

`local u8_seq = utf8Tools.getUCString(str, pos)`

* `str`: The string to read.

* `pos`: The byte position to begin reading from.

**Returns:** The UTF-8 sequence in string form, or `nil` plus error string if unsuccessful.


## utf8Tools.step

Searches `str` for a starting octet, beginning at (and including the byte at) `pos`. A properly encoded UTF-8 string is expected. Does not validate the bytes between `pos` and the returned index.

`local index = utf8Tools.stepNext(str, pos)`

* `str`: The string to search.

* `pos`: The first byte index to check.

**Returns:** Index of the next starting octet, or `nil` if the end of the string is reached.


## utf8Tools.invalidByteCheck

Checks a string for bytes which are invalid in UTF-8.

`local pos, byte = utf8Tools.invalidByteCheck(str)`

* `str`: The string to search.

**Returns:** `nil` if no bad bytes were found, or the index and value of the first instance of an invalid byte. Note that an absence of bad bytes does not necessarily mean that the string is valid UTF-8.


## utf8Tools.hasMalformedUCStrings

Checks a string for malformed UTF-8 sequences: forbidden bytes, code points in the surrogate range, and mismatches between length marker and number of bytes. This is affected by the options `match_exclude` and `check_surrogates`, and both must be true for all checks to be performed.

`local bad_pos, err = utf8Tools.hasMalformedUCStrings(str)`

* `str`: The string to check.

**Returns:** `nil` if no issues were found, or the byte index where the function failed and an error string.


## utf8Tools.ucStringToCodePoint

Tries to convert a UTF-8 sequence in string form to a numeric code point.

`local code_point, err = utf8Tools.ucStringToCodePoint(u_str)`

* `u_str`: The UTF-8 sequence (string) to convert.

**Returns:** On success: the code point number. On failure: a number plus an error string. If the latter, the number is likely bad data, and the error string describes what went wrong in the conversion attempt. The caller is responsible for checking this, and deciding whether to move forward with the bad data or to discard it.


## utf8Tools.codePointToUCString

Tries to convert a code point in numeric form to a UTF-8 sequence string.

`local u8_seq, err = utf8Tools.codePointToUCString(code_point_num)`

* `code_point_num`: The code point number.

**Returns:** On success: A UTF-8 sequence string. On failure: a string plus an error string. Like with `ucStringToCodePoint()`, the presence of a second return value means there was a problem in the conversion, and the returned string is likely bad.


## Options

These should be set to `true` unless you have special requirements.

`utf8Tools.options.check_surrogates`: *(true)* Functions will check the Unicode surrogate range. Code points in this range are forbidden by the UTF-8 spec, but some decoders allow them through.

`options.match_exclude`: *(true)* Functions will exclude certain bytes that are forbidden by the spec when calling `getUCString()`.


## Notes

* Should work with *strict.lua* active.

