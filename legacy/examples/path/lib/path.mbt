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

pub(all) struct Path {
  mut inner : String
  platform : Platform
  file_type : FileType
}

pub(all) enum FileType {
  File
  Directory
  Symlink
  Unknown
}

pub(all) enum Platform {
  Posix
  Windows
}

pub fn Path::new(s : String, platform : Platform, file_type : FileType) -> Path {
  { inner: s, platform, file_type }
}

pub fn parent(self : Path) -> String {
  match self.platform {
    Posix => {
      let (parts, l) = split(self.inner, '/')
      let mut parent = ""
      let mut index = 0
      let end = if parts[l] == "" { l - 1 } else { l }
      while index < end {
        parent = parent + parts[index] + "/"
        index = index + 1
      }
      parent
    }
    Windows => {
      let (parts, l) = split(self.inner, '\\')
      let mut parent = ""
      let mut index = 0
      let end = if parts[l] == "" { l - 1 } else { l }
      while index < end {
        parent = parent + parts[index] + "\\"
        index = index + 1
      }
      parent
    }
  }
}

pub fn is_absolute(self : Path) -> Bool {
  self.has_root()
}

pub fn is_relative(self : Path) -> Bool {
  not(self.has_root())
}

pub fn has_root(self : Path) -> Bool {
  match self.platform {
    Posix => self.inner[0] == '/'
    Windows =>
      ((self.inner[0].compare('a') >= 0 && self.inner[0].compare('z') <= 0) || (self.inner[0].compare(
        'A',
      ) >= 0 && self.inner[0].compare('Z') <= 0)) && self.inner[1] == ':'
  }
}

pub fn file_name(self : Path) -> String? {
  match self.file_type {
    FileType::File => {
      let (parts, l) = match self.platform {
        Posix => split(self.inner, '/')
        Windows => split(self.inner, '\\')
      }
      Some(parts[l])
    }
    _ => None
  }
}

pub fn append(self : Path, p : String) -> Unit {
  match self.platform {
    Posix => {
      if self.inner[self.inner.length() - 1] != '/' {
        self.inner = self.inner + "/"
      }
      self.inner = self.inner + p
    }
    Windows => {
      if self.inner[self.inner.length() - 1] != '\\' {
        self.inner = self.inner + "\\"
      }
      self.inner = self.inner + p
    }
  }
}

pub fn to_string(self : Path) -> String {
  self.inner
}

pub fn output(self : Path, log : &Logger) -> Unit {
  self.inner.output(log)
}
