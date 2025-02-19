# 生命游戏

我们使用 MoonBit 来实现生命游戏。部分代码参考：https://github.com/mununki/moonbit-wasm-game-of-life

`lib/game_of_life.mbt` 实现了生命游戏的执行逻辑。

`lib/draw.mbt` 使用 `canvas` 进行绘制。

## 运行方法

```
make run
```

## 详细信息

### 使用外部引用调用 Canvas API

- 创建外部引用

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

- 绘制网格，参考：`lib/draw.mbt/draw_grid(canvas : Canvas_ctx)`
- 绘制细胞，参考：`lib/draw.mbt/draw_cell(canvas : Canvas_ctx)`

### 加载 WebAssembly 并执行

创建一个 WebAssembly.Memory

```javascript
const importObject = {
  canvas: {
    stroke_rect: (ctx, x, y, width, height) =>
      ctx.strokeRect(x, y, width, height),
    stroke: (ctx) => ctx.stroke(),
    move_to: (ctx, x, y) => ctx.moveTo(x, y),
    line_to: (ctx, x, y) => ctx.lineTo(x, y),
    begin_path: (ctx) => ctx.beginPath(),
    fill_rect: (ctx, x, y, width, height) => ctx.fillRect(x, y, width, height),
    set_stroke_color: (ctx, color) => ctx.setStrokeColor(color),
    set_fill_style: (ctx, color) => ctx.setFillStyle(color)
  },
  spectest: {}
}
```

加载 WebAssembly 并使用 `requestAnimationFrame(renderLoop)` 进行绘制

```javascript
WebAssembly.instantiateStreaming(
  fetch('target/game_of_life.wasm'),
  importObject
).then((obj) => {
  obj.instance.exports._start()
  const drawGrid = obj.instance.exports['game_of_life/lib::draw_grid']
  const drawCell = obj.instance.exports['game_of_life/lib::draw_cell']
  const universe_new = obj.instance.exports['game_of_life/lib::new']
  const universe_tick =
    obj.instance.exports['game_of_life/lib::@game_of_life/lib.Universe::tick']
  const universe = universe_new()
  const renderLoop = () => {
    universe_tick(universe)
    drawGrid(ctx)
    drawCell(ctx, universe)
    requestAnimationFrame(renderLoop)
  }
  requestAnimationFrame(renderLoop)
})
```
