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

fn main {
  let buf : @lib.SBuffer[Int] = @lib.SBuffer::new(5)
  println(buf.capacity()) // 5
  for index = 0; index < 8; index = index + 1 {
    buf.append(index)
  }
  println(buf.capacity()) // 10
  println(buf.length()) // 8
  buf.println() // [0,1,2,3,4,5,6,7]
  buf.clear()
  buf.println() // []
  println(buf.capacity()) // 10
  println(buf.length()) // 0
  buf.reset(10)
  println(buf.capacity()) // 10
  println(buf.length()) // 0
}

