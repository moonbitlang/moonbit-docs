type T😯 Int

fn 😀(self : T😯) -> Int {
  self.0
}

pub enum 😆😆 {
  A
  B
}

fn to_string(self : 😆😆) -> String {
  match self {
    A => "A"
    B => "B"
  }
}

test {
  let 🤣 = T😯::T😯(3)
  inspect(🤣.😀(), content="3")!
  let 😆 = 😆😆::A
  inspect(😆, content="A")!
}
