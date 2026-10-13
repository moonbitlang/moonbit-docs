// start compile_sc definition
fn ScDef::compileSC(self : ScDef[String]) -> (String, Int32, List[Instruction]) {
  let name = self.name
  let body = self.body
  let mut arity = 0
  fn gen_env(i : Int32, args : List[String]) -> List[(String, Int32)] {
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
// end compile_sc definition

// start compile_r definition
fn RawExpr::compileR(
  self : RawExpr[String],
  env : List[(String, Int32)],
  arity : Int32
) -> List[Instruction] {
  if arity == 0 {
    self.compileC(env) + @list.List([Update(arity), Unwind])
  } else {
    self.compileC(env) + @list.List([Update(arity), Pop(arity), Unwind])
  }
}
// end compile_r definition

// start compile_c definition
fn RawExpr::compileC(
  self : RawExpr[String],
  env : List[(String, Int32)]
) -> List[Instruction] {
  match self {
    Var(s) =>
      match env.lookup(s) {
        None => @list.List([PushGlobal(s)])
        Some(n) => @list.List([PushArg(n)])
      }
    Num(n) => @list.List([PushInt(n)])
    App(e1, e2) =>
      e2.compileC(env) +
      e1.compileC(argOffset(1, env)) +
      @list.List([MkApp])
    _ => abort("not support yet")
  }
}
// end compile_c definition

fn argOffset(n : Int32, env : List[(String, Int32)]) -> List[(String, Int32)] {
  env.map(fn (entry) {
    let (name, offset) = entry
    (name, offset + n)
  })
}
