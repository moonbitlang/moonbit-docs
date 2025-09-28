# Function

Functions are reusable blocks of code that take inputs (arguments) and produce outputs (return values). They are defined using the `fn` keyword, followed by the function name, parameter list in parentheses, return type after `->` , and the function body in curly brackets.

## Parameters and Arguments

Parameters are the inputs that a function expects to receive. When calling a function, you provide arguments (actual values) for these parameters. Parameters must have explicit type annotations.

## Return Values

Functions can return values using the `return` keyword, or by having the last expression in the function body serve as the return value. The return type must be specified after the `->` arrow. When a function doesn't return a meaningful value, it uses the `Unit` type. This is similar to `void` in other languages.

## Labeled Arguments And Optional Arguments

MoonBit supports labeled arguments using the syntax `label~ : Type` . The `print_position` function declares two labeled arguments `x` and `y` . When calling the function, you need to provide their values in the form `label=value` .

Arguments can also be optional by providing a default value. The syntax is `label? : Type = default_value` . Take the `print_greeting` function as an example: when calling `print_greeting()` without providing the `name` argument, `name` will use the default value `"guest"` . When passing optional arguments, you must provide the label name at the call site.

Labeled and optional arguments can be passed in any order, making function calls more readable.
