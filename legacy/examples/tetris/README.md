# Tetris in MoonBitLang

`lib/tetris.mbt` implements the execution logic of the tetris.

`lib/draw.mbt` uses `canvas` to draw.

## Deps

This example works with the following versions of the environment.

```
❯ moon version
moon 0.1.0 (6865948 2023-09-12)
moonc 7a44af122 /home/luoxuwei/.moon/bin/moonc

❯ wat2wasm --version
1.0.33 (git~1.0.33-30-g2581e8d5)
```

## How to Run
```
make 
```
## Details

### Use External Ref to Call Canvas API
* Create external ref
```
extern type Canvas_ctx

func set_stroke_color(self : Canvas_ctx, color : Int) = "canvas" "set_stroke_color"

func set_line_width(self : Canvas_ctx, width : Float64) = "canvas" "set_line_width"

func stroke_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "stroke_rect"

func fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "fill_rect"

func set_fill_style(self : Canvas_ctx, color : Int) = "canvas" "set_fill_style"

func draw_game_over(self: Canvas_ctx) = "canvas" "draw_game_over"
```
* Draw entry, ref: `lib/draw.mbt/draw(canvas : Canvas_ctx, tetris : Tetris)`
### Load Wasm and Execute It
Create a WebAssembly.Memory
```javascript
const importObject = {
  canvas: {
    stroke_rect: (ctx, x, y, width, height) => ctx.strokeRect(x, y, width, height),
    stroke: (ctx) => ctx.stroke(),
    set_line_width: (ctx, width) => ctx.lineWidth = width,
    fill_rect: (ctx, x, y, width, height) => ctx.fillRect(x, y, width, height),
    set_stroke_color: (ctx, color) => ctx.strokeStyle = colors[color],
    set_fill_style: (ctx, color) => ctx.fillStyle = colors[color],
  },
  spectest: {
      print_i32: (x) => console.log(String(x)),
      print_f64: (x) => console.log(String(x)),
      print_char: (x) => console.log(String.fromCharCode(x)),
    }
};
```
Load Wasm and use `requestAnimationFrame(update)` to draw
```javascript
function update(time = 0) {
  const deltaTime = time - lastTime
  dropCounter += deltaTime
  if (dropCounter > dropInterval) {
    tetris_step(tetris, 0);
    scoreDom.innerHTML = "score: " + tetris_score(tetris)
    dropCounter = 0
  }
  lastTime = time
  tetris_draw(context, tetris);
  requestAnimationFrameId = requestAnimationFrame(update)
}

WebAssembly.instantiateStreaming(fetch("target/tetris.wasm"), importObject).then(
    (obj) => {
      obj.instance.exports._start();
      tetris_draw = obj.instance.exports["tetris/lib::draw"];
      tetris_new = obj.instance.exports["tetris/lib::new"];
      tetris_step = obj.instance.exports["tetris/lib::step"];
      tetris_score = obj.instance.exports["tetris/lib::get_score"]
      tetris = tetris_new();
      requestAnimationFrameId = requestAnimationFrame(update);
    }
  )
```
* Game entry, ref: `lib/tetris.mbt/step(tetris:Tetris, action:Int)`