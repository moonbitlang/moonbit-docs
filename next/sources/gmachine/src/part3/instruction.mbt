// start instr definition

enum Instruction {
  Unwind
  PushGlobal(String)
  PushInt(Int32)
  Push(Int32)
  MkApp
  Slide(Int32)
  Update(Int32)
  Pop(Int32)
  Alloc(Int32)
  Eval
  Add
  Sub
  Mul
  Div
  Neg
  Eq // ==
  Ne // !=
  Lt // <
  Le // <=
  Gt // >
  Ge // >=
  Cond(List[Instruction], List[Instruction])
  Pack(Int32, Int32) // tag, arity
  CaseJump(List[(Int32, List[Instruction])])
  Split
  Print
} derive(Eq, Debug)

pub extend Instruction with Eq::{not_equal, equal}

pub extend Instruction with @moonbitlang/core/debug.Debug::{to_repr}
// end instr definition
