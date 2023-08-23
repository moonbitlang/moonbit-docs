func println(self : String) {
  self.print()
  '\n'.print()
}

func init {
  // Posix
  let posix_path = @lib.Path::new(
    "/tmp/abc/f/d",
    @lib.Platform::Posix,
    @lib.FileType::File,
  )
  if posix_path.is_absolute() {
    "is absolute".println()
  }
  posix_path.parent().println() // /tmp/abc/f/
  match posix_path.file_name() {
    Some(v) =>
      v.println() // d
    None => ()
  }
  posix_path.append("def")
  posix_path.to_string().println() // /tmp/abc/f/d/def
  let rel_posix_path = @lib.Path::new(
    "./abc/de/f",
    @lib.Platform::Posix,
    @lib.FileType::File,
  )
  if rel_posix_path.is_relative() {
    "is relative".println()
  }
  rel_posix_path.parent().println() // ./abc/de/
  match rel_posix_path.file_name() {
    Some(v) =>
      v.println() // f
    None => ()
  }
  rel_posix_path.append("hello")
  rel_posix_path.to_string().println() // ./abc/de/f/hello
  // windows
  let win_path = @lib.Path::new(
    "C:\\bc\\de",
    @lib.Platform::Windows,
    @lib.FileType::File,
  )
  if win_path.is_absolute() {
    "is absolute".println()
  }
  match win_path.file_name() {
    Some(v) =>
      v.println() // de
    None => ()
  }
}

