# Quick Sort with Closure Example

```{admonition} ⚠️ Critical Technique: Closure First Parameter Reference Counting
:class: warning

This example uses adapter function type `FuncRef[((Point, Point) -> Int, Point, Point) -> Int]`, note that **closure is the first parameter**.

**Important rule**: Before each call to this adapter function in C code, you must execute `moonbit_incref(closure)` on the closure, otherwise it will cause use-after-free errors.

This is one of the most error-prone areas in MoonBit Native FFI!
```

This example shows how to pass MoonBit closures to C functions. Unlike the previous example, the comparison function used here can capture external variables.

## Overview

This example implements a more advanced sorting interface that supports passing closures that can capture variables as comparison functions. It demonstrates:

1. How MoonBit closures are handled in C FFI
2. Differences and conversions between closures and `FuncRef`
3. Complex function type FFI declarations

## FFI Function Declaration

The MoonBit side FFI declaration is more complex than the previous example:

```{literalinclude} /sources/native-ffi/src/funcref_qsort_closure/top.mbt
:language: moonbit
:start-after: start closure qsort ffi declaration
:end-before: end closure qsort ffi declaration
```

Key feature analysis:

1. **Three parameters**:
   - `xs`: Array to be sorted
   - `comp`: Adapter function, type `FuncRef[((Point, Point) -> Int, Point, Point) -> Int]`
   - `closure`: Actual comparison closure, type `(Point, Point) -> Int`

2. **⚠️ Important details of adapter function signature**:
   - Note `comp` type: `((Point, Point) -> Int, Point, Point) -> Int`
   - **First parameter is the closure itself**, subsequent parameters are passed to the closure
   - This design requires special handling of closure reference counting on the C side

3. **Adapter pattern**: Call `closure` through `comp` function, this is the standard pattern for handling closures

## Wrapper Function

MoonBit provides a simplified interface:

```{literalinclude} /sources/native-ffi/src/funcref_qsort_closure/top.mbt
:language: moonbit
:start-after: start closure qsort wrapper
:end-before: end closure qsort wrapper
```

This wrapper function:
- Accepts regular closure function `comp : (Point, Point) -> Int`
- Creates adapter function `fn(f, x, y) { f(x, y) }`
- Hides FFI complexity

## C Implementation Details

### Type Definitions and Context Structure

```{literalinclude} /sources/native-ffi/src/funcref_qsort_closure/stub.c
:language: c
:start-after: start closure type definitions
:end-before: end closure type definitions
```

Main differences from the previous example:
- Added `moonbit_closure_t` type to represent closures
- Context structure contains the closure object itself

### Comparison Function Implementation

```{literalinclude} /sources/native-ffi/src/funcref_qsort_closure/stub.c
:language: c
:start-after: start closure comparison function
:end-before: end closure comparison function
```

Critical memory management:
1. **⚠️ Closure reference count critical technique**: `moonbit_incref(context->closure)` increments closure reference count
   - **Important**: Since closure is the first parameter of adapter function, it consumes one reference when called
   - Must execute `moonbit_incref` before each call, otherwise leads to use-after-free errors
2. **Parameter reference count**: Increment reference counts for both Point parameters respectively
3. **Three-parameter call**: Call adapter function, passing closure and two parameters

### Main Sorting Function

```{literalinclude} /sources/native-ffi/src/funcref_qsort_closure/stub.c
:language: c
:start-after: start closure qsort function
:end-before: end closure qsort function
```

Context setup:
- Save adapter function pointer
- Save closure object reference

## Closure vs FuncRef Differences

### FuncRef Characteristics:
- Must be closed functions (don't capture external variables)
- Represented as simple function pointers on C side
- Lower performance overhead

### Closure Characteristics:
- Can capture external variables
- Require additional context data on C side
- Need more complex memory management

## Test Case

```{literalinclude} /sources/native-ffi/src/funcref_qsort_closure/top.mbt
:language: moonbit
:lines: 19-40
```

Test highlights:

1. **Variable capture**: Comparison function captures external `mut i` variable
2. **State statistics**: Modify `i` to count comparison operations
3. **Functionality verification**: Ensure sorting results are correct

Note: The comment in the test mentions that `inspect` cannot be used inside closures due to error handling limitations.

## Key Learning Points

1. **Closure passing pattern**: Understand how to pass closures through adapter functions
2. **Memory management complexity**: Closures require more careful reference count management
3. **Performance trade-offs**: Closures provide greater flexibility but have additional runtime overhead
4. **Type system design**: MoonBit distinguishes between `FuncRef` and closures through the type system
5. **FFI design patterns**: Adapter pattern is the standard method for handling complex callbacks