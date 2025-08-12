# G-Machine

Lazy evaluation stands as a foundational concept in the realm of programming languages. Haskell, renowned as a purely functional programming language, boasts a robust lazy evaluation mechanism. This mechanism not only empowers developers to craft code that's both more efficient and concise but also enhances program performance and responsiveness, especially when tackling sizable datasets or intricate data streams.

In this article, we'll delve into the Lazy Evaluation mechanism, thoroughly examining its principles and implementation methods, and then explore how to implement Haskell's evaluation semantics in [MoonBit](https://www.moonbitlang.com/).

# Contents:

* [G-Machine 1](gmachine-1.md)
  * [Higher-Order Functions and Performance Challenges](gmachine-1.md#higher-order-functions-and-performance-challenges)
  * [Lazy List Implementation](gmachine-1.md#lazy-list-implementation)
  * [A Lazy Evaluation Language and Its Abstract Syntax Tree](gmachine-1.md#a-lazy-evaluation-language-and-its-abstract-syntax-tree)
  * [Why Graph](gmachine-1.md#why-graph)
  * [Conventions](gmachine-1.md#conventions)
  * [G-Machine Overview](gmachine-1.md#g-machine-overview)
  * [Dissecting the G-Machine State](gmachine-1.md#dissecting-the-g-machine-state)
  * [Corresponding Effect of Each Instruction](gmachine-1.md#corresponding-effect-of-each-instruction)
  * [Compiling Super Combinators into Instruction Sequences](gmachine-1.md#compiling-super-combinators-into-instruction-sequences)
  * [Running the G-Machine](gmachine-1.md#running-the-g-machine)
  * [Conclusion](gmachine-1.md#conclusion)
  * [Reference](gmachine-1.md#reference)
* [G-Machine 2](gmachine-2.md)
  * [let Expressions](gmachine-2.md#let-expressions)
  * [Adding Primitives](gmachine-2.md#adding-primitives)
  * [Conclusion](gmachine-2.md#conclusion)
* [G-Machine 3](gmachine-3.md)
  * [Tracking Context](gmachine-3.md#tracking-context)
  * [Custom Data Structures](gmachine-3.md#custom-data-structures)
  * [Epilogue](gmachine-3.md#epilogue)
