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

priv type JsArray

fn JsArray::new() -> JsArray = "array" "new"

fn push(self : JsArray, charCode : Int) = "array" "push"

pub(all) type JsString

fn JsString::from_char_code(charCode : JsArray) -> JsString = "string" "fromCharCode"

fn iter(self : JsString, f : (Int) -> Unit) -> Unit = "string" "iter"

pub fn JsString::from_string(str : String) -> JsString {
  str
  .iter()
  .fold(
    fn(array : JsArray, char : Char) {
      array.push(char.to_int())
      array
    },
    init=JsArray::new(),
  )
  |> JsString::from_char_code
}

pub fn JsString::to_string(str : JsString) -> String {
  let buffer = StringBuilder::new()
  str.iter(fn(i : Int) { buffer.write_char(Char::from_int(i)) })
  buffer.to_string()
}
