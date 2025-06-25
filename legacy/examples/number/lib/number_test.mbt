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
  inspect(@lib.pi, content="3.141592653589793")
  inspect(@lib.max(4, 2), content="4")
  inspect(@lib.min(1.2, 1.21), content="1.2")
  inspect(@lib.int_max, content="2147483647")
  inspect(@lib.int_min, content="-2147483648")
  inspect(@lib.parse_int("214748"), content="Some(214748)")
  // overflowed
  inspect(@lib.parse_int("2147483648"), content="None")
  // -2_147_483_648
  inspect(@lib.parse_int("-2147483648"), content="Some(-2147483648)")
  // overflowed
  inspect(@lib.parse_int("-2147483649"), content="None")
  // 291
  inspect(@lib.parse_int("0x123"), content="Some(291)")
  // 117
  inspect(@lib.parse_int("0b1110101"), content="Some(117)")
  // 83
  inspect(@lib.parse_int("0o123"), content="Some(83)")
  inspect(@lib.abs_int(-3), content="3") // 3
  // 720
  inspect(@lib.factorial(6), content="Some(720)")
}
