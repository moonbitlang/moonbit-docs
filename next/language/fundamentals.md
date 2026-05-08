# Fundamentals

This section covers the core MoonBit language concepts that later manual pages build on. The pages are grouped by concept area so readers can scan the manual without turning every small syntax topic into a separate stop in the reading order.

```{toctree}
:maxdepth: 2

fundamentals/builtins-and-literals
fundamentals/functions
fundamentals/control-flow-and-iteration
fundamentals/custom-data-types
fundamentals/pattern-matching
fundamentals/special-syntax
```

## Topic Index

<span id="built-in-data-structures"></span>
- [Built-in Data Structures](fundamentals/builtins-and-literals.md)
<span id="unit"></span>
- [Unit](fundamentals/builtins-and-literals.md#unit)
<span id="boolean"></span>
- [Boolean](fundamentals/builtins-and-literals.md#boolean)
<span id="number"></span>
- [Number](fundamentals/builtins-and-literals.md#number)
<span id="string"></span>
- [String](fundamentals/builtins-and-literals.md#string)
<span id="char"></span>
- [Char](fundamentals/builtins-and-literals.md#char)
<span id="byte-s"></span>
- [Byte(s)](fundamentals/builtins-and-literals.md#bytes)
<span id="bytes"></span>
- [Bytes](fundamentals/builtins-and-literals.md#bytes)
<span id="choosing-a-byte-container"></span>
- [Choosing a Byte Container](fundamentals/builtins-and-literals.md#choosing-a-byte-container)
<span id="tuple"></span>
- [Tuple](fundamentals/builtins-and-literals.md#tuple)
<span id="ref"></span>
- [Ref](fundamentals/builtins-and-literals.md#ref)
<span id="option-and-result"></span>
- [Option and Result](fundamentals/builtins-and-literals.md#option-and-result)
<span id="array"></span>
- [Array](fundamentals/builtins-and-literals.md#array)
<span id="arrayview"></span>
- [ArrayView](fundamentals/builtins-and-literals.md#arrayview)
<span id="map"></span>
- [Map](fundamentals/builtins-and-literals.md#map)
<span id="json"></span>
- [Json](fundamentals/builtins-and-literals.md#json)
<span id="overloaded-literals"></span>
- [Overloaded Literals](fundamentals/builtins-and-literals.md#overloaded-literals)
<span id="escape-sequences-in-overloaded-literals"></span>
- [Escape Sequences in Overloaded Literals](fundamentals/builtins-and-literals.md#escape-sequences-in-overloaded-literals)
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
- [Control Structures](fundamentals/control-flow-and-iteration.md)
<span id="conditional-expressions"></span>
- [Conditional Expressions](fundamentals/control-flow-and-iteration.md#conditional-expressions)
<span id="match-expression"></span>
- [Match Expression](fundamentals/control-flow-and-iteration.md#match-expression)
<span id="guard-statement"></span>
- [Guard Statement](fundamentals/control-flow-and-iteration.md#guard-statement)
<span id="guard-statement-and-is-expression"></span>
- [Guard statement and is expression](fundamentals/control-flow-and-iteration.md#guard-statement-and-is-expression)
<span id="while-loop"></span>
- [While loop](fundamentals/control-flow-and-iteration.md#while-loop)
<span id="for-loop"></span>
- [For Loop](fundamentals/control-flow-and-iteration.md#for-loop)
<span id="for--in-loop"></span>
- [for .. in loop](fundamentals/control-flow-and-iteration.md#for--in-loop)
<span id="range-expression-in-for--in-loop"></span>
- [Range expression in for .. in loop](fundamentals/control-flow-and-iteration.md#range-expression-in-for--in-loop)
<span id="labelled-continuebreak"></span>
- [Labelled Continue/Break](fundamentals/control-flow-and-iteration.md#labelled-continuebreak)
<span id="defer-expression"></span>
- [defer expression](fundamentals/control-flow-and-iteration.md#defer-expression)
<span id="iterator"></span>
- [Iterator](fundamentals/control-flow-and-iteration.md#iterator)
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
- [Generics](fundamentals/custom-data-types.md#generics)
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
