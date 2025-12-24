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
pub(all) struct Path {
  mut inner : String
  platform : Platform
  file_type : FileType
}

///|
pub(all) enum FileType {
  File
  Directory
  Symlink
  Unknown
}

///|
pub(all) enum Platform {
  Posix
  Windows
}

///|
pub fn Path::new(s : String, platform : Platform, file_type : FileType) -> Path {
  { inner: s, platform, file_type }
}

///|
pub fn Path::parent(self : Path) -> String {
  match self.platform {
    Posix => {
      let parts = self.inner.split("/").collect()
      let builder = StringBuilder::new()
      match parts {
        [.. parent, _, ""] =>
          for p in parent {
            builder..write_string(p.to_string())..write_char('/')
          }
        [.. parent, _] =>
          for p in parent {
            builder..write_string(p.to_string())..write_char('/')
          }
        _ => panic()
      }
      builder.to_string()
    }
    Windows => {
      let parts = self.inner.split("\\").collect()
      let builder = StringBuilder::new()
      match parts {
        [.. parent, _, ""] =>
          for p in parent {
            builder..write_string(p.to_string())..write_char('\\')
          }
        [.. parent, _] =>
          for p in parent {
            builder..write_string(p.to_string())..write_char('\\')
          }
        _ => panic()
      }
      builder.to_string()
    }
  }
}

///|
pub fn Path::is_absolute(self : Path) -> Bool {
  self.has_root()
}

///|
pub fn Path::is_relative(self : Path) -> Bool {
  not(self.has_root())
}

///|
pub fn Path::has_root(self : Path) -> Bool {
  match self.platform {
    Posix => self.inner is ['/', ..]
    Windows => self.inner is ['a'..='z' | 'A'..='Z', ':', ..]
  }
}

///|
pub fn Path::file_name(self : Path) -> String? {
  match self.file_type {
    FileType::File =>
      match self.platform {
        Posix => self.inner.split("/").last().map(StringView::to_string)
        Windows => self.inner.split("\\").last().map(StringView::to_string)
      }
    _ => None
  }
}

///|
pub fn Path::append(self : Path, p : String) -> Unit {
  match self.platform {
    Posix => {
      if !(self.inner is [.., '/']) {
        self.inner = self.inner + "/"
      }
      self.inner = self.inner + p
    }
    Windows => {
      if !(self.inner is [.., '\\']) {
        self.inner = self.inner + "\\"
      }
      self.inner = self.inner + p
    }
  }
}

///|
pub impl Show for Path with output(self : Path, log : &Logger) -> Unit {
  self.inner.output(log)
}
