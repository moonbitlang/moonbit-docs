# Foreign Function Interface (FFI)

What we've introduced is about describing pure computation. In reality, you'll need
to interact with the real world. However, the "world" is different for each backend (C, JS, Wasm, WasmGC)
and is sometimes based on runtime ([Wasmtime](https://wasmtime.dev/), Deno, Browser, etc.).

## Backends

MoonBit currently have five backends:

- Wasm
- Wasm GC
- JavaScript
- C
- LLVM (experimental)

`````````{tab-set}

``````{tab-item} Wasm
:sync: wasm1
By Wasm we refer to WebAssembly with some post-MVP proposals including:
- bulk-memory-operations
- multi-value
- reference-types

For better compatibility, the `init` function will be compiled as [`start` function](https://webassembly.github.io/spec/core/syntax/modules.html#start-function), and the `main` function will be exported as `_start`.

```{note}
For Wasm backends, all functions interacting with outside world relies on the host. For example, the `println` for Wasm and Wasm GC backend relies on importing a function `spectest.print_char` that prints a UTF-16 code unit for each call. The `env` package in standard library and some packages in `moonbitlang/x` relies on specific host function defined for MoonBit runtime. Avoid using them if you want to make the generated Wasm portable.
```
``````

``````{tab-item} Wasm GC
:sync: wasm-gc
By Wasm GC we refer to WebAssembly with Garbage Collection proposal, meaning that data structures will be represented with reference types such as `struct` `array` and the linear memory would not be used by default. It also supports other post-MVP proposals including:
- multi-value
- JS string builtins

For better compatibility, the `init` function will be compiled as [`start` function](https://webassembly.github.io/spec/core/syntax/modules.html#start-function), and the `main` function will be exported as `_start`.

```{note}
For Wasm backends, all functions interacting with outside world relies on the host. For example, the `println` for Wasm and Wasm GC backend relies on importing a function `spectest.print_char` that prints a UTF-16 code unit for each call. The `env` package in standard library and some packages in `moonbitlang/x` relies on specific host function defined for MoonBit runtime. Avoid using them if you want to make the generated Wasm portable.
```
``````

``````{tab-item} JavaScript
:sync: js
JavaScript backend will generate a JavaScript file, which can be a CommonJS module, an ES module or an IIFE based on the [configuration](/toolchain/moon/package.md#js-backend-link-options).
``````

```{tab-item} C
:sync: c
C backend will generate a C file. The MoonBit toolchain will also compile the project and generate an executable based on the [configuration](/toolchain/moon/package.md#native-backend-link-options).
```

```{tab-item} LLVM
:sync: llvm
LLVM backend will generate an object file. The backend is experimental and does not support FFIs.
```

`````````

## Declare Foreign Type

You can declare a foreign type using the `#extern` attribute like this:

```moonbit
#external
type ExternalRef
```

``````{tab-set}
```{tab-item} Wasm & Wasm GC
:sync: wasm1
:sync: wasm-gc

This will be interpreted as an [`externref`](https://webassembly.github.io/spec/core/syntax/types.html#reference-types).
```

```{tab-item} JavaScript
:sync: js

This will be interpreted as a JavaScript value.
```

```{tab-item} C
:sync: c

This will be interpreted as `void*`.
```
``````

## Declare Foreign Function

To interact with the outside world, you can declare foreign functions.

```{note}
MoonBit does not support polymorphic foreign functions.
```

`````````{tab-set}
:sync-group: backends

``````{tab-item} Wasm & Wasm GC
:sync: wasm1
:sync: wasm-gc

There are two ways to declare a foreign function: importing a function or writing an inline function.

You can import a function given the module name and the function name from the runtime host:

```moonbit
fn cos(d : Double) -> Double = "math" "cos"
```

Or you can write an inline function using Wasm syntax:

```moonbit
extern "wasm" fn identity(d : Double) -> Double =
  #|(func (param f64) (result f64))
```

```{note}
When writing the inline function, do not provide a function name.
```

``````

``````{tab-item} JavaScript
:sync: js

There are two ways to declare a foreign function: importing a function or writing an inline function.

You can import a function given the module name and the function name, which will be interpreted as `module.function`. For example,

```moonbit
fn cos(d : Double) -> Double = "Math" "cos"
```

would refer to the function `const cos = (d) => Math.cos(d)`{l=javascript}

Or you can write an inline function defining a JavaScript lambda:

```moonbit
extern "js" fn cos(d : Double) -> Double =
  #|(d) => Math.cos(d)
```
``````

``````{tab-item} C
:sync: c

You can declare a foreign function by importing a function given the function name:

```moonbit
extern "C" fn put_char(ch : UInt) = "function_name"
```

If a package needs to dynamically link with foreign C library, add `cc-link-flags` to `moon.pkg.json`. It would be passed to C compiler directly.

```json
{
  // ...
  "link": {
    "native": {
      "cc-link-flags": "-l<c library>"
    }
  },
  // ...
}
```



To define wrapper functions, you can add a C stub file to a package, and add the following to the `moon.pkg.json` of the package:

```json
{
  // ...
  "native-stub": [ 
    // list of stub file names
  ],
  // ...
}
```

You would probably like to `#include "moonbit.h"`, which contains type definitions and handy utilities for MoonBit's C interface. The header is located in `~/.moon/include`, check its content for more details.
``````
`````````

### Types

When declaring functions, you need to make sure that the signature corresponds to the actual foreign function.
When a function returns nothing (e.g. `void`), ignore the return type annotation in the function declaration.
The table below shows the underlying representation of some MoonBit types:

`````````{tab-set}
:sync-group: backends

``````{tab-item} Wasm
:sync: wasm1

| MoonBit type |   ABI      |
|--------------|------------|
| `Bool`       | `i32`   |
| `Int`        | `i32`   |
| `UInt`       | `i32`   |
| `Int64`      | `i64`   |
| `UInt64`     | `i64`   |
| `Float`      | `f32`   |
| `Double`     | `f64`   |
| constant `enum` | `i32` |
| external type (`#external type T`) | `externref` |
| `FuncRef[T]` | `funcref` |
``````

``````{tab-item} Wasm GC
:sync: wasm-gc

| MoonBit type |   ABI      |
|--------------|------------|
| `Bool`       | `i32`   |
| `Int`        | `i32`   |
| `UInt`       | `i32`   |
| `Int64`      | `i64`   |
| `UInt64`     | `i64`   |
| `Float`      | `f32`   |
| `Double`     | `f64`   |
| constant `enum` | `i32` |
| external type (`#external type T`) | `externref` |
| `String` | `externref` iff JS string builtin is on |
| `FuncRef[T]` | `funcref` |
``````

``````{tab-item} JavaScript
:sync: js

| MoonBit type |   ABI      |
|--------------|------------|
| `Bool`       | `boolean`  |
| `Int`        | `number`   |
| `UInt`       | `number`   |
| `Float`      | `number`   |
| `Double`     | `number`   |
| constant `enum` | `number` |
| external type (`#external type T`) | `any`   |
| `String` | `string` |
| `FixedArray[Byte]`/`Bytes` | `Uint8Array` |
| `FixedArray[T]` / `Array[T]` | `T[]` |
| `FuncRef[T]` | `Function` |

```{note}
The `FixedArray[T]` for numbers may migrate to `TypedArray` in the future.
```

``````

``````{tab-item} C
:sync: c

| MoonBit type |   ABI      |
|--------------|------------|
| `Bool`       | `int32_t`  |
| `Int`        | `int32_t`  |
| `UInt`       | `uint32_t` |
| `Int64`      | `int64_t`  |
| `UInt64`     | `uint64_t` |
| `Float`      | `float`    |
| `Double`     | `double`   |
| constant `enum` | `int32_t` |
| abstract type (`type T`) | pointer (must be valid MoonBit object) |
| external type (`#external type T`) | `void*` |
| `FixedArray[Byte]`/`Bytes` | `uint8_t*` |
| `FixedArray[T]` | `T*` |
| `FuncRef[T]` | Function pointer |

```{note}
If the return type of `T` in `FuncRef[T]` is `Unit`, then it points to a function that returns `void`.
```

``````
`````````

Types not mentioned above do not have a stable ABI, so your code should not depend on their representations.

### Callbacks

Sometimes, we want to pass a MoonBit function to the foreign interface as callback. In MoonBit, it is possible to have closures. Per [MDN glossary](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Closures):

> A closure is the combination of a function bundled together (enclosed) with references to its surrounding state (the lexical environment). In other words, a closure gives a function access to its outer scope. In JavaScript, closures are created every time a function is created, at function creation time.

In some cases, we would like to pass the callback function which doesn't capture any local free variables. For this purpose, MoonBit provides a special type `FuncRef[T]`, which represents closed function of type `T`. Values of type `FuncRef[T]` must be closed function of type `T`, otherwise [a type error](/language/error_codes/E4151.md) would occur.

In other cases, a MoonBit function parameter would be represented as a function and an object containing the surrounding state.

`````````{tab-set}
:sync-group: backends
``````{tab-item} Wasm & Wasm GC
:sync: wasm1
:sync: wasm-gc

For Wasm backends, the callbacks will be passed as `externref`, which represents a function of the host. However, it is essential to convert the function together with the captured data to the host's function. 

To do so, the Wasm module will import a function under the module `moonbit:ffi` and function name `make_closure`. This function takes a function and an object, where the function's first parameter should be the object, and should return a host's function. That is, the host is responsible for doing the partial application. A possible implementation would be:

```javascript
{ 
  "moonbit:ffi": {
    "make_closure": (funcref, closure) => funcref.bind(null, closure)
  } 
}
```
``````

``````{tab-item} JavaScript
:sync: js

JavaScript supports closure, so there's nothing special to be done here.
``````

``````{tab-item} C
:sync: c

Some C library functions allow supplying extra data in addition to the callback function.
Assume we have the following C library function:

```c
void register_callback(void (*callback)(void*), void *data);
```

we can bind this C function and pass closure to it using the following trick:

```moonbit
extern "C" fn register_callback_ffi(
  call_closure : FuncRef[(() -> Unit) -> Unit],
  closure : () -> Unit
) = "register_callback"

fn register_callback(callback : () -> Unit) -> Unit {
  register_callback_ffi(
    fn (f) { f() },
    callback
  )
}
```

``````
`````````

### Customize integer value of constant enum
In all backends of MoonBit, constant enum (`enum` where all constructors have no payload) are translated to integer.
It is possible to customize the actual integer representation of each constructor,
by adding `= <integer literal>` after constructor declaration:

```moonbit
enum SpecialNumbers {
  Zero = 0
  One
  Two
  Three
  Ten = 10
  FourtyTwo = 42
}
```

If a constructor's integer value is unspecified,
it defaults to one plus the value of the previous constructor (or zero for the first constructor).
This feature is particular useful for binding flags of C libraries.

## Export Functions

For public functions that are neither methods nor polymorphic, they can be exported by configuring the `exports` field in [link configuration](/toolchain/moon/package.md#link-options).

```json
{
  "link": {
    "<backend>": {
      "exports": [ "add", "fib:test" ]
    }
  }
}
```

The previous example exports functions `add` and `fib`, where `fib` will be exported as `test`.

`````````{tab-set}
``````{tab-item} Wasm & Wasm GC
:sync: wasm1
:sync: wasm-gc

```{note}
It is only effective for the package that configures it, i.e. it doesn't affect the downstream packages.
```
``````
``````{tab-item} JavaScript
:sync: js

```{note}
It is only effective for the package that configures it, i.e. it doesn't affect the downstream packages.

There's another `format` option to export as CommonJS module (`cjs`), ES Module (`esm`), or `iife`.
```
``````
``````{tab-item} C
:sync: c
```{note}
It is only effective for the package that configures it, i.e. it doesn't affect the downstream packages.

Renaming the exported function is not supported for now
```
``````
`````````

## Lifetime management 

MoonBit is a programming language with garbage collection. Thus when handling external object or passing MoonBit object to host, it is essential to keep in mind the lifetime management. Currently, MoonBit uses reference counting for Wasm backend and C backend. For Wasm GC backend and JavaScript backend, the runtime's GC is reused.

### Lifetime management of external object

When handling external object/resource in MoonBit, it is important to destroy object or release resource in time to prevent memory/resource leak.

```{note}
For C backend only
```

`moonbit.h` provides an API `moonbit_make_external_object` for handling lifetime of external object/resource using MoonBit's own automatic memory management system:

```c
void *moonbit_make_external_object(
  void (*finalize)(void *self),
  uint32_t payload_size
);
```

`moonbit_make_external_object` will create a new MoonBit object of size `payload_size + sizeof(finalize)`,
the layout of the object is as follows:

```
| MoonBit object header | ... payload | finalize function |
                        ^
                        |
                        |_
                           pointer returned by `moonbit_make_external_object`
```

so you can treat the object as a pointer to its payload directly. When MoonBit's automatic memory management system finds that an object created by `moonbit_make_external_object` is no longer alive, it will invoke the function `finalize` with the object itself as argument. Now, `finalize` can release external resource/memory held by the object's payload. 

```{note}
`finalize` **must not** drop the object itself, as this is handled by MoonBit runtime.
```

On the MoonBit side, objects returned by `moonbit_make_external_object`
should be bind to an *abstract* type, declared using `type T`,
so that MoonBit's memory management system will not ignore the object.


### Lifetime management of MoonBit object

When passing MoonBit objects to the host through functions, it is essential to take care of the lifetime management of MoonBit itself. As mentioned before, MoonBit's Wasm backend and C backend uses compiler-optimized reference counting to manage lifetime of objects. To avoid memory error or leak, FFI functions must properly maintain the reference count of MoonBit objects.

```{note}
For C backend and for Wasm backend only.
```

#### The calling convention of reference counting

By default, MoonBit uses an owned calling convention for reference counting. That is, callee (the function being invoked) is responsible for dropping its parameters using the `moonbit_decref` / `$moonbit.decref` function. If the parameter is used more than once, the callee should increase the reference count using the `moonbit_incref` / `$moonbit.incref` function. Here are the rules for the necessary operations to perform in different circumstances:

| event | operation |
|-------|-----------|
| read field/element | nothing |
| store into data structure | `incref` |
| passed to MoonBit function | `incref` |
| passed to other foreign function | nothing |
| returned | nothing |
| end of scope (not returned) | `decref` |

For example, here's a lifetime-correct binding to the standard `open` function for opening a file:

```moonbit
extern "C" fn open(filename : Bytes, flags : Int) -> Int = "open_ffi"
```

```c
int open_ffi(moonbit_bytes_t filename, int flags) {
  int fd = open(filename, flags);
  moonbit_decref(filename);
  return fd;
}
```

#### The managed types

The following types are always unboxed, so there is no need to manage their lifetime:

- builtin number types, such as `Int` and `Double`
- constant `enum` (`enum` where all constructors have no payload)

The following types are always boxed and reference counted:

- `FixedArray[T]`, `Bytes` and `String`
- abstract types (`type T`)

External types (`#external type T`) are also boxed, but they represent external pointers,
so MoonBit will not perform any reference counting operations on them.

The layout of `struct`/`enum` with payload is currently unstable.

#### The borrow and owned attribute

When passing a parameter through the FFI, its ownership may or may not be kept.
The `#borrow` and `#owned` attributes can be used to specify these two conditions.

```{warning}
We are in the process of migrating the default semantics to `#borrow` instead of `#owned`
```

The syntax of `#borrow` and `#owned` are as follows:

```moonbit
#borrow(params..)
extern "C" fn c_ffi(..) -> .. = ..
```

where `params` is a subset of the parameters of `c_ffi`.

Parameters of `#borrow` will be passed using borrow based calling convention, that is, the invoked function does not need to `decref` these parameters. If the FFI function only read its parameter locally (i.e. does not return its parameters and does not store them in data structures), you can directly use the `#borrow` attribute. For example, the `open` function mentioned above could be rewritten using `#borrow` as follows:

```moonbit
#borrow(filename)
extern "C" fn open(filename : Bytes, flags : Int) -> Int = "open"
```

There is no need for a stub function anymore: we are binding to the original version of `open` here. With the `#borrow` attribute, this version is still lifetime-correct.

Even if a stub function is still necessary for other reasons, `#borrow` can often simplify the lifetime management. Here are the rules for the necessary operations to perform **on borrow parameters** in different circumstances:

| event | operation |
|-------|-----------|
| read field / element | nothing |
| store into data structure | `incref` |
| passed to MoonBit function | `incref` |
| passed to other C function / `#borrow` MoonBit function | nothing |
| returned | `incref` |
| end of scope (not returned) | nothing |

The opposite is the `#owned` semantic, where the parameter is stored by the FFI function, and the `decref` needs to be executed manually later.
One use case is registering the callback where the closure would be **owned**.