# Callback Registration Example

```{admonition} ⚠️ Critical Technique: Closure First Parameter Reference Counting
:class: warning

This example uses adapter function type `FuncRef[(() -> Unit) -> Unit]`, note that **closure is the first (and only) parameter**.

**Important rule**: Before each call to this adapter function in C code, you must execute `moonbit_incref(closure)` on the closure, otherwise it will cause use-after-free errors.

The example calls three times, so it needs three `moonbit_incref` calls.
```

This example demonstrates how to implement callback function mechanisms in MoonBit and how to properly manage closure lifetimes.

## Overview

This example implements a callback registration system that allows MoonBit functions to be called multiple times by C code. It showcases MoonBit closure runtime representation and memory management strategies.

## MoonBit Closure Runtime Representation

In the C backend, MoonBit closures are represented as `void*` type pointers:

```{literalinclude} /sources/native-ffi/src/funcref_register_callback/stub.c
:language: c
:start-after: start moonbit closure definition
:end-before: end moonbit closure definition
```

This type definition illustrates how MoonBit closures are represented on the C side. All closure objects are passed through pointers.

## FFI Function Declaration

In MoonBit, we declare an external C function:

```{literalinclude} /sources/native-ffi/src/funcref_register_callback/top.mbt
:language: moonbit
:start-after: start ffi declaration
:end-before: end ffi declaration
```

Key features explanation:

1. **`#borrow` attribute**: Specifies that `call` and `closure` parameters use borrow semantics, avoiding manual reference count management
2. **⚠️ `FuncRef[(() -> Unit) -> Unit]`**: This is a function reference type
   - **First parameter**: `() -> Unit` type closure
   - **Function**: Accepts and calls a closure
   - **Important**: Closure passed as first parameter, consuming one reference when called
3. **`() -> Unit`**: Type of callback function to register

## C Implementation

The C side implementation demonstrates how to properly handle MoonBit closure lifetimes:

```{literalinclude} /sources/native-ffi/src/funcref_register_callback/stub.c
:language: c
:start-after: start register_callback definition
:end-before: end register_callback definition
```

### Memory Management Details

1. **⚠️ Critical reference counting technique**: Need to call `moonbit_incref(closure)` before each closure call
   - **Reason**: In `call(closure)`, closure as first parameter will be consumed by adapter function
   - **Rule**: Must `moonbit_incref` before each call, otherwise closure is freed on second call
   - **Example**: Three calls in code, so three `moonbit_incref` calls
2. **Calling convention**: `call(closure)` directly calls the passed function pointer, MoonBit compiler handles closure expansion and calling at compile time
3. **Multiple calls**: Example demonstrates how to call the same closure multiple times

## Wrapper Function

MoonBit provides a convenient wrapper function:

```{literalinclude} /sources/native-ffi/src/funcref_register_callback/top.mbt
:language: moonbit
:start-after: start wrapper function
:end-before: end wrapper function
```

This wrapper function:

1. Creates a `FuncRef` type adapter function `fn(f) { f() }`
2. Passes user-provided closure to C function
3. Hides underlying FFI complexity

## Test Case

The example includes a complete test case:

```{literalinclude} /sources/native-ffi/src/funcref_register_callback/top.mbt
:language: moonbit
:start-after: start test case
:end-before: end test case
```

### Test Description

1. **Variable capture**: Closures capture external variables `s1` and `s2`, demonstrating closure variable capture capability
2. **Multiple execution**: Each registered callback is executed 3 times
3. **State maintenance**: Uses `StringBuilder` to collect output, verifying correct callback execution

## Key Learning Points

1. **FuncRef vs Closure**: `FuncRef` type is for functions that don't capture variables, while closures can capture external variables
2. **Lifetime management**: Use `#borrow` attribute to simplify reference count management
3. **Runtime representation**: Understand MoonBit closure memory layout and representation on C side
4. **Calling convention**: Master correct closure calling and memory management patterns