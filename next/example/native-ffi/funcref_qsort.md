# Quick Sort with Comparison Function Example

This example demonstrates how to pass MoonBit comparison functions to the C standard library's `qsort` function, showcasing `FuncRef` type usage in practical algorithms.

## Overview

This example sorts MoonBit's `FixedArray[Point]` by calling the C standard library's `qsort_r` function, demonstrating:

1. How to handle different `qsort_r` signatures across different platforms
2. Using `FuncRef` type as comparison functions
3. Cross-platform compatibility handling

## Data Structure Definition

First, define the `Point` structure used for sorting:

```{literalinclude} /sources/native-ffi/src/funcref_qsort/top.mbt
:language: moonbit
:start-after: start point definition
:end-before: end point definition
```

The `Point` structure derives multiple traits, including `Compare`, allowing us to directly use the `compare` method for comparison.

## FFI Function Declaration

MoonBit side FFI declaration:

```{literalinclude} /sources/native-ffi/src/funcref_qsort/top.mbt
:language: moonbit
:start-after: start qsort ffi declaration
:end-before: end qsort ffi declaration
```

Key features:

1. **`#borrow` attribute**: Avoids manual reference count management
2. **`FixedArray[Point]`**: Represented as `Point*` on the C side
3. **`FuncRef[(Point, Point) -> Int]`**: Comparison function type, returns integer indicating comparison result

## C Implementation Details

### Type Definitions and Context Structure

```{literalinclude} /sources/native-ffi/src/funcref_qsort/stub.c
:language: c
:start-after: start type definitions
:end-before: end type definitions
```

These type definitions:
- `moonbit_point_t`: C representation of MoonBit Point objects
- `moonbit_fixedarray_point_t`: C representation of Point arrays
- `comp_context`: Context structure wrapping comparison functions

### Cross-platform Comparison Function

Due to different `qsort_r` function signatures on different platforms, conditional compilation is needed:

```{literalinclude} /sources/native-ffi/src/funcref_qsort/stub.c
:language: c
:start-after: start cross platform comparison function
:end-before: end cross platform comparison function
```

### Memory Management

In the comparison function:
1. **Reference count increment**: Call `moonbit_incref` to increase parameter reference counts
2. **Function call**: Call MoonBit comparison function through function pointer
3. **Automatic cleanup**: Due to `#borrow` usage, MoonBit compiler-generated code automatically handles reference counting

### Main Sorting Function

```{literalinclude} /sources/native-ffi/src/funcref_qsort/stub.c
:language: c
:start-after: start main qsort function
:end-before: end main qsort function
```

### Cross-platform Compatibility

Different platforms use different sorting functions:
- **Windows**: Uses `qsort_s`
- **macOS**: Uses `qsort_r` (BSD style)
- **Linux**: Uses `qsort_r` (GNU style)

## Test Case

```{literalinclude} /sources/native-ffi/src/funcref_qsort/top.mbt
:language: moonbit
:lines: 14-36
```

Test flow:

1. **Data generation**: Use `@quickcheck.samples` to generate random test data
2. **Comparison function**: Create `FuncRef` type comparison function
3. **Sort comparison**: Use both C's `qsort` and MoonBit's `sort` method
4. **Result verification**: Ensure both sorting methods produce identical results

## Key Learning Points

1. **Cross-platform handling**: Learn how to handle differences in C standard libraries across platforms
2. **Function pointer passing**: Master techniques for passing MoonBit functions as C function pointers
3. **Memory safety**: Understand the importance of correctly managing reference counts in callback functions
4. **Type mapping**: Learn how MoonBit complex types are represented on the C side
5. **Context passing**: Pass additional context information to callback functions through structures