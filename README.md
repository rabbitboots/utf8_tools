**Version:** 1.2.3

# utf8Tools

Some UTF-8 utility functions for Lua.

Tested with Lua 5.1.5, Lua 5.2.4, Lua 5.3.6, Lua 5.4.6 and LuaJIT 2.1.1707061634 on Fedora 39, and LuaJIT 2.1.0-beta3 on Windows 10.


## Files

* `utf8_tools.lua`: The main file.

* `utf8_conv.lua`: Additional functions for converting UTF-16 and ISO 8859-1 (Latin-1) to UTF-8.


## Terminology

**UCString**: A UTF-8 Sequence; a single Unicode Code Point, encoded in UTF-8 and stored in a Lua string. `"A"`

**Code Point**: a Unicode Code Point, stored as a Lua number, like `65` (for A).

**UTF-8 start octet**: The first byte in a UTF-8 Sequence, which indicates the length of the sequence (one to four bytes).


# utf8Tools API

## utf8Tools.getUCString

Gets a UTF-8 Sequence from a string.

`local u8_seq = utf8Tools.getUCString(str, pos)`

* `str`: The string to read.

* `pos`: The start index of the UTF-8 Sequence.

**Returns:** The UTF-8 Sequence as a string, or `nil` plus error string if unsuccessful.


## utf8Tools.step

Searches the string for a UTF-8 start octet. If no start octet is found, it returns one after the final byte position `(#str + 1)`.

`local index = utf8Tools.step(str, pos)`

* `str`: The string to search.

* `pos`: The first byte index to check. Can be from `1` to `#str + 1`.

**Returns:** Index of the next start octet, or `#str + 1` if the end of the string is reached.

**Notes:**

* This function does not validate the string's encoding.


## utf8Tools.check

Checks a string for UTF-8 encoding problems and bad code point values.

`local ok, err = utf8Tools.check(str, [i], [j])`

* `str`: The string to check.

* `[i]`: *(1)* The first byte index.

* `[j]`: *(#str)* The last byte index. Cannot be lower than `i`.

**Returns:** `true` if no problems found. Otherwise, `false`, position, and error string.


## utf8Tools.ucStringToCodePoint

Converts a UTF-8 Sequence within a string to a numeric code point.

`local code_point, err = utf8Tools.ucStringToCodePoint(str, pos)`

* `str`: String containing the UTF-8 Sequence to convert.

* `pos`: Starting position in the string to check.

**Returns:** The code point in number form and its size as a UTF-8 Sequence, or `nil` and an error string if a problem was detected.


## utf8Tools.codePointToUCString

Converts a code point in numeric form to a UTF-8 Sequence string.

`local u8_seq, err = utf8Tools.codePointToUCString(code)`

* `code`: The code point to convert. Must be an integer.

**Returns:** the UTF-8 Sequence in string form, or `nil` and an error string if there was a problem validating the UTF-8 Sequence.



## utf8Tools Options

These should be set to `true` unless you have special requirements.

`utf8Tools.options.check_surrogates`: *(true)* Functions will check the Unicode surrogate range. Code points in this range are forbidden by the UTF-8 spec, but some decoders allow them through.

`options.exclude_invalid_octets`: *(true)* Functions will exclude UTF-8 Sequences with bytes that are forbidden by the spec.


# utf8Conv API


## utf8Conv.latin1_utf8

Converts a Latin 1 (ISO 8859-1) string to UTF-8.

`utf8Conv.latin1_utf8(str)`

* `str`: The Latin 1 string to convert.

**Returns:** The converted UTF-8 string, or `nil` and an error string if there was a problem.


## utf8Conv.utf8_latin1

Converts a UTF-8 string to Latin 1 (ISO 8859-1). Note that only code points 0 through 255 can be directly mapped to a Latin 1 string.

`utf8Conv.utf8_latin1(str, [unmappable])`

* `str`: The UTF-8 string to convert.

* `[unmappable]`: Controls what happens when unmappable code points are encountered (anything above U+00FF). When `unmappable` is a string, it is used in place of the unmappable code point. (Pass in an empty string to ignore unmappable code points.) When `unmappable` is any other type, the function returns `nil`, the byte where the unmappable code point was encountered, and an error string.

**Returns:** The converted Latin 1 string, or `nil`, byte index, and an error string if there was a problem.


## utf8Tools.utf16_utf8

Converts a UTF-16 string to UTF-8.

`utf8Conv.utf16_utf8(str, [big_endian])`

* `str`: The UTF-16 string to convert.

* `[big_endian]`: *(nil)* `true` if the input UTF-16 string is big-endian, `false/nil` if it is little-endian.

**Returns:** The converted UTF-8 string, or `nil`, byte index, and an error string if there was a problem.


## utf8Conv.utf8_utf16

Converts a UTF-8 string to UTF-16.

`utf8Conv.utf8_utf16(str, [big_endian])`

* `str`: The UTF-8 string to convert.

* `[big_endian]`: *(nil)* `true` if the converted UTF-16 string is big-endian, `false/nil` if it is little-endian.

**Returns:** The converted UTF-16 string, or `nil`, byte index, and an error string if there was a problem.


# References

* [UTF-8 RFC 3629](https://tools.ietf.org/html/rfc3629)

* [UTF-16 RFC 2781](https://www.rfc-editor.org/rfc/rfc2781)

* [Wikipedia: Unicode](https://en.wikipedia.org/wiki/Unicode)

* [Wikipedia: UTF-8](https://en.wikipedia.org/wiki/UTF-8)


# License (MIT)

Copyright (c) 2022 - 2024 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
