fn get_head(cur : List[Position]) -> Position {
  match cur {
    Nil => { x: 0, y: 0 }
    Cons(x, _) => x
  }
}

fn get_tail(cur : List[Position]) -> Position {
  loop cur {
    Nil => { x: 0, y: 0 }
    Cons(x, Nil) => x
    Cons(_, xs) => continue xs
  }
}

fn delete_tail(cur : List[Position]) -> List[Position] {
  fn go(list : List[Position]) -> List[Position] {
    match list {
      Nil => Nil
      Cons(_, Nil) => Nil
      Cons(x, xs) => Cons(x, go(xs))
    }
  }

  go(cur)
}

fn random_lcg(seed : Int64) -> (Int, Int64) {
  let a = 25214903917L
  let c = 11L
  (seed.lsr(15).to_int(), (a * seed.land(0xFFFFFFFFFFFFL) + c).land(0xFFFFFFFFFFFFL))
}
