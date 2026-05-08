# Fundamentals

This section introduces the core MoonBit language concepts. It is split into focused pages so the language manual is easier to scan, link, and maintain.

```{toctree}
:maxdepth: 2

fundamentals/builtins
fundamentals/overloaded-literals
fundamentals/functions
fundamentals/control-structures
fundamentals/iterator
fundamentals/custom-data-types
fundamentals/pattern-matching
fundamentals/generics
fundamentals/special-syntax
```

## Topic Index

<span id="built-in-data-structures"></span>
- [Built-in Data Structures](fundamentals/builtins.md)
<span id="unit"></span>
- [Unit](fundamentals/builtins.md#unit)
<span id="boolean"></span>
- [Boolean](fundamentals/builtins.md#boolean)
<span id="number"></span>
- [Number](fundamentals/builtins.md#number)
<span id="string"></span>
- [String](fundamentals/builtins.md#string)
<span id="char"></span>
- [Char](fundamentals/builtins.md#char)
<span id="byte-s"></span>
- [Byte(s)](fundamentals/builtins.md#bytes)
<span id="bytes"></span>
- [Bytes](fundamentals/builtins.md#bytes)
<span id="choosing-a-byte-container"></span>
- [Choosing a Byte Container](fundamentals/builtins.md#choosing-a-byte-container)
<span id="tuple"></span>
- [Tuple](fundamentals/builtins.md#tuple)
<span id="ref"></span>
- [Ref](fundamentals/builtins.md#ref)
<span id="option-and-result"></span>
- [Option and Result](fundamentals/builtins.md#option-and-result)
<span id="array"></span>
- [Array](fundamentals/builtins.md#array)
<span id="arrayview"></span>
- [ArrayView](fundamentals/builtins.md#arrayview)
<span id="map"></span>
- [Map](fundamentals/builtins.md#map)
<span id="json"></span>
- [Json](fundamentals/builtins.md#json)
<span id="overloaded-literals"></span>
- [Overloaded Literals](fundamentals/overloaded-literals.md)
<span id="escape-sequences-in-overloaded-literals"></span>
- [Escape Sequences in Overloaded Literals](fundamentals/overloaded-literals.md#escape-sequences-in-overloaded-literals)
<span id="functions"></span>
- [Functions](fundamentals/functions.md)
<span id="top-level-functions"></span>
- [Top-Level Functions](fundamentals/functions.md#top-level-functions)
<span id="local-functions"></span>
- [Local Functions](fundamentals/functions.md#local-functions)
<span id="function-applications"></span>
- [Function Applications](fundamentals/functions.md#function-applications)
<span id="partial-applications"></span>
- [Partial Applications](fundamentals/functions.md#partial-applications)
<span id="labelled-arguments"></span>
- [Labelled arguments](fundamentals/functions.md#labelled-arguments)
<span id="optional-arguments"></span>
- [Optional arguments](fundamentals/functions.md#optional-arguments)
<span id="optional-arguments-without-default-values"></span>
- [Optional arguments without default values](fundamentals/functions.md#optional-arguments-without-default-values)
<span id="autofill-arguments"></span>
- [Autofill arguments](fundamentals/functions.md#autofill-arguments)
<span id="function-alias"></span>
- [Function alias](fundamentals/functions.md#function-alias)
<span id="control-structures"></span>
- [Control Structures](fundamentals/control-structures.md)
<span id="conditional-expressions"></span>
- [Conditional Expressions](fundamentals/control-structures.md#conditional-expressions)
<span id="match-expression"></span>
- [Match Expression](fundamentals/control-structures.md#match-expression)
<span id="guard-statement"></span>
- [Guard Statement](fundamentals/control-structures.md#guard-statement)
<span id="guard-statement-and-is-expression"></span>
- [Guard statement and is expression](fundamentals/control-structures.md#guard-statement-and-is-expression)
<span id="while-loop"></span>
- [While loop](fundamentals/control-structures.md#while-loop)
<span id="for-loop"></span>
- [For Loop](fundamentals/control-structures.md#for-loop)
<span id="for--in-loop"></span>
- [for .. in loop](fundamentals/control-structures.md#for--in-loop)
<span id="range-expression-in-for--in-loop"></span>
- [Range expression in for .. in loop](fundamentals/control-structures.md#range-expression-in-for--in-loop)
<span id="labelled-continuebreak"></span>
- [Labelled Continue/Break](fundamentals/control-structures.md#labelled-continuebreak)
<span id="defer-expression"></span>
- [defer expression](fundamentals/control-structures.md#defer-expression)
<span id="iterator"></span>
- [Iterator](fundamentals/iterator.md)
<span id="custom-data-types"></span>
- [Custom Data Types](fundamentals/custom-data-types.md)
<span id="struct"></span>
- [Struct](fundamentals/custom-data-types.md#struct)
<span id="constructing-struct-with-shorthand"></span>
- [Constructing Struct with Shorthand](fundamentals/custom-data-types.md#constructing-struct-with-shorthand)
<span id="struct-update-syntax"></span>
- [Struct Update Syntax](fundamentals/custom-data-types.md#struct-update-syntax)
<span id="custom-constructor-for-struct"></span>
- [Custom constructor for struct](fundamentals/custom-data-types.md#custom-constructor-for-struct)
<span id="enum"></span>
- [Enum](fundamentals/custom-data-types.md#enum)
<span id="constructor-with-labelled-arguments"></span>
- [Constructor with labelled arguments](fundamentals/custom-data-types.md#constructor-with-labelled-arguments)
<span id="constructor-with-mutable-fields"></span>
- [Constructor with mutable fields](fundamentals/custom-data-types.md#constructor-with-mutable-fields)
<span id="tuple-struct"></span>
- [Tuple Struct](fundamentals/custom-data-types.md#tuple-struct)
<span id="type-alias"></span>
- [Type alias](fundamentals/custom-data-types.md#type-alias)
<span id="local-types"></span>
- [Local types](fundamentals/custom-data-types.md#local-types)
<span id="pattern-matching"></span>
- [Pattern Matching](fundamentals/pattern-matching.md)
<span id="simple-patterns"></span>
- [Simple Patterns](fundamentals/pattern-matching.md#simple-patterns)
<span id="array-pattern"></span>
- [Array Pattern](fundamentals/pattern-matching.md#array-pattern)
<span id="bitstring-pattern"></span>
- [Bitstring Pattern](fundamentals/pattern-matching.md#bitstring-pattern)
<span id="range-pattern"></span>
- [Range Pattern](fundamentals/pattern-matching.md#range-pattern)
<span id="map-pattern"></span>
- [Map Pattern](fundamentals/pattern-matching.md#map-pattern)
<span id="json-pattern"></span>
- [Json Pattern](fundamentals/pattern-matching.md#json-pattern)
<span id="guard-condition"></span>
- [Guard condition](fundamentals/pattern-matching.md#guard-condition)
<span id="generics"></span>
- [Generics](fundamentals/generics.md)
<span id="special-syntax"></span>
- [Special Syntax](fundamentals/special-syntax.md)
<span id="pipelines"></span>
- [Pipelines](fundamentals/special-syntax.md#pipelines)
<span id="cascade-operator"></span>
- [Cascade Operator](fundamentals/special-syntax.md#cascade-operator)
<span id="is-expression"></span>
- [is Expression](fundamentals/special-syntax.md#is-expression)
<span id="regex-literal-expression"></span>
- [Regex Literal Expression](fundamentals/special-syntax.md#regex-literal-expression)
<span id="regex-match-expression"></span>
- [Regex Match Expression](fundamentals/special-syntax.md#regex-match-expression)
<span id="lexmatch"></span>
- [Lexmatch](fundamentals/special-syntax.md#lexmatch)
<span id="spread-operator"></span>
- [Spread Operator](fundamentals/special-syntax.md#spread-operator)
<span id="todo-syntax"></span>
- [TODO syntax](fundamentals/special-syntax.md#todo-syntax)
