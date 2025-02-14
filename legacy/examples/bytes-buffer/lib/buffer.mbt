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
pub struct Buffer {
  mut data : FixedArray[Byte]
  mut len : Int
}

///|
pub fn Buffer::new(size : Int) -> Buffer {
  { data: FixedArray::make(size, 0), len: 0 }
}

///|
pub fn op_get(self : Buffer, i : Int) -> Byte? {
  if i < self.data.length() {
    Some(self.data[i])
  } else {
    None
  }
}

///|
pub fn capacity(self : Buffer) -> Int {
  self.data.length()
}

///|
pub fn length(self : Buffer) -> Int {
  self.len
}

///|
fn expand_size(self : Buffer) -> Unit {
  let new_capacity = if self.data.length() != 0 {
    self.data.length() * 2
  } else {
    (self.data.length() + 1) * 2
  }
  let new_data = FixedArray::make(new_capacity, b'\x00')
  let mut index = 0
  while index < self.len {
    new_data[index] = self.data[index]
    index = index + 1
  }
  self.data = new_data
}

///|
pub fn append_int(self : Buffer, value : Int) -> Unit {
  if self.len + 4 >= self.data.length() {
    self.expand_size()
  }
  let value = value.reinterpret_as_uint()
  self.data[self.len] = ((value >> 24) & 0xFF).to_byte()
  self.data[self.len + 1] = ((value >> 16) & 0xFF).to_byte()
  self.data[self.len + 2] = ((value >> 8) & 0xFF).to_byte()
  self.data[self.len + 3] = (value & 0xFF).to_byte()
  self.len = self.len + 4
}

///|
pub fn truncate(self : Buffer, another : Buffer) -> Unit {
  let mut index = 0
  while index < another.len {
    if self.len >= self.data.length() {
      self.expand_size()
    }
    self.data[self.len] = another.data[index]
    self.len = self.len + 1
    index = index + 1
  }
}

///|
pub fn clear(self : Buffer) -> Unit {
  let mut index = 0
  while index < self.len {
    self.data[index] = b'\x00'
    index = index + 1
  }
  self.len = 0
}

///|
pub fn reset(self : Buffer, capacity : Int) -> Unit {
  self.len = 0
  self.data = FixedArray::make(capacity, b'\x00')
}

///|
pub fn to_bytes(self : Buffer) -> Bytes {
  self.data |> Bytes::from_fixedarray
}
