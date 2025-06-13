///| start run definition
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
  let (heap, globals) = build_initial_heap(codes)
  let initialState : GState = {
    heap,
    stack: Nil,
    code: @immut/list.of([PushGlobal("main"), Unwind]),
    globals,
    stats: 0,
  }
  GState::reify(initialState)
}
// end run definition

///|
test "basic eval" {
  // S K K x => ((K x (K x)) => x
  let main = "(defn main[] (S K K 3))"
  inspect(run(@immut/list.of([main])), content="NNum(3)")
  let main = "(defn main[] (K 0 1))"
  inspect(run(@immut/list.of([main])), content="NNum(0)")
  let main = "(defn main[] (K1 0 1))"
  inspect(run(@immut/list.of([main])), content="NNum(1)")
  let r = LazyRef::{ data: Waiting(fn() { 3 + 4 }) }
  inspect(square(r), content="49")
}
