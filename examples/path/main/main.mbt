fn init {
  // Posix
  let posix_path = @lib.Path::new(
    "/tmp/abc/f/d",
    @lib.Platform::Posix,
    @lib.FileType::File,
  )
  if posix_path.is_absolute() {
    println("is absolute")
  }
  println(posix_path.parent()) // /tmp/abc/f/
  match posix_path.file_name() {
    Some(v) =>
      println(v) // d
    None => ()
  }
  posix_path.append("def")
  println(posix_path.to_string()) // /tmp/abc/f/d/def
  let rel_posix_path = @lib.Path::new(
    "./abc/de/f",
    @lib.Platform::Posix,
    @lib.FileType::File,
  )
  if rel_posix_path.is_relative() {
    println("is relative")
  }
  println(rel_posix_path.parent()) // ./abc/de/
  match rel_posix_path.file_name() {
    Some(v) =>
      println(v) // f
    None => ()
  }
  rel_posix_path.append("hello")
  println(rel_posix_path.to_string()) // ./abc/de/f/hello
  // windows
  let win_path = @lib.Path::new(
    "C:\\bc\\de",
    @lib.Platform::Windows,
    @lib.FileType::File,
  )
  if win_path.is_absolute() {
    println("is absolute")
  }
  match win_path.file_name() {
    Some(v) =>
      println(v) // de
    None => ()
  }
}

