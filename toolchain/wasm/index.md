# WebAssembly Integration

MoonBit is a programming language that provides first-class support for
WebAssembly.

## Component Model

Check out [this tutorial](component-model-tutorial.md) on how to work with
[component model](https://component-model.bytecodealliance.org/) in MoonBit.

## Custom Export and Import

Check out [FFI](../../language/ffi.md) section on how to import or export functions.

## Q&A

1. Q: What is `spectest.print_char`

   A: It's how MoonBit prints. It prints a UTF-16 unicode code at a time. For
   portability, avoid using `println`. If this does occur in the final result,
   consider using [`wasm-merge`](https://github.com/WebAssembly/binaryen) or
   similar tools.
