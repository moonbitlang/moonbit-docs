///|
fn run(codes : List[String]) -> Node {
  fn parse_then_compile(code : String) -> (String, Int, List[Instruction]) {
    let tokens = tokenize(code)
    let code = try tokens.parse_sc() catch {
      ParseError(s) => abort(s)
    } else {
      expr => expr
    }
    let code = code.compileSC()
    return code
  }

  let codes = codes.map(parse_then_compile) + prelude_defs.map(ScDef::compileSC)
  let codes = compiled_primitives + codes
  let (heap, globals) = build_initial_heap(codes)
  // start init definition
  let initialState : GState = {
    heap,
    stack: Nil,
    code: @immut/list.of([PushGlobal("main"), Eval]),
    globals,
    stats: 0,
    dump: Nil,
  }
  // end init definition
  GState::reify(initialState)
}

///|
test "basic eval" {
  let main = "(defn main[] (let ([add1 (add 1)]) (add1 1)))"
  inspect(run(@immut/list.of([main])), content="NNum(2)")
  let main = "(defn main[] (let ([x 4] [y 5]) (sub x y)))"
  inspect(run(@immut/list.of([main])), content="NNum(-1)")
}
