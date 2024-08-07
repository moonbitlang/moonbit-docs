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

pub fn split(s : String, sep : Char) -> Array[String] {
  let mut index = 0
  let result = []
  let it = iter(s)
  while it.index != it.length {
    let c = match it.next() {
      Some(c) => c
      None => return result
    }
    if c == sep {
      let sub = match sub_string(s, index, it.index - 1) {
        Some(sub) => sub
        None => return result
      }
      result.push(sub)
      index = it.index
    }
  }
  let sub = match sub_string(s, index, it.length) {
    Some(sub) => sub
    None => return result
  }
  result.push(sub)
  result
}

pub fn sub_string(s : String, start : Int, end : Int) -> String? {
  if start > end || start < 0 || end > s.length() {
    return None
  }
  let it = iter(s)
  let mut result : String = ""
  while it.index != it.length {
    let c = match it.next() {
      Some(c) => c
      None => return None
    }
    if it.index - 1 >= start && it.index - 1 < end {
      result = result + c.to_string()
    }
  }
  Some(result)
}

pub fn trim(s : String, removed : Char) -> String {
  let l = s.length()
  let mut start = 0
  let mut end = l - 1
  while start < l && s[start] == removed {
    start = start + 1
  }
  while end >= 0 && s[end] == removed {
    end = end - 1
  }
  if start <= end {
    match sub_string(s, start, end + 1) {
      Some(sub) => return sub
      None => return s
    }
  }
  s
}

pub fn index_of(s : String, pattern : String) -> Int? {
  let prefix_func = prefix_function(pattern)
  let mut s_index = 0
  let mut p_index = 0
  let l = s.length()
  while s_index < l {
    if s[s_index] == pattern[p_index] {
      while p_index < pattern.length() && s_index < l && s[s_index] == pattern[p_index] {
        s_index = s_index + 1
        p_index = p_index + 1
      }
      if p_index == pattern.length() {
        return Some(s_index - pattern.length())
      } else {
        p_index = 0
        s_index = s_index + (p_index - prefix_func[p_index])
      }
    } else {
      s_index = s_index + 1
    }
  }
  None
}

pub fn last_index_of(s : String, pattern : String) -> Int? {
  let prefix_func = prefix_function(pattern)
  let mut s_index = 0
  let mut p_index = 0
  let mut index = -1
  let l = s.length()
  while s_index < l {
    if s[s_index] == pattern[p_index] {
      while p_index < pattern.length() && s_index < l && s[s_index] == pattern[p_index] {
        s_index = s_index + 1
        p_index = p_index + 1
      }
      if p_index == pattern.length() {
        let d = s_index - pattern.length()
        if d > index {
          index = d
        }
      }
      p_index = 0
      s_index = s_index + (p_index - prefix_func[p_index])
    } else {
      s_index = s_index + 1
    }
  }
  if index == -1 {
    None
  } else {
    Some(index)
  }
}

pub fn contains(s : String, sub : String) -> Bool {
  match index_of(s, sub) {
    Some(v) => v != -1
    None => false
  }
}

fn prefix_function(pattern : String) -> Array[Int] {
  let result = Array::make(pattern.length(), 0)
  let n = pattern.length()
  let mut i = 1
  while i < n {
    let mut j = result[i - 1]
    while j > 0 && pattern[i] != pattern[j] {
      j = result[j - 1]
    }
    if pattern[i] == pattern[j] {
      j = j + 1
    }
    result[i] = j
    i = i + 1
  }
  result
}

pub fn char_at(s : String, pos : Int) -> Char? {
  if pos >= 0 && pos < s.length() {
    return Some(s.get(pos))
  }
  None
}

pub fn to_char_array(s : String) -> Array[Char] {
  let l = s.length()
  let array = Array::make(l, ' ')
  let mut index = 0
  while index < l {
    array[index] = s.get(index)
    index = index + 1
  }
  array
}

pub struct Iterator {
  mut index : Int
  length : Int
  data : String
}

pub fn iter(s : String) -> Iterator {
  { index: 0, length: s.length(), data: s }
}

pub fn next(self : Iterator) -> Char? {
  if self.index == self.length {
    return None
  }
  let c = self.data[self.index]
  self.index = self.index + 1
  Some(c)
}
