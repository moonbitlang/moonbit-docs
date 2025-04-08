# Interacting with C library

MoonBit's native backend can call native libraries in C ABI directly at almost no cost.
This page introduces how to interact with C libraries in MoonBit.

## Binding C function
In order to call a foreign function in some C library,
you should first bind the function with the `extern "C"` syntax:

```moonbit
extern "C" fn c_lib_function(..) -> .. = "function_name"
```

Now, you can use `c_lib_function` just like normal MoonBit function.
Under the hood, `c_lib_function` will be linked to the symbol named `function_name`.
There is no need to specify or include any C header,
but do make sure the signature of `c_lib_function` is ABI-compatible with the symbol `function_name` in the C library.

## Linking with C library
If a package needs to dynamically link with foreign C library, add the following to `moon.pkg.json`:

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

`cc-link-flags` would be passed to C compiler directly.

## ABI when interacting with C
When binding foreign C functions,
it is vital to ensure the binding has the same ABI as the actual foreign function.
The table below shows the ABI of different kinds of MoonBit types:

| MoonBit type | C ABI      |
|--------------|------------|
| `Int`        | `int32_t`  |
| `UInt`       | `uint32_t` |
| `Int64`      | `int64_t`  |
| `UInt64`     | `uint64_t` |
| constant `enum` | `int32_t` |
| abstract type (`type T`) | pointer (must be valid MoonBit object) |
| external type (`extern type T`) | `void*` |
| `FixedArray[Byte]`/`Bytes` | `uint8_t*` |
| `FixedArray[T]` | `T*` |
| newtype | same as underlying type |

Types not mentioned above have an unstable ABI, so your code should not depend on their current representation.

MoonBit's automatic memory management requires a small object header in front of every MoonBit value on the heap.
So it is invalid to convert a foreign pointer to regular MoonBit type.
To represent foreign pointer to non-MoonBit object in C FFI, you use the `extern type T` syntax.
Types defined in this way will be ignored by MoonBit's automatic memory management system,
and need no object header.

The ABI of `Unit` is unstable.
Don't write any return type annotation if you want to bind a C function that returns nothing (`void`),

## Passing callback to C
Sometimes, we need to pass a MoonBit function to C as callback.
For this purpose, MoonBit provides a special type `FuncRef[T]`,
which represents capture-free function of type `T`.
Values of type `FuncRef[T]` must be capture free function of type `T`.
In C FFI, `FuncRef[T]` will correspond to function pointer with signature `T`,
and it is guaranteed that `FuncRef[(..) -> Unit]` will correspond to `void`-returning functions in C
(although the ABI of `Unit` itself is unstable).
Here's an example of binding the UNIX `signal` function:

```moonbit
enum Signal {
  SIGHUP = 1
  SIGINT = 2
  SIGQUIT = 3
} derive(Show)

typealias SignalHandler = FuncRef[(Signal) -> Unit]

extern "C" fn signal(
  signum : Signal,
  handler : SignalHandler
) -> SignalHandler = "signal"

fn init {
  signal(SIGQUIT, fn (sig) {
    println("received signal \{sig}")
  })
}
```

### Passing closure to C
Some C library functions allow supplying extra data in addition to the callback function.
Assume we have the following C library function:

```c
void register_callback(void (*callback)(void*), void *data);
```

we can bind this C function and pass closure to it using the following trick:

```moonbit
extern "C" fn register_callback_ffi(
  callback : FuncRef[(() -> Unit) -> Unit],
  data : () -> Unit
) = "register_callback"

fn register_callback(callback : () -> Unit) -> Unit {
  register_callback_ffi(
    fn (closure_callback) { closure_callback() },
    callback
  )
}
```

Here, we treat the MoonBit closure as opaque data passed to the C function,
and use a capture-free wrapper to invoke the closure.

## Writing C stub
Some C functions are difficult to bind using pure MoonBit syntax.
In this case, you can write some simple C wrapper functions to glue the C side and the MoonBit side.
To add a C stub file to a package, add the following to the `moon.pkg.json` of the package:

```json
{
  // ...
  "native-stub": [ 
    // list of stub file names
  ],
  // ...
}
```

