//  Copyright 2024 International Digital Economy Academy
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

///|
#external
type Canvas_ctx

///|
fn Canvas_ctx::begin_path(self : Canvas_ctx) = "canvas" "begin_path"

///|
fn Canvas_ctx::clear_rect(
  self : Canvas_ctx,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) = "canvas" "clear_rect"

///|
fn Canvas_ctx::move_to(self : Canvas_ctx, x : Double, y : Double) = "canvas" "move_to"

///|
fn Canvas_ctx::line_to(self : Canvas_ctx, x : Double, y : Double) = "canvas" "line_to"

///|
fn Canvas_ctx::stroke(self : Canvas_ctx) = "canvas" "stroke"

///|
fn sqrt(x : Double) -> Double = "canvas" "sqrt"

///|
fn cos(x : Double) -> Double = "canvas" "cos"

///|
fn get_pi() -> Double = "canvas" "get_pi"

///|
fn koch(
  ctx : Canvas_ctx,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  n : Double,
  m : Double,
) -> Unit {
  ctx.clear_rect(0.0, 0.0, 400.0, 400.0)
  let x3 = (x2 - x1) / 3.0 + x1
  let y3 = (y2 - y1) / 3.0 + y1
  let x4 = (x2 - x1) / 3.0 * 2.0 + x1
  let y4 = (y2 - y1) / 3.0 * 2.0 + y1
  let x5 = x3 + (x2 - x1 - (y2 - y1) * sqrt(3.0)) / 6.0
  let y5 = y3 + ((x2 - x1) * sqrt(3.0) + (y2 - y1)) / 6.0
  let n = n + 1.0
  if n == m {
    ctx.move_to(x1, y1)
    ctx.line_to(x3, y3)
    ctx.line_to(x5, y5)
    ctx.line_to(x4, y4)
    ctx.line_to(x2, y2)
    ctx.stroke()
    return
  }
  koch(ctx, x1, y1, x3, y3, n, m)
  koch(ctx, x3, y3, x5, y5, n, m)
  koch(ctx, x5, y5, x4, y4, n, m)
  koch(ctx, x4, y4, x2, y2, n, m)
}

///|
pub fn draw(ctx : Canvas_ctx, deep : Double) -> Unit {
  ctx.begin_path()
  let y = 80.0 + cos(get_pi() / 6.0) * 200.0
  koch(ctx, 150.0, y, 250.0, 80.0, 0.0, deep)
  koch(ctx, 250.0, 80.0, 50.0, 80.0, 0.0, deep)
  koch(ctx, 50.0, 80.0, 150.0, y, 0.0, deep)
}
