//  Copyright 2024 International Digital Economy Academy
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at

//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

fn main {
  let mut v : @lib.T[Int] = Empty
  let iter = 30 // Create an empty AVL tree with Int type

  // Add values from 0 to iter-1 to the AVL tree
  for i = 0; i < iter; i = i + 1 {
    v = v.add(i)
  }
  let height = v.height()
  println("height of the tree: \{height}")
  v.print_tree()

  // Check values from 0 to iter-1 in the AVL tree
  for i = 0; i < iter; i = i + 1 {
    if not(v.mem(i)) {
      abort("impossible")
    }
  }

  // Remove values from 0 to iter-1 from the AVL tree
  for i = 0; i < iter; i = i + 1 {
    v = v.remove(i)
  }

  // Tree is empty, removal successful
  match v {
    Empty => println("success")
    Node(_) => println("impossible")
  }
}
