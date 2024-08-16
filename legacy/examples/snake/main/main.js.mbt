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

extern "js" fn request_animation_frame(callback : (Double) -> Unit) -> Int =
  #|window.requestAnimationFrame

extern "js" fn set_on_keydown(callback : (KeyboardEvent) -> Unit) =
  #|(callback) => { document.onkeydown = callback }

extern "js" fn get_context() -> @lib.Canvas_ctx =
  #|() => {
  #|  const context = globalThis["canvas"].getContext("2d");
  #|  context.scale(24, 24);
  #|  return context;
  #|}

type KeyboardEvent

extern "js" fn key_ffi(self : KeyboardEvent) -> @extern.JsString =
  #|(event) => event.key

fn key(self : KeyboardEvent) -> String {
  self.key_ffi().to_string()
}
