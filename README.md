**Version:** 1.3.0

# utf8Tools

UTF-8 utility functions for Lua.

Tested with Lua 5.1.5, Lua 5.2.4, Lua 5.3.6, Lua 5.4.6 and LuaJIT 2.1.1707061634 on Fedora 39, and Lua 5.1.5 on Windows 10.


## Files

* `utf8_tools.lua`: The main file.

* `utf8_conv.lua`: Auxiliary functions for converting UTF-16 and ISO 8859-1 (Latin-1) to UTF-8 and back.


## Terminology

**Code Point**: a Unicode Code Point, stored as a Lua number. `65` (for A)

**UTF-8 Sequence**: A single Unicode Code Point, encoded in UTF-8 and stored as a Lua string. `"A"`

**Start Byte**: The first byte in a UTF-8 Sequence. The length of the sequence is encoded in the start byte.

**Continuation Byte**: The second, third or fourth byte in a UTF-8 Sequence. A UTF-8 Sequence may not be longer than 4 bytes.


# utf8Tools

## utf8Tools Options

`utf8Tools.options.check_surrogates`: *(true)* Functions will check the Unicode surrogate range. Code points in this range are forbidden by the UTF-8 spec, but some decoders allow them through.


## utf8Tools API

### utf8Tools.check

Checks a UTF-8 string for encoding problems and invalid code points.

`local ok, err, byte = utf8Tools.check(s, [i], [j])`

* `s`: The string to check.

* `[i]`: *(empty string: 0; non-empty string: 1)* The first byte index.

* `[j]`: *(#str)* The last byte index. Cannot be lower than `i`.

**Returns:** If no problems were found, the total number of code points scanned. Otherwise, `nil`, error string, and byte index.

**Notes:**

* As a special case, this function will return `0` when given an empty string and values of zero for `i` and `j`. (In other words, `utf8Tools.check("")` will always return `0`.)

* For non-empty strings, if the range arguments are specified, then `i` needs to point to a UTF-8 Start Byte, and `j` needs to point to the last byte of a UTF-8-encoded character.


### utf8Tools.scrub

Replaces bad UTF-8 Sequences in a string.

`local str = utf8Tools.scrub(s, repl)`

* `s`: The string to scrub.

* `repl`: A replacement string to use in place of the bad UTF-8 Sequences. Use an empty string to just remove the invalid bytes.


**Returns:** The scrubbed UTF-8 string.


### utf8Tools.codeFromString

Gets a Unicode Code Point and its isolated UTF-8 Sequence from a string.

`local code, u8_seq = utf8Tools.codeFromString(s, [i])`

* `s`: The UTF-8 string to read. Cannot be empty.

* `[i]`: *(1)* The byte position to read from. Must point to a valid UTF-8 Start Byte.


**Returns:** The code point number and its equivalent UTF-8 Sequence as a string, or `nil` plus an error string if unsuccessful.


### utf8Tools.stringFromCode

Converts a code point in numeric form to a UTF-8 Sequence (string).

`local u8_seq, err = utf8Tools.stringFromCode(c)`

* `c`: The code point number.

**Returns:** the UTF-8 Sequence (string), or `nil` plus an error string if unsuccessful.


### utf8Tools.step

Looks for a Start Byte from a byte position through to the end of the string.

This function **does not validate** the encoding.

`local index = utf8Tools.step(s, i)`

* `s`: The string to search.

* `i`: Starting position; bytes *after* this index are checked. Can be from `0` to `#str`.

**Returns:** Index of the next Start Byte, or `nil` if the end of the string is reached.

**Notes:**

* With empty strings, the only accepted position for `i` is 0.


### utf8Tools.stepBack

Looks for a Start Byte from a byte position through to the start of the string.

This function **does not validate** the encoding.

`local index = utf8Tools.stepBack(s, i)`

* `s`: The string to search.

* `i`: Starting position; bytes *before* this index are checked. Can be from `1` to `#str + 1`.

**Returns:** Index of the previous Start Byte, or `nil` if the start of the string is reached.

**Notes:**

* With empty strings, the only accepted position for `i` is 1.


### utf8Tools.codes

A loop iterator for code points in a UTF-8 string, where `i` is the byte position, `c` is the code point number, and `u` is the code point's UTF-8 substring.

This function **raises a Lua error** if it encounters a problem with the UTF-8 encoding or with the code point values.

`for i, c, u in utf8.codes(s) do …`

* `s`: The string to iterate.

**Returns:** The byte position `i`, the code point number `c`, and the code point's UTF-8 string representation `u`.


### utf8Tools.concatCodes

Creates a UTF-8 string from one or more code point numbers.

This function **raises a Lua error** if it encounters a problem with the code point numbers.

`local str = utf8Tools.concatCodes(...)`

* `...`: Code point numbers.

**Returns:** A concatenated UTF-8 string.

**Notes:**

* This function allocates a temporary table. To convert single code points, `utf8Tools.stringFromCode()` can be used instead.


# utf8Conv

## utf8Conv API

### utf8Conv.latin1_utf8

Converts a Latin 1 (ISO 8859-1) string to UTF-8.

`utf8Conv.latin1_utf8(s)`

* `s`: The Latin 1 string to convert.

**Returns:** The converted UTF-8 string, or `nil`, error string, and byte index if there was a problem.


### utf8Conv.utf8_latin1

Converts a UTF-8 string to Latin 1 (ISO 8859-1).

Only code points 0 through 255 can be directly mapped to a Latin 1 string. Use the `[unmapped]` argument to control what happens when an unmappable code point is encountered.

`utf8Conv.utf8_latin1(s, [unmapped])`

* `s`: The UTF-8 string to convert.

* `[unmapped]`: When `unmapped` is a string, it is used in place of unmappable code points. (Pass in an empty string to ignore unmappable code points.) When `unmapped` is any other type, the function returns `nil`, an error string, and the byte where the unmappable code point was encountered.

**Returns:** The converted Latin 1 string, or `nil`, error string, and byte index if there was a problem.


### utf8Tools.utf16_utf8

Converts a UTF-16 string to UTF-8.

`utf8Conv.utf16_utf8(s, [big_en])`

* `s`: The UTF-16 string to convert.

* `[big_en]`: *(nil)* `true` if the input UTF-16 string is big-endian, `false/nil` if it is little-endian.

**Returns:** The converted UTF-8 string, or `nil`, error string, and byte index if there was a problem.


### utf8Conv.utf8_utf16

Converts a UTF-8 string to UTF-16.

`utf8Conv.utf8_utf16(s, [big_en])`

* `s`: The UTF-8 string to convert.

* `[big_en]`: *(nil)* `true` if the converted UTF-16 string is big-endian, `false/nil` if it is little-endian.

**Returns:** The converted UTF-16 string, or `nil`, error string, and byte index if there was a problem.


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
