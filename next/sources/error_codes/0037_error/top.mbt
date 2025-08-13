fn read() -> BytesView {
  ...
}

fn main {
  let mut bytes = []
  read~: loop read() {
    [] => break
    bs => {
      bytes = [..bytes, ..bs]
      continue read()
    }
  }
}
