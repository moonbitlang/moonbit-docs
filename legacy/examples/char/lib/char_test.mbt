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

test {
  assert_true(@lib.is_alpha('a'))
  assert_false(@lib.is_alpha('3'))
  assert_true(@lib.is_numeric('1'))
  assert_false(@lib.is_numeric('b'))
  assert_true(@lib.is_alphanumeric('a'))
  assert_eq(@lib.to_lower('H'), 'h')
  assert_eq(@lib.to_upper('c'), 'C')
  assert_true(@lib.is_whitespace(' '))
  assert_eq(@lib.next('Z'), Some('['))
  assert_eq(@lib.prev('A'), Some('@'))
}
