///|
fn ScDef::compileSC(self : ScDef[String]) -> (String, Int, List[Instruction]) {
  let name = self.name
  let body = self.body
  let mut arity = 0
  fn gen_env(i : Int, args : List[String]) -> List[(String, Int)] {
    match args {
      Empty => {
        arity = i
        return @list.empty()
      }
      More(s, tail=ss) => gen_env(i + 1, ss).prepend((s, i))
    }
  }

  let env = gen_env(0, self.args)
  (name, arity, body.compileR(env, arity))
}

///|
fn RawExpr::compileR(
  self : RawExpr[String],
  env : List[(String, Int)],
  arity : Int
) -> List[Instruction] {
  if arity == 0 {
    self.compileE(env) + @list.of([Update(arity), Unwind])
  } else {
    self.compileE(env) + @list.of([Update(arity), Pop(arity), Unwind])
  }
}

///|
fn RawExpr::compileC(
  self : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  match self {
    Var(s) =>
      match env.lookup(s) {
        None => @list.of([PushGlobal(s)])
        Some(n) => @list.of([Push(n)])
      }
    Num(n) => @list.of([PushInt(n)])
    // start c_constr definition
    App(App(Constructor(tag=1, arity=2), x), xs) =>
      // Cons(x, xs)
      xs.compileC(env) + x.compileC(argOffset(1, env)) + @list.of([Pack(1, 2)])
    // Empty
    Constructor(tag=0, arity=0) => @list.of([Pack(0, 0)])
    // end c_constr definition
    App(e1, e2) =>
      e2.compileC(env) + e1.compileC(argOffset(1, env)) + @list.of([MkApp])
    Let(rec, defs, e) =>
      if rec {
        compileLetrec(RawExpr::compileC, defs, e, env)
      } else {
        compileLet(RawExpr::compileC, defs, e, env)
      }
    _ => abort("not support yet")
  }
}

///|
fn RawExpr::compileE(
  self : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  match self {
    // start num definition
    Num(n) => @list.of([PushInt(n)])
    // end num definition
    // start let definition
    Let(rec, defs, e) =>
      if rec {
        compileLetrec(RawExpr::compileE, defs, e, env)
      } else {
        compileLet(RawExpr::compileE, defs, e, env)
      }
    // end let definition
    // start if_and_neg definition
    App(App(App(Var("if"), b), e1), e2) => {
      let condition = b.compileE(env)
      let branch1 = e1.compileE(env)
      let branch2 = e2.compileE(env)
      condition + @list.of([Cond(branch1, branch2)])
    }
    App(Var("negate"), e) => e.compileE(env) + @list.of([Neg])
    // end if_and_neg definition
    // start binop definition
    App(App(Var(op), e0), e1) =>
      match builtinOpS.get(op) {
        None => self.compileC(env) + @list.of([Eval])
        Some(instr) => {
          let code1 = e1.compileE(env)
          let code0 = e0.compileE(argOffset(1, env))
          code1 + code0 + @list.of([instr])
        }
      }
    // end binop definition
    // start e_constr_case definition
    Case(e, alts) =>
      e.compileE(env) + @list.of([CaseJump(compileAlts(alts, env))])
    Constructor(tag=0, arity=0) =>
      // Empty
      @list.of([Pack(0, 0)])
    App(App(Constructor(tag=1, arity=2), x), xs) =>
      // Cons(x, xs)
      xs.compileC(env) + x.compileC(argOffset(1, env)) + @list.of([Pack(1, 2)])
    // end e_constr_case definition
    // start default definition
    _ => self.compileC(env) + @list.of([Eval])
    // end default definition
  }
}

