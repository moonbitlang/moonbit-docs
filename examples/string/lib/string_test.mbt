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
  let arr = @lib.split("a.b.c.e.f.g.h.i.j.k.l.m.n", '.')
  @test.eq!(
    arr,
    ["a", "b", "c", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"],
  )
  inspect!(
    @lib.sub_string("Hello World", 3, 7),
    content=
      #|Some("lo W")
    ,
  )
  "Hello World" |> @lib.index_of("Wo") |> @test.eq!(Some(6))
  "Hello World World Hello" |> @lib.last_index_of("Wo") |> @test.eq!(Some(12))
  @test.is_true!(@lib.contains("Hello World", "Wo"))
  let arr = @lib.to_char_array("HelloWorld")
  @test.eq!(arr, ['H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd'])
  @test.eq!(@lib.char_at("abcde", 4), Some('e'))
  @test.eq!(@lib.trim("   abcde   ", ' '), "abcde")
}
