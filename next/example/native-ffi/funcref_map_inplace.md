# In-place Map Transformation Example

```{admonition} ⚠️ Critical Technique: Closure First Parameter Reference Counting
:class: warning

This example uses adapter function type `FuncRef[((Point) -> Point, Point) -> Point]`, note that **closure is the first parameter**.

**Important rule**: Before each call to this adapter function in C code, you must execute `moonbit_incref(closure)` on the closure, otherwise it will cause use-after-free errors.

In the example, each array element is called twice, so two `moonbit_incref` calls are needed.
```

This example demonstrates how to implement in-place array transformation operations, showcasing MoonBit closure usage in array element transformations.

## Overview

This example implements a `map_inplace` function that can apply transformation functions to each element in an array. Unlike the previous sorting examples, this focuses on element transformation rather than comparison operations.

## FFI Function Declaration

MoonBit side FFI declaration:

```{literalinclude} /sources/native-ffi/src/funcref_map_inplace/top.mbt
:language: moonbit
:start-after: start map inplace ffi declaration
:end-before: end map inplace ffi declaration
```

Function parameter analysis:

1. **`xs : FixedArray[Point]`**: Array to be transformed
2. **⚠️ `call : FuncRef[((Point) -> Point, Point) -> Point]`**: Adapter function type
   - **Key**: First parameter `(Point) -> Point` is the closure itself
   - Second parameter `Point` is the input value passed to the closure
   - Return value `Point` is the execution result of the closure
3. **`closure : (Point) -> Point`**: Actual transformation closure

## Wrapper Function

```{literalinclude} /sources/native-ffi/src/funcref_map_inplace/top.mbt
:language: moonbit
:start-after: start map inplace wrapper
:end-before: end map inplace wrapper
```

This wrapper function provides a clean interface, hiding FFI complexity.

## C Implementation Details

### Type Definitions

```{literalinclude} /sources/native-ffi/src/funcref_map_inplace/stub.c
:language: c
:start-after: start map inplace types
:end-before: end map inplace types
```

Simplified type definitions:
- `moonbit_closure_t`: Represents MoonBit closures
- `moonbit_point_t`: Represents Point objects

### Core Implementation

```{literalinclude} /sources/native-ffi/src/funcref_map_inplace/stub.c
:language: c
:start-after: start map inplace implementation
:end-before: end map inplace implementation
```

### Implementation Detail Analysis

1. **Array length retrieval**: Use `Moonbit_array_length(xs)` to get array length
2. **Loop processing**: Iterate through each element in the array
3. **Double call**: Each element is called by transformation function twice (for demonstration)
4. **⚠️ Critical reference count management**: Need `moonbit_incref(closure)` before each call
   - **Reason**: Closure as first parameter of adapter function consumes one reference when called
   - **Must**: Execute `moonbit_incref(closure)` before each `call(closure, xs[i])`
   - **Consequence**: Forgetting to increment reference count leads to use-after-free or memory leaks

### Memory Management Points

- **Closure lifetime**: Increment closure reference count before each call
- **In-place modification**: Directly modify array elements `xs[i] = call(closure, xs[i])`
- **No manual release**: Due to `#borrow` attribute, MoonBit compiler-generated code automatically manages memory

## Test Case Analysis

```{literalinclude} /sources/native-ffi/src/funcref_map_inplace/top.mbt
:language: moonbit
:lines: 19-39
```

### Test Highlights

1. **Counter closure**: Transformation function captures external variable `i` to count call times
2. **Identity transformation**: Function returns input Point unchanged, focus is on verifying call count
3. **Multiple call verification**:
   - After first call: `i = 8` (4 elements × 2 calls each)
   - After second call: `i = 16`
   - After third call: `i = 24`

### Call Count Calculation

For an array of length 4:
- Each element is transformed 2 times in one `map_inplace` call
- Total: 4 × 2 = 8 function calls
- Three `map_inplace` calls: 8 × 3 = 24 times

## Design Pattern Analysis

### Adapter Pattern Application

```moonbit
ffi_map_inplace(xs, fn(f, x) { f(x) }, closure)
```

The `fn(f, x) { f(x) }` here is an adapter function that:
1. Receives closure `f` and parameter `x`
2. Calls closure and returns result
3. Bridges MoonBit closures and C function pointers

### FFI Design Principles

1. **Type safety**: Ensure correct function signatures through type system
2. **Memory safety**: Use `#borrow` to simplify lifetime management
3. **Performance optimization**: In-place modification avoids additional memory allocation
4. **Interface simplification**: Provide clean user interfaces through wrapper functions

## Comparison with Other Examples

| Example | Operation Type | Closure Features | C Implementation Complexity |
|---------|----------------|------------------|---------------------------|
| register_callback | Callback registration | Multiple calls | Simple |
| qsort | Comparison sorting | Returns integer | Medium (cross-platform) |
| qsort_closure | Comparison sorting | Variable capture | Medium |
| map_inplace | Element transformation | Returns object | Simple |

## Key Learning Points

1. **In-place operation pattern**: Understand how to implement efficient in-place array operations through FFI
2. **Object return handling**: Master how to handle closures that return MoonBit objects
3. **Counter pattern**: Learn how to monitor execution through closure-captured state
4. **Performance considerations**: Understand performance advantages of in-place operations compared to creating new arrays
5. **FFI design best practices**: Understand core principles of FFI interface design through this simple example