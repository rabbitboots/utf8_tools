# utf8Tools Changelog

# v1.1.0 (19 Sept 2023)

**NOTE:** This is an API-breaking update.

* (#1) Fixed incorrect usage of the term *code unit* in source code and documentation. Renamed functions with the term `CodeUnit` to use `UCString` instead, where *UCString* refers to a single Unicode Code Point encoded in UTF-8 and stored as a Lua string. (*Code Unit* refers to the bytes in a code point encoded as UTF-8.) In some other cases (comments and error messages), *UTF-8 sequence* is used. See *Upgrade Guide From v1.0.0 to v1.1.0* for a list of affected public functions.

* Updated and reformatted README.md. Minor updates to source comments.

* Started changelog.


## Upgrade Guide From v1.0.0 to v1.1.0

* Update any calls to these functions (they behave the same as before):
  * `utf8Tools.getCodeUnit(str, pos)` -> `utf8Tools.getUCString(str, pos)`
  * `utf8Tools.hasMalformedCodeUnits(str)` -> `utf8Tools.hasMalformedUCStrings(str)`
  * `utf8Tools.u8CodePointToUnit(code_point_num)` -> `utf8Tools.codePointToUCString(code_point_num)`
  * `utf8Tools.u8UnitToCodePoint(unit_str)` -> `utf8Tools.ucStringToCodePoint(u_str)`
