typealias List[E] = @immut/list.T[E]


enum RawExpr[T] {
  Var(T)
  Num(Int)
  Constructor(tag~:Int, arity~:Int) // tag, arity
  App(RawExpr[T], RawExpr[T])
  Let(Bool, List[(T, RawExpr[T])], RawExpr[T]) // isRec, Defs, Body
  Case(RawExpr[T], List[(Int, List[T], RawExpr[T])])
} derive(Show)

struct ScDef[T] {
  name : String
  args : List[T]
  body : RawExpr[T]
} derive(Show)

fn is_atom[T](self : RawExpr[T]) -> Bool {
  match self {
    Var(_) => true
    Num(_) => true
    _ => false
  }
}

fn binders_of[L, R](l : List[(L, R)]) -> List[L] {
  fn fst(pair) {
    let (l, _) = pair
    return l
  }

  l.map(fst)
}

fn rhss_of[L, R](l : List[(L, R)]) -> List[R] {
  fn snd(pair) {
    let (_, r) = pair
    return r
  }

  l.map(snd)
}

fn ScDef::new[T](
  name : String,
  args : List[T],
  body : RawExpr[T]
) -> ScDef[T] {
  { name : name, args : args, body : body }
}

let prelude_defs : List[ScDef[String]] = {
  let args : (FixedArray[String]) -> List[String] = List::of
  let id = ScDef::new("I", args(["x"]), Var("x")) // id x = x
  let k = 
    ScDef::new(
      "K",
      args(["x", "y"]),
      Var("x")
    ) // K x y = x
  let k1 = 
    ScDef::new(
      "K1",
      args(["x", "y"]),
      Var("y")
    ) // K1 x y = y
  let s = 
    ScDef::new(
      "S",
      args(["f", "g", "x"]),
      App(App(Var("f"), Var("x")), App(Var("g"), Var("x")))
    ) // S f g x = f x (g x)
  let compose = 
    ScDef::new(
      "compose",
      args(["f", "g", "x"]),
      App(Var("f"), App(Var("g"), Var("x")))
    ) // compose f g x = f (g x)
  let twice = 
    ScDef::new(
      "twice",
      args(["f"]),
      App(App(Var("compose"), Var("f")), Var("f"))
    ) // twice f = compose f f
  List::of([id, k, k1, s, compose, twice])
}