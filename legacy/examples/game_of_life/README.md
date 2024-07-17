# Game of Life
We use MoonBit to implement the game of life. Some codes refer: https://github.com/mununki/moonbit-wasm-game-of-life

`lib/game_of_life.mbt` implements the execution logic of the game of life.

`lib/draw.mbt` uses `canvas` to draw.

## How to Run
```
make run
```
## Details

### Use External Ref to Call Canvas API
* Create external ref
```
type Canvas_ctx

func set_stroke_color(self : Canvas_ctx, color : Int) = "canvas" "set_stroke_color"

func move_to(self : Canvas_ctx, x : Int, y : Int) = "canvas" "move_to"

func line_to(self : Canvas_ctx, x : Int, y : Int) = "canvas" "line_to"

func begin_path(self : Canvas_ctx) = "canvas" "begin_path"

func stroke(self : Canvas_ctx) = "canvas" "stroke"

func fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "fill_rect"

func set_fill_style(self : Canvas_ctx, color : Int) = "canvas" "set_fill_style"
```
* Draw grid, ref: `lib/draw.mbt/draw_grid(canvas : Canvas_ctx)`
* Draw cell, ref: `lib/draw.mbt/draw_cell(canvas : Canvas_ctx)`
### Load Wasm and Execute It
Create a WebAssembly.Memory
```javascript
const importObject = {
  canvas: {
    stroke_rect: (ctx, x, y, width, height) => ctx.strokeRect(x, y, width, height),
    stroke: (ctx) => ctx.stroke(),
    move_to: (ctx, x, y) => ctx.moveTo(x, y),
    line_to: (ctx, x, y) => ctx.lineTo(x, y),
    begin_path: (ctx) => ctx.beginPath(),
    fill_rect: (ctx, x, y, width, height) => ctx.fillRect(x, y, width, height),
    set_stroke_color: (ctx, color) => ctx.setStrokeColor(color),
    set_fill_style: (ctx, color) => ctx.setFillStyle(color),
  },
  spectest: {},
};
```
Load Wasm and use `requestAnimationFrame(renderLoop)` to draw
```javascript
  WebAssembly.instantiateStreaming(fetch("target/game_of_life.wasm"), importObject).then(
    (obj) => {
      obj.instance.exports._start();
      const drawGrid = obj.instance.exports["game_of_life/lib::draw_grid"];
      const drawCell = obj.instance.exports["game_of_life/lib::draw_cell"];
      const universe_new = obj.instance.exports["game_of_life/lib::new"];
      const universe_tick = obj.instance.exports["game_of_life/lib::@game_of_life/lib.Universe::tick"];
      const universe = universe_new();
      const renderLoop = () => {
        universe_tick(universe);
        drawGrid(ctx);
        drawCell(ctx, universe);
        requestAnimationFrame(renderLoop);
      }
      requestAnimationFrame(renderLoop);
    }
  )
```