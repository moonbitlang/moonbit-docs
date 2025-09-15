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
pub fn[T : Compare + Show] assert_eq(left : T, right : T) -> Unit {
  if left.compare(right) != 0 {
    abort(
      "assertion failed: (left == right)\n" +
      "left: " +
      left.to_string() +
      "\n" +
      "right: " +
      right.to_string() +
      "\n",
    )
  }
}

///|
pub fn[T : Compare + Show] assert_ne(left : T, right : T) -> Unit {
  if left.compare(right) == 0 {
    abort(
      "assertion failed: (left != right)\n" +
      "left: " +
      left.to_string() +
      "\n" +
      "right: " +
      right.to_string() +
      "\n",
    )
  }
}