Now, you can write your C wrappers in the listed C files and bind them in MoonBit.
You would probably like to `#include "moonbit.h"`,
which contains type definitions and handy utilities for MoonBit's C interface.
The header itself is usually located in `~/.moon/include`, check its content for more details.

## Lifetime management of external object
When handling foreign object/resource in MoonBit,
it is important to free the object/resource in time to prevent memory/resource leak.
`moonbit.h` provides an API `moonbit_make_external_object`
for handling lifetime of external object/resource using MoonBit's own automatic memory management system:

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

so you can treat the object as a pointer to its payload directly.
When MoonBit's automatic memory management system finds that
an object created by `moonbit_make_external_object` is no longer alive,
it will invoke the function `finalize` with the object itself as argument.
Now, `finalize` can release external resource/memory held by the object's payload.
Notice that `finalize` **must not** drop the object itself, as this is handled by MoonBit runtime.

On the MoonBit side, objects returned by `moonbit_make_external_object`
should be bind to an *abstract* type, declared using `type T`,
so that MoonBit's memory management system will not ignore the object.

## Lifetime management of MoonBit object
MoonBit's native backend uses compiler-optimized reference counting to manage lifetime of objects.
To avoid memory error or leak, FFI functions must properly maintain the reference count of MoonBit objects.

### Which types are reference counted?
The following types are always unboxed, so there is no need to manage their lifetime:

- builtin number types, such as `Int` and `Double`
- constant `enum` (`enum` where all constructors have no payload)

The following types are always boxed and reference counted:

- `FixedArray[T]`, `Bytes` and `String`
- abstract types (`type T`)

External types (`extern type T`) are also boxed, but they represent external pointers,
so MoonBit will not perform any reference counting operations on them.

The layout of `struct`/`enum` with payload is currently unstable.

### The calling convention of reference counting
By default, MoonBit uses an owned calling convention for reference counting.
That is, callee (the function being invoked) is responsible for
dropping its parameters using the `moonbit_decref` function.
If the parameter is used more than once,
the callee should increase the reference count using the `moonbit_incref` function.
Here are the rules for the necessary operations to perform in different circumstances:

| event | operation |
|-------|-----------|
| read field/element | nothing |
| store into data structure | `incref` |
| passed to MoonBit function | `incref` |
| passed to other C function | nothing |
| returned | nothing |
| end of scope (not returned) | `decref` |

For example, here's a lifetime-correct binding to the standard `open` function for opening a file:

```moonbit
extern "C" open(filename : Bytes, flags : Int) -> Int = "open_ffi"
```

```c
int open_ffi(moonbit_bytes_t filename, int flags) {
  int fd = open(filename, flags);
  moonbit_decref(filename);
  return fd;
}
```

### The borrow attribute
To properly maintain reference count, it is often necessary to write a stub C function just to perform `decref`.
Fortunately, MoonBit provides a `#borrow` attribute to change the calling convention of C FFI to borrow based.
The syntax of `#borrow` is as follows:

```moonbit
#borrow(params..)
extern "C" fn c_ffi(..) -> .. = ..
```

where `params` is a subset of the parameters of `c_ffi`.
Parameters of `#borrow` will be passed using borrow based calling convention,
that is, the invoked function does not need to drop these parameters.
If the FFI function only read its parameter locally (i.e. does not return its parameters or store them in data structures),
there is no need to write a stub function using the `#borrow` attribute.
For example, the `open` function mentioned above could be rewritten using `#borrow` as follows:

```moonbit
#borrow(filename)
extern "C" fn open(filename : Bytes, flags : Int) -> Int = "open"
```

There is no need for a C stub anymore: we are binding to the original version of `open` here.
With the `#borrow` attribute, this version is still lifetime-correct.

Even if a C stub is still necessary for other reasons, `#borrow` can often simplify the lifetime management of the C stub.
Here are the rules for the necessary operations to perform **on borrow parameters** in different circumstances:

| event | operation |
|-------|-----------|
| read field/element | nothing |
| store into data structure | `incref` |
| passed to MoonBit function | `incref` |
| passed to other C function/`#borrow` MoonBit function | nothing |
| returned | `incref` |
| end of scope (not returned) | nothing |
