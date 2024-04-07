# Foreign Function Interface(FFI)

You can use foreign function in MoonBit through FFI to interact with the hosting runtime when embedded inside the browser or command line applications through [Wasmtime](https://wasmtime.dev/) or similar projects.

⚠ Warning: MoonBit is still in early stage, so the content may be outdated.

## FFI

### Declare Foreign Reference

You can declare a foreign reference type like this:

```rust
type Canvas_ctx
```

This will be a type that represents a reference to a foreign object, a `CanvasRenderingContext2D` object held by the hosting JavaScript runtime in this example.

### Declare Foreign Function

You can declare a foreign function like this:

```rust
fn get_pi() -> Double = "math" "PI"
```

It's similar to a normal function definition except that the function body is replaced with two strings.

These two strings are used to identify the specific function from a Wasm import object, the first string is the module name, and the second string is the function name.

After declaration, you can use foreign functions like regular functions.

You may also declare a foreign function that will be invoked upon a foreign object by using the foreign reference type like this:

```rust
fn begin_path(self: Canvas_ctx) = "canvas" "begin_path"
```

and apply it to a previously owned reference normally such as `context.begin_path()`.

### Use compiled Wasm

To use the compiled Wasm, you need to initialize the Wasm module with the host functions so as to meet the needs of the foreign functions, and then use the exported functions provided by the Wasm module.

#### Provide host functions

To use the compiled Wasm, you must provide **All** declared foreign functions in Wasm import object.

For example, to use wasm compiled from above code snippet in JavaScript:

```js
WebAssembly.instantiateStreaming(fetch("xxx.wasm"), {
  math: {
    PI: () => Math.PI,
  },
});
```

Check out the documentation such as [MDN](https://developer.mozilla.org/en-US/docs/WebAssembly) or the manual of runtime that you're using to embed the Wasm.

#### Use exported functions

Functions that are not methods nor polymorphic functions can be exported if they are public and if the link configuration appears in the `moon.pkg.json` of the package:

```json
{
  "link": {
    "wasm": {
      "exports": [
        "add",
        "fib:test"
      ]
    }
  }
}
```

The example above will export function `add` and `fib` if compiled with the default wasm backend, and the function `fib` will be exported with the name of `test`.

The `_start` function should always be called to initialize all the global instances defined in MoonBit program.

## Example: Smiling face

Let's walk through a full example to draw a smiling face using Canvas API in MoonBit. Suppose you created a new project with `moon new draw`

```moonbit title="lib/draw.mbt"
// We first declare a type representing the context of canvas
type Canvas_ctx

// We then declare the foreign function interfaces
fn begin_path(self : Canvas_ctx) = "canvas" "beginPath"
fn arc(self : Canvas_ctx, x : Int, y : Int, radius : Int, start_angle : Double,
    end_angle : Double, counterclockwise : Bool) = "canvas" "arc"
fn move_to(self : Canvas_ctx, x : Int, y : Int) = "canvas" "moveTo"
fn stroke(self : Canvas_ctx) = "canvas" "stroke"

fn get_pi() -> Double = "math" "PI"
let pi : Double = get_pi()

// We then apply these functions to define the drawing function upon the context
pub fn draw(self : Canvas_ctx) -> Unit {
  self.begin_path()
  self.arc(75, 75, 50, 0.0, pi * 2.0, true) // Outer circle
  self.move_to(110, 75)
  self.arc(75, 75, 35, 0.0, pi, false) // Mouth (clockwise)
  self.move_to(65, 65)
  self.arc(60, 65, 5, 0.0, pi * 2.0, true) // Left eye
  self.move_to(95, 65)
  self.arc(90, 65, 5, 0.0, pi * 2.0, true) // Right eye
  self.stroke()
}

// We also demonstrate the `println` functionality here
pub fn display_pi() -> Unit {
  println("PI: \(pi)")
}
```

```json title="lib/moon.pkg.json"
{
  "link": {
    "wasm": {
      "exports": ["draw", "display_pi"]
    },
    "wasm-gc": {
      "exports": ["draw", "display_pi"]
    }
  }
}
```

Build the project using `moon build --target wasm-gc`. We recommend using the wasm-gc feature whenever possible. If the environment does not support wasm-gc feature, simply omit the `--target wasm-gc` option.

We now can use it from JavaScript.

```html title="./index.html"
<html lang="en">
  <body>
    <canvas id="canvas" width="150" height="150"></canvas>
  </body>
  <script>
    // import object for defining the FFI
    const importObject = {
      // TODO
    }

    const canvas = document.getElementById("canvas");
    if (canvas.getContext) {
      const ctx = canvas.getContext("2d");
      WebAssembly.instantiateStreaming(fetch("target/wasm-gc/release/build/lib/lib.wasm"), importObject).then(
        (obj) => {
          // Always call _start to initialize the environment
          obj.instance.exports._start();
          // Pass the JS object as parameter to draw the smiling face
          obj.instance.exports["draw"](ctx);
          // Display the value of PI
          obj.instance.exports["display_pi"]();
        }
      );
    }
  </script>
</html>
```

For import object, we need to provide all the FFI used in the previously defined program: the canvas rendering API, the math API and finally, an API for printing to the console used by the `println` or `print` function.

As of the canvas rendering API and the math API, we can use the following code to convert the methods of objects into function calls that accept the object as the first parameter, and convert the constant properties of objects into functions that returns the value:

```javascript
function prototype_to_ffi(prototype) {
  return Object.fromEntries(
    Object.entries(Object.getOwnPropertyDescriptors(prototype))
      .filter(([_key, value]) => value.value)
      .map(([key, value]) => {
        if (typeof value.value == 'function')
          return [key, Function.prototype.call.bind(value.value)]
        // TODO: it is also possible to convert properties into getters and setters
        else
          return [key, () => value.value]
      })
  );
}

const importObject = {
  canvas: prototype_to_ffi(CanvasRenderingContext2D.prototype),
  math: prototype_to_ffi(Math),
  // ...
}
```

As of the printing service, we can provide the following closure so that it buffers the bytes of string until it needs to be logged to the console:

```javascript
const [log, flush] = (() => {
  var buffer = [];
  function flush() {
    if (buffer.length > 0) {
      console.log(new TextDecoder("utf-16").decode(new Uint16Array(buffer).valueOf()));
      buffer = [];
    }
  }
  function log(ch) {
    if (ch == '\n'.charCodeAt(0)) { flush(); }
    else if (ch == '\r'.charCodeAt(0)) { /* noop */ }
    else { buffer.push(ch); }
  }
  return [log, flush]
})();

const importObject = {
  // ...
  spectest: {
    print_char: log
  },
}

// ...
WebAssembly.instantiateStreaming(fetch("target/wasm-gc/release/build/hello.wasm"), importObject).then(
  (obj) => {
    obj.instance.exports._start();
    // ...
    flush()
  }
);
```

Now, we put them together, so this is our final complete `index.html`:

```html title="./index.html
<!DOCTYPE html>
<html>

<head></head>

<body>
  <canvas id="canvas" width="150" height="150"></canvas>
  <script>
    function prototype_to_ffi(prototype) {
      return Object.fromEntries(
        Object.entries(Object.getOwnPropertyDescriptors(prototype))
          .filter(([_key, value]) => value.value)
          .map(([key, value]) => {
            if (typeof value.value == 'function')
              return [key, Function.prototype.call.bind(value.value)]
            else
              return [key, () => value.value]
          })
      );
    }

    const [log, flush] = (() => {
      var buffer = [];
      function flush() {
        if (buffer.length > 0) {
          console.log(new TextDecoder("utf-16").decode(new Uint16Array(buffer).valueOf()));
          buffer = [];
        }
      }
      function log(ch) {
        if (ch == '\n'.charCodeAt(0)) { flush(); }
        else if (ch == '\r'.charCodeAt(0)) { /* noop */ }
        else { buffer.push(ch); }
      }
      return [log, flush]
    })();



    const importObject = {
      canvas: prototype_to_ffi(CanvasRenderingContext2D.prototype),
      math: prototype_to_ffi(Math),
      spectest: {
        print_char: log
      },
    }

    const canvas = document.getElementById("canvas");
    if (canvas.getContext) {
      const ctx = canvas.getContext("2d");
      WebAssembly.instantiateStreaming(fetch("target/wasm-gc/release/build/hello.wasm"), importObject).then(
        (obj) => {
          obj.instance.exports._start();
          obj.instance.exports["draw"](ctx);
          obj.instance.exports["display_pi"]();
          flush()
        }
      );
    }
  </script>
</body>

</html>
```

Make sure that `draw.wasm` and `index.html` are in the same folder, then start a http server at this folder. For example, using Python:

```bash
python3 -m http.server 8080
```

Goto http://localhost:8080 in your browser, there should be a smile face on the screen and an output on the console:

![](./imgs/smile_face_with_log.png)
