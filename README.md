**Version:** 1.4.1

# utf8Tools

UTF-8 utility functions for Lua 5.1 - 5.4.

## Package Information

`utf8_tools.lua` is the main file.

`utf8_conv.lua` contains auxiliary functions for converting UTF-16 and ISO 8859-1 (Latin-1) to UTF-8 and back.

Files beginning with `pile` are required.

Files and folders beginning with `test` can be deleted.


## Terminology

**Code Point**: a Unicode Code Point, stored as a Lua number. `65` (for A)

**UTF-8 Sequence**: A single Unicode Code Point, encoded in UTF-8 and stored as a Lua string. `"A"`

**Start Byte**: The first byte in a UTF-8 Sequence. The length of the sequence is encoded in the start byte.

**Continuation Byte**: The second, third or fourth byte in a UTF-8 Sequence. A UTF-8 Sequence may not be longer than 4 bytes.

**Surrogate**: Values in the range of U±D800 to U±DFFF are reserved for *surrogate pairs* in UTF-16, and are not valid code points.


# utf8Tools API

## utf8Tools.getCheckSurrogates

Gets the library's setting for checking surrogate values.

`local enabled = utf8Tools.getCheckSurrogates()`

**Returns:** `true` if surrogates are rejected as invalid, `false` if they are ignored.


## utf8Tools.setCheckSurrogates

*Default: true*

Sets the library to check or ignore surrogate values.

`utf8Tools.setCheckSurrogates(enabled)`

* `enabled`: `true` to reject surrogates as invalid, `false/nil` to ignore them.


## utf8Tools.check

Checks a UTF-8 string for encoding problems and invalid code points.

`local ok, err, byte = utf8Tools.check(s, [i], [j])`

* `s`: The string to check.

* `[i]`: *(empty string: 0; non-empty string: 1)* The first byte index.

