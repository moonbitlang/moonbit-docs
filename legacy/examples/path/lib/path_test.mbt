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
test {
  // Posix
  let posix_path = @lib.Path::new(
    "/tmp/abc/f/d",
    @lib.Platform::Posix,
    @lib.FileType::File,
  )
  inspect(posix_path.is_absolute(), content="true")
  inspect(posix_path.parent(), content="/tmp/abc/f/")
  inspect(
    posix_path.file_name(),
    content=(
      #|Some("d")
    ),
  )
  posix_path.append("def")
  inspect(
    posix_path,
    content=(
      #|"/tmp/abc/f/d/def"
    ),
  )

  // Relative Posix
  let rel_posix_path = @lib.Path::new(
    "./abc/de/f",
    @lib.Platform::Posix,
    @lib.FileType::File,
  )
  inspect(rel_posix_path.is_relative(), content="true")
  inspect(rel_posix_path.parent(), content="./abc/de/")
  inspect(
    rel_posix_path.file_name(),
    content=(
      #|Some("f")
    ),
  )
  rel_posix_path.append("hello")
  inspect(
    rel_posix_path.to_string(),
    content=(
      #|"./abc/de/f/hello"
    ),
  )

  // windows
  let win_path = @lib.Path::new(
    "C:\\bc\\de",
    @lib.Platform::Windows,
    @lib.FileType::File,
  )
  inspect(win_path.is_absolute(), content="true")
  inspect(
    win_path.file_name(),
    content=(
      #|Some("de")
    ),
  )
}
