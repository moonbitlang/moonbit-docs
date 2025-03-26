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
  ...
  "link": {
    "native": {
      "cc-link-flags": "-l<c library>"
    }
  },
  ...
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
  ...
  "native-stub": [ <list of stub file names> ],
  ...
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
Design still evolving, TODO