* `[j]`: *(#str)* The last byte index. Cannot be lower than `i`.

**Returns:** If no problems were found, the total number of code points scanned. Otherwise, `nil`, error string, and byte index.

**Notes:**

* As a special case, this function will return `0` when given an empty string and values of zero for `i` and `j`. (In other words, `utf8Tools.check("")` will always return `0`.)

* For non-empty strings, if the range arguments are specified, then `i` needs to point to a UTF-8 Start Byte, and `j` needs to point to the last byte of a UTF-8-encoded character.


## utf8Tools.checkAlt

An alternative UTF-8 encoding checker, based on [kikito's utf_validator.lua](https://github.com/kikito/utf8_validator.lua). Depending on the input, this function can be faster than `utf8Tools.check()` in PUC-Lua (though if you have access to Lua 5.4's `utf8` library, then `utf8.len()` will likely be faster).

`local ok, byte = utf8Tools.checkAlt(s, [i])`

* `s`: The string to check.

* `[i]`: *(empty string: 0; non-empty string: 1)* The first byte index.

**Returns:** If no problems were found, the total number of code points scanned. Otherwise, `nil` and byte index.

**Notes:**

* As a special case, this function will return `0` when given an empty string, regardless of what is provided for `i`.

* For non-empty strings, if the start byte is specified, then `i` needs to point to a UTF-8 Start Byte.

* This function *always* rejects surrogate values, regardless of what has been set with `utf8Tools.setCheckSurrogates()`.


## utf8Tools.scrub

Replaces bad UTF-8 Sequences in a string.

`local str = utf8Tools.scrub(s, repl, alt)`

* `s`: The string to scrub.

* `repl`: A replacement string to use in place of the bad UTF-8 Sequences. Use an empty string to remove the invalid bytes.

* `alt`: *(false)* When `true`, uses `utf8Tools.checkAlt()` internally rather than `utf8Tools.check()`.


**Returns:** The scrubbed UTF-8 string.


## utf8Tools.codeFromString

Gets a Unicode Code Point and its isolated UTF-8 Sequence from a string.

`local code, u8_seq = utf8Tools.codeFromString(s, [i])`

* `s`: The UTF-8 string to read. Cannot be empty.

* `[i]`: *(1)* The byte position to read from. Must point to a valid UTF-8 Start Byte.

**Returns:** The code point number and its equivalent UTF-8 Sequence as a string, or `nil` plus an error string if unsuccessful.


## utf8Tools.stringFromCode

Converts a code point in numeric form to a UTF-8 Sequence (string).

`local u8_seq, err = utf8Tools.stringFromCode(c)`

* `c`: The code point number.

**Returns:** the UTF-8 Sequence (string), or `nil` plus an error string if unsuccessful.


## utf8Tools.step

Looks for a Start Byte from a byte position through to the end of the string.

This function **does not validate** the encoding.

`local index = utf8Tools.step(s, i)`

* `s`: The string to search.

* `i`: Starting position; bytes *after* this index are checked. Can be from `0` to `#str`.

**Returns:** Index of the next Start Byte, or `nil` if the end of the string is reached.

**Notes:**

* With empty strings, the only accepted position for `i` is 0.


## utf8Tools.stepBack

Looks for a Start Byte from a byte position through to the start of the string.

This function **does not validate** the encoding.

`local index = utf8Tools.stepBack(s, i)`

* `s`: The string to search.

* `i`: Starting position; bytes *before* this index are checked. Can be from `1` to `#str + 1`.

**Returns:** Index of the previous Start Byte, or `nil` if the start of the string is reached.

**Notes:**

* With empty strings, the only accepted position for `i` is 1.


## utf8Tools.codes

A loop iterator for code points in a UTF-8 string, where `i` is the byte position, `c` is the code point number, and `u` is the code point's UTF-8 substring.

This function **raises a Lua error** if it encounters a problem with the UTF-8 encoding or with the code point values.

`for i, c, u in utf8.codes(s) do …`

* `s`: The string to iterate.

**Returns:** The byte position `i`, the code point number `c`, and the code point's UTF-8 string representation `u`.


## utf8Tools.concatCodes

Creates a UTF-8 string from one or more code point numbers.

This function **raises a Lua error** if it encounters a problem with the code point numbers.

`local str = utf8Tools.concatCodes(...)`

* `...`: Code point numbers.

**Returns:** A concatenated UTF-8 string.

**Notes:**

* This function allocates a temporary table. To convert single code points, `utf8Tools.stringFromCode()` can be used instead.


# utf8Conv API

## utf8Conv.latin1_utf8

Converts a Latin 1 (ISO 8859-1) string to UTF-8.

`utf8Conv.latin1_utf8(s)`

* `s`: The Latin 1 string to convert.

**Returns:** The converted UTF-8 string, or `nil`, error string, and byte index if there was a problem.


## utf8Conv.utf8_latin1

Converts a UTF-8 string to Latin 1 (ISO 8859-1).

Only code points 0 through 255 can be directly mapped to a Latin 1 string. Use the `[unmapped]` argument to control what happens when an unmappable code point is encountered.

`utf8Conv.utf8_latin1(s, [unmapped])`

* `s`: The UTF-8 string to convert.

* `[unmapped]`: When `unmapped` is a string, it is used in place of unmappable code points. (Pass in an empty string to ignore unmappable code points.) When `unmapped` is any other type, the function returns `nil`, an error string, and the byte where the unmappable code point was encountered.

**Returns:** The converted Latin 1 string, or `nil`, error string, and byte index if there was a problem.


## utf8Conv.utf16_utf8

Converts a UTF-16 string to UTF-8.

`utf8Conv.utf16_utf8(s, [big_en])`

* `s`: The UTF-16 string to convert.

* `[big_en]`: *(nil)* `true` if the input UTF-16 string is big-endian, `false/nil` if it is little-endian.

**Returns:** The converted UTF-8 string, or `nil`, error string, and byte index if there was a problem.


## utf8Conv.utf8_utf16

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

```
MIT License

Copyright (c) 2022 - 2024 RBTS

Code from https://github.com/kikito/utf8_validator.lua:
Copyright (c) 2013 Enrique García Cota

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
```
