enum Term {
  Var(String) // Variable
  Abs(String, Term) // Define lambda, variables represented by strings
  App(Term, Term) // Call lambda
}

struct Index {
  name : String
  depth : Int
}

enum TermDBI {
  Var(String, Int)
  Abs(String, TermDBI)
  App(TermDBI, TermDBI)
}

impl Show for TermDBI with output(self : TermDBI, logger) -> Unit {
  match self {
    Var(name, _) => logger.write_string(name)
    Abs(name, body) => logger.write_string("(\\\{name}.\{body})")
    App(t1, t2) => logger.write_string("\{t1} \{t2}")
  }
}

/// https://bor0.wordpress.com/2019/03/19/writing-a-lambda-calculus-evaluator-in-haskell/
fn bruijn(self : Term) -> Result[TermDBI, String] {
  // Find the depth corresponding to the first varname in the environment
  fn find(map : @immut/list.T[Index], varname : String) -> Result[Int, String] {
    match map {
      Nil => Err(varname)
      Cons(i, rest) =>
        if i.name == varname {
          Ok(i.depth)
        } else {
          find(rest, varname)
        }
    }
  }

  fn go(m : @immut/list.T[Index], t : Term) -> Result[TermDBI, String] {
    match t {
      Var(name) => {
        let idx = find(m, name)
        match idx {
          Err(name) => Err(name)
          Ok(idx) => Ok(Var(name, idx))
        }
      }
      Abs(varname, body) => {
        let m = @immut/list.Cons(
          { name: varname, depth: 0 },
          m.map(fn(index) { { name: index.name, depth: index.depth + 1 } }),
        )
        let res = go(m, body)
        match res {
          Err(name) => Err(name)
          Ok(term) => Ok(Abs(varname, term))
        }
      }
      App(e1, e2) =>
        match (go(m, e1), go(m, e2)) {
          (Ok(e1), Ok(e2)) => Ok(App(e1, e2))
          (Err(name), _) => Err(name)
          (_, Err(name)) => Err(name)
        }
    }
  }

  go(Nil, self)
}

fn subst(t1 : TermDBI, t2 : TermDBI) -> TermDBI {
  fn go(t1 : TermDBI, t2 : TermDBI, depth : Int) -> TermDBI {
    match t1 {
      Var(_, d) => if d == depth { t2 } else { t1 }
      Abs(name, t) => Abs(name, go(t, t2, depth + 1))
      App(tl, tr) => App(go(tl, t2, depth), go(tr, t2, depth))
    }
  }

  go(t1, t2, 0)
}

fn eval(self : TermDBI) -> TermDBI {
  match self {
    App(t1, t2) =>
      match (eval(t1), eval(t2)) {
        (Abs(_, t1), t2) => eval(subst(t1, t2))
        (t1, t2) => App(t1, t2)
      }
    Abs(_) => self
    // Eval should not encounter any free variables
    _ => panic()
  }
}

test {
  // (\x.x x) (\y.y)
  let exp : Term = App(Abs("x", App(Var("x"), Var("x"))), Abs("x", Var("x")))
  let exp = exp.bruijn()
  match exp {
    Err(name) => fail!("err on \{name}\n")
    Ok(t) => {
      inspect!(
        t,
        content=
          #|(\x.x x) (\x.x)
        ,
      )
      let t = eval(t)
      inspect!(
        t,
        content=
          #|(\x.x)
        ,
      )
    }
  }
}
