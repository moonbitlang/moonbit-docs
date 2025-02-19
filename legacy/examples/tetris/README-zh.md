# 用 MoonBitLang 实现俄罗斯方块

`lib/tetris.mbt` 实现了俄罗斯方块的执行逻辑。

`lib/draw.mbt` 使用 `canvas` 进行绘制。

## 依赖项

此示例在以下版本的环境中可以正常运行。

```
❯ moon version
moon 0.1.0 (6865948 2023-09-12)
moonc 7a44af122 /home/luoxuwei/.moon/bin/moonc

❯ wat2wasm --version
1.0.33 (git~1.0.33-30-g2581e8d5)
```

## 运行方法

```
make
```

## 详细信息

### 使用外部引用调用 Canvas API

- 创建外部引用

```
type Canvas_ctx

func set_stroke_color(self : Canvas_ctx, color : Int) = "canvas" "set_stroke_color"

func set_line_width(self : Canvas_ctx, width : Float64) = "canvas" "set_line_width"

func stroke_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "stroke_rect"

func fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "fill_rect"

func set_fill_style(self : Canvas_ctx, color : Int) = "canvas" "set_fill_style"

func draw_game_over(self: Canvas_ctx) = "canvas" "draw_game_over"
```

- 绘制入口，参考：`lib/draw.mbt/draw(canvas : Canvas_ctx, tetris : Tetris)`

### 加载 WebAssembly 并执行

创建一个 WebAssembly.Memory

```javascript
const importObject = {
  canvas: {
    stroke_rect: (ctx, x, y, width, height) =>
      ctx.strokeRect(x, y, width, height),
    stroke: (ctx) => ctx.stroke(),
    set_line_width: (ctx, width) => (ctx.lineWidth = width),
    fill_rect: (ctx, x, y, width, height) => ctx.fillRect(x, y, width, height),
    set_stroke_color: (ctx, color) => (ctx.strokeStyle = colors[color]),
    set_fill_style: (ctx, color) => (ctx.fillStyle = colors[color])
  },
  spectest: {
    print_i32: (x) => console.log(String(x)),
    print_f64: (x) => console.log(String(x)),
    print_char: (x) => console.log(String.fromCharCode(x))
  }
}
```

加载 WebAssembly 并使用 `requestAnimationFrame(update)` 进行绘制

```javascript
function update(time = 0) {
  const deltaTime = time - lastTime
  dropCounter += deltaTime
  if (dropCounter > dropInterval) {
    tetris_step(tetris, 0)
    scoreDom.innerHTML = 'score: ' + tetris_score(tetris)
    dropCounter = 0
  }
  lastTime = time
  tetris_draw(context, tetris)
  requestAnimationFrameId = requestAnimationFrame(update)
}

WebAssembly.instantiateStreaming(
  fetch('target/tetris.wasm'),
  importObject
).then((obj) => {
  obj.instance.exports._start()
  tetris_draw = obj.instance.exports['tetris/lib::draw']
  tetris_new = obj.instance.exports['tetris/lib::new']
  tetris_step = obj.instance.exports['tetris/lib::step']
  tetris_score = obj.instance.exports['tetris/lib::get_score']
  tetris = tetris_new()
  requestAnimationFrameId = requestAnimationFrame(update)
})
```

- 游戏入口，参考：`lib/tetris.mbt/step(tetris:Tetris, action:Int)`
