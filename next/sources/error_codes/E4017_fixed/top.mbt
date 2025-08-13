struct S { v : Int } derive(Show)

trait Tee { to_string(Self) -> String }

impl Tee for S with to_string(_self) { "Tee" }

let s : S = { v: 3 }
let t = Tee::to_string(s)