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
fn Canvas_ctx::set_stroke_color_ffi(
  self : Canvas_ctx,
  color : @extern.JsString,
) = "canvas" "set_stroke_color"

///|
fn Canvas_ctx::set_stroke_color(self : Canvas_ctx, color : String) -> Unit {
  self.set_stroke_color_ffi(@extern.JsString::from_string(color))
}

///|
fn Canvas_ctx::set_line_width(self : Canvas_ctx, width : Double) = "canvas" "set_line_width"

///|
fn Canvas_ctx::stroke_rect(
  self : Canvas_ctx,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) = "canvas" "stroke_rect"

///|
fn Canvas_ctx::fill_rect(
  self : Canvas_ctx,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) = "canvas" "fill_rect"

///|
fn Canvas_ctx::set_fill_style_ffi(self : Canvas_ctx, color : @extern.JsString) = "canvas" "set_fill_style"

///|
fn Canvas_ctx::set_fill_style(self : Canvas_ctx, color : String) -> Unit {
  self.set_fill_style_ffi(@extern.JsString::from_string(color))
}
