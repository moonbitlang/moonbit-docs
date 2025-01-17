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
    compileE(self, env) + @immut/list.of([Update(arity), Unwind])
  } else {
    compileE(self, env) + @immut/list.of([Update(arity), Pop(arity), Unwind])
  }
}

fn compileC(
  self : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  match self {
    Var(s) =>
      match env.lookup(s) {
        None => @immut/list.of([PushGlobal(s)])
        Some(n) => @immut/list.of([Push(n)])
      }
    Num(n) => @immut/list.of([PushInt(n)])
    // start c_constr definition
    App(App(Constructor(tag = 1, arity = 2), x), xs) => {
      // Cons(x, xs)
      compileC(xs, env) + compileC(x, argOffset(1, env)) + @immut/list.of([Pack(1, 2)])
    }
    // Nil
    Constructor(tag = 0, arity = 0) => @immut/list.of([Pack(0, 0)])
    // end c_constr definition
    App(e1, e2) =>
      compileC(e2, env) + compileC(e1, argOffset(1, env)) + @immut/list.of([MkApp])
    Let(rec, defs, e) =>
      if rec {
        compileLetrec(compileC, defs, e, env)
      } else {
        compileLet(compileC, defs, e, env)
      } 
    _ => abort("not support yet")
  }
}

fn compileE(self : RawExpr[String], env : List[(String, Int)]) -> List[Instruction] {
  match self {
    // start num definition
    Num(n) => @immut/list.of([PushInt(n)])
    // end num definition
    // start let definition
    Let(rec, defs, e) => {
      if rec {
        compileLetrec(compileE, defs, e, env)
      } else {
        compileLet(compileE, defs, e, env)
      }
    }
    // end let definition
    // start if_and_neg definition
    App(App(App(Var("if"), b), e1), e2) => {
      let condition = compileE(b, env)
      let branch1 = compileE(e1, env)
      let branch2 = compileE(e2, env)
      condition +  @immut/list.of([Cond(branch1, branch2)])
    }
    App(Var("negate"), e) => {
      compileE(e, env) + @immut/list.of([Neg])
    }
    // end if_and_neg definition
    // start binop definition
    App(App(Var(op), e0), e1) => {
      match builtinOpS[op] {
        None => compileC(self, env) + @immut/list.of([Eval])
        Some(instr) => {
          let code1 = compileE(e1, env)
          let code0 = compileE(e0, argOffset(1, env))
          code1 + code0 + @immut/list.of([instr])
        }
      }
    }
    // end binop definition
    // start e_constr_case definition
    Case(e, alts) => {
      compileE(e, env) + @immut/list.of([CaseJump(compileAlts(alts, env))])
    }
    Constructor(tag = 0, arity = 0) => {
      // Nil
      @immut/list.of([Pack(0, 0)])
    }
    App(App(Constructor(tag = 1, arity = 2), x), xs) => {
      // Cons(x, xs)
      compileC(xs, env) + compileC(x, argOffset(1, env)) + @immut/list.of([Pack(1, 2)])
    }
    // end e_constr_case definition
    // start default definition
    _ => compileC(self, env) + @immut/list.of([Eval])
    // end default definition
  }
}

fn compileAlts(alts : List[(Int, List[String], RawExpr[String])], env : List[(String, Int)]) -> List[(Int, List[Instruction])] {
  fn buildenv(variables : List[String], off : Int) -> List[(String, Int)] {
    match variables {
      Nil => Nil
      Cons(v, vs) => {
        Cons((v, off), buildenv(vs, off + 1))
      }
    }
  }
  fn go(alts : List[(Int, List[String], RawExpr[String])]) -> List[(Int, List[Instruction])] {
    match alts {
      Nil => Nil
      Cons(alt, rest) => {
        let (tag, variables, body) = alt
        let offset = variables.length()
        let env = buildenv(variables, 0) + argOffset(offset, env)
        let code = 
          @immut/list.of([Split]) + compileE(body, env) + @immut/list.of([Slide(offset)])
        Cons((tag, code), go(rest))
      }
    }
  }
  go(alts)
}


fn argOffset(n : Int, env : List[(String, Int)]) -> List[(String, Int)] {
  env.map(fn { (name, offset) => (name, offset + n) })
}


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
  codes + comp(expr, env) + @immut/list.of([Slide(defs.length())])
}

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
      Nil => comp(expr, env) + @immut/list.of([Slide(n)])
      Cons((_, expr), rest) =>
        compileC(expr, env) +
        Cons(Update(offset), compileDefs(rest, offset - 1))
    }
  }

  Cons(Alloc(n), compileDefs(defs, n - 1))
}



let compiled_primitives : List[(String, Int, List[Instruction])] = @immut/list.of(
  [
    // Arith
    (
      "add",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Add, Update(2), Pop(2), Unwind]),
    ),
    (
      "sub",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Sub, Update(2), Pop(2), Unwind]),
    ),
    (
      "mul",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Mul, Update(2), Pop(2), Unwind]),
    ),
    (
      "div",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Div, Update(2), Pop(2), Unwind]),
    ),
    // Compare
    (
      "eq",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Eq, Update(2), Pop(2), Unwind]),
    ),
    (
      "neq",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Ne, Update(2), Pop(2), Unwind]),
    ),
    (
      "ge",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Ge, Update(2), Pop(2), Unwind]),
    ),
    (
      "gt",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Gt, Update(2), Pop(2), Unwind]),
    ),
    (
      "le",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Le, Update(2), Pop(2), Unwind]),
    ),
    (
      "lt",
      2,
      @immut/list.of([Push(1), Eval, Push(1), Eval, Lt, Update(2), Pop(2), Unwind]),
    ),
    // MISC
    ("negate", 1, @immut/list.of([Push(0), Eval, Neg, Update(1), Pop(1), Unwind])),
    (
      "if",
      3,
      @immut/list.of(
        [
          Push(0),
          Eval,
          Cond(@immut/list.of([Push(1)]), @immut/list.of([Push(2)])),
          Update(3),
          Pop(3),
          Unwind,
        ],
      ),
    ),
  ],
)

// start builtin definition
let builtinOpS : @hashmap.T[String, Instruction] = {
  let table  = @hashmap.new(capacity = 50)
  table["add"] = Add 
  table["mul"] = Mul
  table["sub"] = Sub
  table["div"] = Div
  table["eq"]  = Eq
  table["neq"] = Ne
  table["ge"] = Ge 
  table["gt"] = Gt
  table["le"] = Le
  table["lt"] = Lt
  table
}
// end builtin definition