# Variables

The `let` keyword is used to define a variable in MoonBit. 

## Type Annotation

You can specify the type of a variable by using a colon followed by the type name. Type annotation is optional - if not provided, MoonBit will automatically infer the type from the assigned value.

If you don't want to define an extra variable, you can also add a type annotation to any expression using the syntax `(expression : Type)`.

## Mutability

Variables in MoonBit are **immutable by default**, which means they cannot be reassigned after initialization. To create a mutable variable that can be reassigned, add the `mut` keyword before the variable name.

## Scope

You can define a variable in top-level scope or local scope (inside a function or block).
Variables defined in a block (enclosed by `{}`) are only accessible within that block 
and its nested blocks. Variables defined in the top-level scope are accessible throughout 
the entire program.

