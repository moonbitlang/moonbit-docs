# Variables

The `let` keyword used to define a variable. 

The type of the variable can be annotated by using a colon followed by the type. 
It is optional, if not provided the type will be inferred from the value.

Variables are immutable by default in MoonBit. You can add an extra `mut` 
keyword to make them mutable at the local level.

If you uncomment the `d = d + 1`, you will get an error.