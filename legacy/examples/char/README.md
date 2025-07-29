# Char
Use MoonBit to implement string tools.

## API
This function is used to check whether the given character c is a valid character. It returns a boolean value indicating whether the character is valid or not.
```moonbit
is_valid(c: Char) -> Bool
```
This function is used to determine if the character c is an alphabet letter. It returns true if c is an alphabet letter, otherwise it returns false.
```moonbit
is_alpha(c : Char) -> Bool
```
This function is used to check if the character c is a numeric digit. It returns true if c is a numeric digit, otherwise it returns false.
```moonbit
is_numeric(c : Char) -> Bool
```
This function is used to determine if the character c is either an alphabet letter or a numeric digit. It returns true if c is an alphanumeric character, otherwise it returns false.
```moonbit
is_alphanumeric(c : Char) -> Bool
```
This function is used to convert the character c to its lowercase form and returns the lowercase character.
```moonbit
to_lower(c : Char) -> Char
```
This function is used to convert the character c to its uppercase form and returns the uppercase character.
```moonbit
to_upper(c : Char) -> Char
```
This function is used to check if the character c is a whitespace character (such as space or tab). It returns true if c is a whitespace character, otherwise it returns false.
```moonbit
is_whitespace(c : Char) -> Bool
```
This function returns the next character following the character c. If there is a next character, it returns the character wrapped in Some, otherwise it returns None.
```moonbit
next(c : Char) -> Option[Char]
```
This function returns the previous character before the character c. If there is a previous character, it returns the character wrapped in Some, otherwise it returns None.
```moonbit
prev(c : Char) -> Option[Char]
```
