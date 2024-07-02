test {
  // Posix
  let posix_path = Path::new("/tmp/abc/f/d", Platform::Posix, FileType::File)
  inspect(posix_path.is_absolute(), content="true")!
  inspect(posix_path.parent(), content="/tmp/abc/f/")!
  inspect(posix_path.file_name(), content="Some(d)")!
  posix_path.append("def")
  inspect(posix_path, content="/tmp/abc/f/d/def")!

  // Relative Posix
  let rel_posix_path = Path::new("./abc/de/f", Platform::Posix, FileType::File)
  inspect(rel_posix_path.is_relative(), content="true")!
  inspect(rel_posix_path.parent(), content="./abc/de/")!
  inspect(rel_posix_path.file_name(), content="Some(f)")!
  rel_posix_path.append("hello")
  inspect(rel_posix_path.to_string(), content="./abc/de/f/hello")!

  // windows
  let win_path = Path::new("C:\\bc\\de", Platform::Windows, FileType::File)
  inspect(win_path.is_absolute(), content="true")!
  inspect(win_path.file_name(), content="Some(de)")!
}
