# Enum 

Enum used to define a type by enumerating its possible values. Unlike traditional enums, MoonBit enums can have data associated with each enumeration. We call each enumeration an *enum constructor*.

In this example, we define an enum `Color`, which has five enum constructors: `Red`, `Green`, `Blue`, `RGB`, and `CMYK`. The `Red`, `Green`, and `Blue` directly represent a color it described, while `RGB` and `CMYK` have data associated with them.

Values like `Red` and `RGB(255,255,255)` are both instances of the `Color` type. To create an instance more explicitly, you can use `Color::Red`, similar to creating an instance of a struct.

We use a bit of *pattern matching* to distinguish different *enum constructors* in `print_color`. It's a control flow similar to switch-case in C-like languages. Here is a slight difference: you can extract the associated data by giving them a name on the left of `=>`, and use them as variables on the right side.

We will explore more powerful features of *pattern matching* in the next chapter.

