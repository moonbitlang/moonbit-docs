// start compile_sc definition
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
// end compile_sc definition

// start compile_r definition
fn compileR(
  self : RawExpr[String],
  env : List[(String, Int)],
  arity : Int
) -> List[Instruction] {
  if arity == 0 {
    compileC(self, env) + @immut/list.of([Update(arity), Unwind])
  } else {
    compileC(self, env) + @immut/list.of([Update(arity), Pop(arity), Unwind])
  }
}
// end compile_r definition

// start compile_c definition
fn compileC(
  self : RawExpr[String],
  env : List[(String, Int)]
) -> List[Instruction] {
  match self {
    Var(s) =>
      match env.lookup(s) {
        None => @immut/list.of([PushGlobal(s)])
        Some(n) => @immut/list.of([PushArg(n)])
      }
    Num(n) => @immut/list.of([PushInt(n)])
    App(e1, e2) =>
      compileC(e2, env) + compileC(e1, argOffset(1, env)) + @immut/list.of([MkApp])
    _ => abort("not support yet")
  }
}
// end compile_c definition

fn argOffset(n : Int, env : List[(String, Int)]) -> List[(String, Int)] {
  env.map(fn { (name, offset) => (name, offset + n) })
}
