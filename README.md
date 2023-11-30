**Version:** 1.2.2.

# utf8Tools

Some UTF-8 utility functions for Lua.

Tested with Lua 5.1.5, Lua 5.2.4, Lua 5.3.6, Lua 5.4.4 and LuaJIT 2.1.0-beta3 on Fedora 38.


# Public Functions

## utf8Tools.getUCString

Gets a UTF-8 sequence from a string.

`local u8_seq = utf8Tools.getUCString(str, pos)`

* `str`: The string to read.

* `pos`: The start index of the UTF-8 sequence.

**Returns:** The UTF-8 sequence as a string, or `nil` plus error string if unsuccessful.


## utf8Tools.step

Searches for a UTF-8 start octet in a string. A properly encoded UTF-8 string is expected, and the function does not perform any validation.

`local index = utf8Tools.stepNext(str, pos)`

* `str`: The string to search.

* `pos`: The first byte index to check. Can be from `1` to `#str + 1`.

**Returns:** Index of the next starting octet, or `nil` if the end of the string is reached.


## utf8Tools.check

Checks a string for UTF-8 encoding problems and bad code point values.

`local ok, err = utf8Tools.check(str, [i], [j])`

* `str`: The string to check.

* `i`: *(1)* The first byte index.

* `j`: *(#str)* The last byte index.

**Returns:** `true` if no problems found. Otherwise, `false`, position, and error string.


## utf8Tools.ucStringToCodePoint

Tries to convert a UTF-8 sequence within a string to a numeric code point.

`local code_point, err = utf8Tools.ucStringToCodePoint(str, pos)`

* `str`: String containing the UTF-8 sequence to convert.

* `pos`: Starting position in the string to check.

**Returns:** The code point in number form and its size as a UTF-8 sequence, or `nil` and an error string if a problem was detected.


## utf8Tools.codePointToUCString

Tries to convert a code point in numeric form to a UTF-8 sequence string.

`local u8_seq, err = utf8Tools.codePointToUCString(code)`

* `code`: The code point to convert. Must be an integer.

**Returns:** the UTF-8 sequence in string form, or `nil` and an error string if there was a problem validating the UTF-8 sequence.


## Options

These should be set to `true` unless you have special requirements.

`utf8Tools.options.check_surrogates`: *(true)* Functions will check the Unicode surrogate range. Code points in this range are forbidden by the UTF-8 spec, but some decoders allow them through.

`options.exclude_invalid_octets`: *(true)* Functions will exclude UTF-8 sequences with bytes that are forbidden by the spec.


