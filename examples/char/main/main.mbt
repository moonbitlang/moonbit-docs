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
  @test.is_true(@lib.is_alpha('a'))!
  @test.is_false(@lib.is_alpha('3'))!
  @test.is_true(@lib.is_numeric('1'))!
  @test.is_false(@lib.is_numeric('b'))!
  @test.is_true(@lib.is_alphanumeric('a'))!
  @test.eq(@lib.to_lower('H'), 'h')!
  @test.eq(@lib.to_upper('c'), 'C')!
  @test.is_true(@lib.is_whitespace(' '))!
  @test.eq(@lib.next('Z'), Some('['))!
  @test.eq(@lib.prev('A'), Some('@'))!
}