///|
fn compileAlts(
  alts : List[(Int, List[String], RawExpr[String])],
  env : List[(String, Int)]
) -> List[(Int, List[Instruction])] {
  fn buildenv(variables : List[String], off : Int) -> List[(String, Int)] {
    match variables {
      Empty => @list.empty()
      More(v, tail=vs) => buildenv(vs, off + 1).prepend((v, off))
    }
  }

  fn go(
    alts : List[(Int, List[String], RawExpr[String])]
  ) -> List[(Int, List[Instruction])] {
    match alts {
      Empty => @list.empty()
      More(alt, tail=rest) => {
        let (tag, variables, body) = alt
        let offset = variables.length()
        let env = buildenv(variables, 0) + argOffset(offset, env)
        let code = @list.of([Split]) +
          body.compileE(env) +
          @list.of([Slide(offset)])
        go(rest).prepend((tag, code))
      }
    }
  }

  go(alts)
}

///|
fn argOffset(n : Int, env : List[(String, Int)]) -> List[(String, Int)] {
  env.map(fn (entry) {
    let (name, offset) = entry
    (name, offset + n)
  })
}

///|
fn compileLet(
  comp : (RawExpr[String], List[(String, Int)]) -> List[Instruction],
  defs : List[(String, RawExpr[String])],
  expr : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  let (env, codes) = loop (env, @list.empty(), defs) {
    (env, acc, Empty) => (env, acc)
    (env, acc, More((name, expr), tail=rest)) => {
      let code = expr.compileC(env)
      let env = argOffset(1, env).prepend((name, 0))
      continue (env, acc + code, rest)
    }
  }
  codes + comp(expr, env) + @list.of([Slide(defs.length())])
}

///|
fn compileLetrec(
  comp : (RawExpr[String], List[(String, Int)]) -> List[Instruction],
  defs : List[(String, RawExpr[String])],
  expr : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  let mut env = env
  loop defs {
    Empty => ()
    More((name, _), tail=rest) => {
      env = argOffset(1, env).prepend((name, 0))
      continue rest
    }
  }
  let n = defs.length()
  fn compileDefs(
    defs : List[(String, RawExpr[String])],
    offset : Int
  ) -> List[Instruction] {
    match defs {
      Empty => comp(expr, env) + @list.of([Slide(n)])
      More((_, expr), tail=rest) =>
        expr.compileC(env) + compileDefs(rest, offset - 1).prepend(Update(offset))
    }
  }

  compileDefs(defs, n - 1).prepend(Alloc(n))
}

///|
let compiled_primitives : List[(String, Int, List[Instruction])] = @list.of([
  // Arith
  (
    "add",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Add, Update(2), Pop(2), Unwind]),
  ),
  (
    "sub",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Sub, Update(2), Pop(2), Unwind]),
  ),
  (
    "mul",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Mul, Update(2), Pop(2), Unwind]),
  ),
  (
    "div",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Div, Update(2), Pop(2), Unwind]),
  ),
  // Compare
  (
    "eq",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Eq, Update(2), Pop(2), Unwind]),
  ),
  (
    "neq",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Ne, Update(2), Pop(2), Unwind]),
  ),
  (
    "ge",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Ge, Update(2), Pop(2), Unwind]),
  ),
  (
    "gt",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Gt, Update(2), Pop(2), Unwind]),
  ),
  (
    "le",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Le, Update(2), Pop(2), Unwind]),
  ),
  (
    "lt",
    2,
    @list.of([Push(1), Eval, Push(1), Eval, Lt, Update(2), Pop(2), Unwind]),
  ),
  // MISC
  ("negate", 1, @list.of([Push(0), Eval, Neg, Update(1), Pop(1), Unwind])),
  (
    "if",
    3,
    @list.of([
      Push(0),
      Eval,
      Cond(@list.of([Push(1)]), @list.of([Push(2)])),
      Update(3),
      Pop(3),
      Unwind,
    ]),
  ),
])

///| start builtin definition
let builtinOpS : @hashmap.HashMap[String, Instruction] = {
  let table = @hashmap.new(capacity=50)
  table["add"] = Add
  table["mul"] = Mul
  table["sub"] = Sub
  table["div"] = Div
  table["eq"] = Eq
  table["neq"] = Ne
  table["ge"] = Ge
  table["gt"] = Gt
  table["le"] = Le
  table["lt"] = Lt
  table
}
// end builtin definition
