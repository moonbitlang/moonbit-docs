# Foreign Function Interface(FFI)

You can use foreign function in MoonBit through FFI

## FFI

### Declare Foreign Function

You can declare a foreign function like this:

```rust
fn get_pi() -> Double = "math" "get_pi"
```

It's similar to a normal function definition except that the function body is replaced with two strings.

These two strings are used to identify the specific function from a Wasm import object, the first string is the module name, and the second string is the function name.

After declaration, you can use foreign functions like regular functions.

### Use compiled Wasm

To use the compiled Wasm, you must provide **All** declared foreign functions in Wasm import object.

For example, to use wasm compiled from above code snippet in JavaScript:

```js
WebAssembly.instantiateStreaming(fetch("xxx.wasm"), {
  math: {
    get_pi: () => Math.PI,
  },
});
```

### Full example

Let's walk through a full example to draw a simle face using canvas API in MoonBit.

```moonbit title="./draw.mbt"
type Canvas_ctx

fn begin_path(self: Canvas_ctx) = "canvas" "begin_path"
fn arc(self: Canvas_ctx, x: Int, y: Int, radius: Int, start_angle: Double, end_angle: Double, counterclockwise: Bool) = "canvas" "arc"
fn move_to(self: Canvas_ctx, x: Int, y: Int) = "canvas" "move_to"
fn stroke(self: Canvas_ctx) = "canvas" "stroke"
fn get_pi() -> Double = "canvas" "get_pi"

let pi: Double = get_pi()

pub fn draw(self: Canvas_ctx) {
    self.begin_path();
    self.arc(75, 75, 50, 0.0, pi * 2.0, true); // Outer circle
    self.move_to(110, 75);
    self.arc(75, 75, 35, 0.0, pi, false); // Mouth (clockwise)
    self.move_to(65, 65);
    self.arc(60, 65, 5, 0.0, pi * 2.0, true); // Left eye
    self.move_to(95, 65);
    self.arc(90, 65, 5, 0.0, pi * 2.0, true); // Right eye
    self.stroke();
}
```

Compile the file using `moonc` to get `draw.mbt.wasm`.

```bash
moonc compile draw.mbt
wat2wasm draw.mbt.wat
```

Use it from JavaScript:

```html title="./index.html"
<html lang="en">
  <body>
    <canvas id="canvas" width="150" height="150"></canvas>
  </body>
  <script>
    const spectest = {
      canvas: {
        stroke_rect: (ctx, x, y, width, height) =>
          ctx.strokeRect(x, y, width, height),
        begin_path: (ctx) => ctx.beginPath(),
        arc: (ctx, x, y, radius, startAngle, endAngle, counterclockwise) =>
          ctx.arc(x, y, radius, startAngle, endAngle, counterclockwise),
        move_to: (ctx, x, y) => ctx.moveTo(x, y),
        stroke: (ctx) => ctx.stroke(),
        get_pi: () => Math.PI,
      },
      spectest: {
        print_i32: (x) => console.log(String(x)),
        print_f64: (x) => console.log(String(x)),
        print_char: (x) => console.log(String.fromCharCode(x)),
      },
    };

    const canvas = document.getElementById("canvas");
    if (canvas.getContext) {
      const ctx = canvas.getContext("2d");

      WebAssembly.instantiateStreaming(fetch("draw.wasm"), spectest).then(
        (obj) => {
          obj.instance.exports._start();
          obj.instance.exports["Canvas_ctx::draw"](ctx);
        }
      );
    }
  </script>
</html>
```

Make sure that `draw.mbt.wasm` and `index.html` are in the same folder, then start a http server at this folder. For example, using Python:

```bash
python3 -m http.server 8080
```

Goto http://localhost:8080 in your browser, there should be a smile face like this:

![](./imgs/smile-face.png)
