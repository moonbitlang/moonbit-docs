fn compileSC(self : ScDef[String]) -> (String, Int, List[Instruction]) {
  let name = self.name
  let body = self.body
  let mut arity = 0
  fn gen_env(i : Int, args : List[String]) -> List[(String, Int)] {
    match args {
      Nil => {
        arity = i
        return Nil
      }
      Cons(s, ss) => Cons((s, i), gen_env(i + 1, ss))
    }
  }

  let env = gen_env(0, self.args)
  (name, arity, compileR(body, env, arity))
}


fn compileR(
  self : RawExpr[String],
  env : List[(String, Int)],
  arity : Int
) -> List[Instruction] {
  if arity == 0 {
    compileC(self, env) + List::of([Update(arity), Unwind])
  } else {
    compileC(self, env) + List::of([Update(arity), Pop(arity), Unwind])
  }
}

fn compileC(
  self : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  match self {
    Var(s) =>
      match env.lookup(s) {
        None => List::of([PushGlobal(s)])
        Some(n) => List::of([Push(n)])
      }
    Num(n) => List::of([PushInt(n)])
    App(e1, e2) =>
      compileC(e2, env) + compileC(e1, argOffset(1, env)) + List::of([MkApp])
    Let(rec, defs, e) =>
      if rec {
        compileLetrec(compileC, defs, e, env)
      } else {
        compileLet(compileC, defs, e, env)
      }
    _ => abort("not support yet")
  }
}

fn argOffset(n : Int, env : List[(String, Int)]) -> List[(String, Int)] {
  env.map(fn { (name, offset) => (name, offset + n) })
}

// start compile_let definition
fn compileLet(
  comp : (RawExpr[String], List[(String, Int)]) -> List[Instruction],
  defs : List[(String, RawExpr[String])],
  expr : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  let (env, codes) = loop env, List::Nil, defs {
    env, acc, Nil => (env, acc)
    env, acc, Cons((name, expr), rest) => {
      let code = compileC(expr, env)
      let env = List::Cons((name, 0), argOffset(1, env))
      continue env, acc + code, rest
    }
  }
  codes + comp(expr, env) + List::of([Slide(defs.length())])
}
// end compile_let definition

// start compile_letrec definition
fn compileLetrec(
  comp : (RawExpr[String], List[(String, Int)]) -> List[Instruction],
  defs : List[(String, RawExpr[String])],
  expr : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  let mut env = env
  loop defs {
    Nil => ()
    Cons((name, _), rest) => {
      env = Cons((name, 0), argOffset(1, env))
      continue rest
    }
  }
  let n = defs.length()
  fn compileDefs(
    defs : List[(String, RawExpr[String])],
    offset : Int
  ) -> List[Instruction] {
    match defs {
      Nil => comp(expr, env) + List::of([Slide(n)])
      Cons((_, expr), rest) =>
        compileC(expr, env) +
        Cons(Update(offset), compileDefs(rest, offset - 1))
    }
  }

  Cons(Alloc(n), compileDefs(defs, n - 1))
}
// end compile_letrec definition

// start prim definition
let compiled_primitives : List[(String, Int, List[Instruction])] = List::of(
  [
    // Arith
    (
      "add",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Add, Update(2), Pop(2), Unwind]),
    ),
    (
      "sub",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Sub, Update(2), Pop(2), Unwind]),
    ),
    (
      "mul",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Mul, Update(2), Pop(2), Unwind]),
    ),
    (
      "div",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Div, Update(2), Pop(2), Unwind]),
    ),
    // Compare
    (
      "eq",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Eq, Update(2), Pop(2), Unwind]),
    ),
    (
      "neq",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Ne, Update(2), Pop(2), Unwind]),
    ),
    (
      "ge",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Ge, Update(2), Pop(2), Unwind]),
    ),
    (
      "gt",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Gt, Update(2), Pop(2), Unwind]),
    ),
    (
      "le",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Le, Update(2), Pop(2), Unwind]),
    ),
    (
      "lt",
      2,
      List::of([Push(1), Eval, Push(1), Eval, Lt, Update(2), Pop(2), Unwind]),
    ),
    // MISC
    ("negate", 1, List::of([Push(0), Eval, Neg, Update(1), Pop(1), Unwind])),
    (
      "if",
      3,
      List::of(
        [
          Push(0),
          Eval,
          Cond(List::of([Push(1)]), List::of([Push(2)])),
          Update(3),
          Pop(3),
          Unwind,
        ],
      ),
    ),
  ],
)
// end prim definition