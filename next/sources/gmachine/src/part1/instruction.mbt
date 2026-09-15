// start instr definition

enum Instruction {
  Unwind
  PushGlobal(String)
  PushInt(Int)
  PushArg(Int)
  MkApp
  Update(Int)
  Pop(Int)
} derive(Eq, Debug)

pub extend Instruction with Eq::{not_equal, equal}

pub extend Instruction with @moonbitlang/core/debug.Debug::{to_repr}
// end instr definition
