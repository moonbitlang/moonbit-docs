// Use the 'type' keyword to encapsulate an address type.
type Addr Int derive(Eq, Show)

// Describe graph nodes with an enumeration type.
enum Node {
  NNum(Int)
  // The application node
  NApp(Addr, Addr)
  // To store the number of parameters and 
  // the corresponding sequence of instructions for a super combinator
  NGlobal(String, Int, List[Instruction])
  // The Indirection node，The key component of implementing lazy evaluation
  NInd(Addr)
  NConstr(Int, List[Addr])
} derive(Eq, Show)

struct GHeap {
  // The heap uses an array, 
  // and the space with None content in the array is available as free memory.
  mut object_count : Int
  memory : Array[Node?]
}

// Allocate heap space for nodes.
fn GHeap::alloc(self : GHeap, node : Node) -> Addr {
  let heap = self
  fn next(n : Int) -> Int {
    (n + 1) % heap.memory.length()
  }

  fn free(i : Int) -> Bool {
    match heap.memory[i] {
      None => true
      _ => false
    }
  }

  let mut i = heap.object_count
  while not(free(i)) {
    i = next(i)
  }
  heap.memory[i] = Some(node)
  heap.object_count = heap.object_count + 1
  return Addr(i)
}

fn GHeap::op_get(self : GHeap, key : Addr) -> Node {
  let Addr(i) = key
  match self.memory[i] {
    Some(node) => node
    None => abort("GHeap::get(): index \{i} was empty")
  }
}

fn GHeap::op_set(self : GHeap, key : Addr, val : Node) -> Unit {
  self.memory[key.inner()] = Some(val)
}

struct GState {
  output : @buffer.T
  mut stack : List[Addr]
  heap : GHeap
  globals : @hashmap.T[String, Addr]
  mut dump : List[(List[Instruction], List[Addr])]
  mut code : List[Instruction]
  mut stats : GStats
}

type GStats Int

fn GState::stat_incr(self : GState) -> Unit {
  self.stats = self.stats.inner() + 1
}

fn GState::put_stack(self : GState, addr : Addr) -> Unit {
  self.stack = self.stack.prepend(addr)
}

fn GState::put_dump(
  self : GState,
  codes : List[Instruction],
  stack : List[Addr]
) -> Unit {
  self.dump = self.dump.prepend((codes, stack))
}

fn GState::put_code(self : GState, instrs : List[Instruction]) -> Unit {
  self.code = instrs + self.code
}

fn GState::pop1(self : GState) -> Addr {
  match self.stack {
    More(addr, tail=reststack) => {
      self.stack = reststack
      addr
    }
    Empty => abort("pop1(): stack size smaller than 1")
  }
}

// e1 e2 ..... -> (e1, e2) ......
fn GState::pop2(self : GState) -> (Addr, Addr) {
  match self.stack {
    More(addr1, tail=More(addr2, tail=reststack)) => {
      self.stack = reststack
      (addr1, addr2)
    }
    _ => abort("pop2(): stack size smaller than 2")
  }
}

fn GState::push_int(self : GState, num : Int) -> Unit {
  let addr = self.heap.alloc(NNum(num))
  self.put_stack(addr)
}

fn GState::push_global(self : GState, name : String) -> Unit {
  guard self.globals.get(name) is Some(addr) else {
    abort("push_global(): cant find supercombinator \{name}")
  }
  self.put_stack(addr)
}

fn GState::push(self : GState, offset : Int) -> Unit {
  // Push(n) a0 : . . . : an : s
  //     =>  an : a0 : . . . : an : s
  let addr = self.stack.unsafe_nth(offset)
  self.put_stack(addr)
}

fn GState::slide(self : GState, n : Int) -> Unit {
  let addr = self.pop1()
  self.stack = self.stack.drop(n).prepend(addr)
}

fn GState::rearrange(self : GState, n : Int) -> Unit {
  let appnodes = self.stack.take(n)
  let args = appnodes.map(fn(addr) {
    guard self.heap[addr] is NApp(_, arg)
    arg
  })
  self.stack = args + appnodes.drop(n - 1)
}

fn GState::mk_apply(self : GState) -> Unit {
  let (a1, a2) = self.pop2()
  let appaddr = self.heap.alloc(NApp(a1, a2))
  self.put_stack(appaddr)
}

fn GState::update(self : GState, n : Int) -> Unit {
  let addr = self.pop1()
  let dst = self.stack.unsafe_nth(n)
  self.heap[dst] = NInd(addr)
}

fn GState::unwind(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(_) =>
      match self.dump {
        Empty => self.put_stack(addr)
        More((instrs, stack), tail=rest_dump) => {
          self.stack = stack
          self.put_stack(addr)
          self.dump = rest_dump
          self.code = instrs
        }
      }
    NApp(a1, _) => {
      self.put_stack(addr)
      self.put_stack(a1)
      self.put_code(@list.of([Unwind]))
    }
    // start unwind_g definition
    NGlobal(_, n, c) => {
      let k = self.stack.length()
      if k < n {
        match self.dump {
          Empty => abort("Unwinding with too few arguments")
          More((i, s), tail=rest) => {
            // a1 : ...... : ak
            // ||
            // ak : s
            self.stack = self.stack.drop(k - 1) + s
            self.dump = rest
            self.code = i
          }
        }
      } else {
        if n != 0 {
          self.rearrange(n)
        } else {
          self.put_stack(addr)
        }
        self.put_code(c)
      }
    }
    // end unwind_g definition
    NInd(a) => {
      self.put_stack(a)
      self.put_code(@list.of([Unwind]))
    }
    NConstr(_, _) =>
      match self.dump {
        Empty => abort("Unwinding with too few arguments")
        More((i, s), tail=rest) => {
          self.dump = rest
          self.stack = s
          self.code = i
          self.put_stack(addr)
        }
      }
  }
}

fn GState::alloc_nodes(self : GState, n : Int) -> Unit {
  let dummynode : Node = NInd(Addr(-1))
  for i = 0; i < n; i = i + 1 {
    let addr = self.heap.alloc(dummynode)
    self.put_stack(addr)
  }
}

fn GState::eval(self : GState) -> Unit {
  let addr = self.pop1()
  self.put_dump(self.code, self.stack)
  self.stack = @list.of([addr])
  self.code = @list.of([Unwind])
}

fn GState::condition(
  self : GState,
  i1 : List[Instruction],
  i2 : List[Instruction]
) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(0) =>
      // false
      self.code = i2 + self.code
    NNum(1) =>
      // true
      self.code = i1 + self.code
    otherwise => abort("cond : \{addr} = \{otherwise}")
  }
}

fn GState::negate(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(n) => {
      let addr = self.heap.alloc(NNum(-n))
      self.put_stack(addr)
    }
    otherwise =>
      abort("negate: wrong kind of node \{otherwise}, address \{addr}")
  }
}

fn GState::lift_arith2(self : GState, op : (Int, Int) -> Int) -> Unit {
  let (a1, a2) = self.pop2()
  match (self.heap[a1], self.heap[a2]) {
    (NNum(n1), NNum(n2)) => {
      let newnode = Node::NNum(op(n1, n2))
      let addr = self.heap.alloc(newnode)
      self.put_stack(addr)
    }
    (node1, node2) => abort("liftArith2: \{a1} = \{node1} \{a2} = \{node2}")
  }
}

fn GState::lift_cmp2(self : GState, op : (Int, Int) -> Bool) -> Unit {
  let (a1, a2) = self.pop2()
  match (self.heap[a1], self.heap[a2]) {
    (NNum(n1), NNum(n2)) => {
      let flag = op(n1, n2)
      let newnode = if flag { Node::NNum(1) } else { Node::NNum(0) }
      let addr = self.heap.alloc(newnode)
      self.put_stack(addr)
    }
    (node1, node2) => abort("liftCmp2: \{a1} = \{node1} \{a2} = \{node2}")
  }
}

// start split_pack definition
fn GState::pack(self : GState, t : Int, n : Int) -> Unit {
  let addrs = self.stack.take(n)
  self.stack = self.stack.drop(n)
  let addr = self.heap.alloc(NConstr(t, addrs))
  self.put_stack(addr)
}

fn GState::split(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NConstr(_, addrs) =>
      // n == addrs.length()
      self.stack = addrs + self.stack
    _ => panic()
  }
}
// end split_pack definition

// start casejump definition
fn GState::casejump(self : GState, table : List[(Int, List[Instruction])]) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NConstr(t, _) =>
      match table.lookup(t) {
        None => abort("casejump")
        Some(instrs) => {
          self.code = instrs + self.code
          self.put_stack(addr)
        }
      }
    otherwise => abort("casejump(): addr = \{addr} node = \{otherwise}")
  }
}
// end casejump definition

// start gprint definition
fn GState::gprint(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(n) => {
      self.output.write_string(n.to_string())
      self.output.write_char(' ')
    }
    NConstr(0, Empty) => self.output.write_string("Nil")
    NConstr(1, More(addr1, tail=More(addr2, tail=Empty))) => {
      self.code = @list.of([Instruction::Eval, Print, Eval, Print]) +
        self.code
      self.put_stack(addr2)
      self.put_stack(addr1)
    }
    _ => panic()
  }
}
// end gprint definition

fn build_initial_heap(
  scdefs : List[(String, Int, List[Instruction])]
) -> (GHeap, @hashmap.T[String, Addr]) {
  let heap = { object_count: 0, memory: Array::make(10000, None) }
  let globals = @hashmap.new(capacity=50)
  loop scdefs {
    Empty => ()
    More((name, arity, instrs), tail=rest) => {
      let addr = heap.alloc(NGlobal(name, arity, instrs))
      globals[name] = addr
      continue rest
    }
  }
  return (heap, globals)
}

fn GState::step(self : GState) -> Bool {
  match self.code {
    Empty => return false
    More(i, tail=rest) => {
      self.code = rest
      self.stat_incr()
      match i {
        PushGlobal(f) => self.push_global(f)
        PushInt(n) => self.push_int(n)
        Push(n) => self.push(n)
        MkApp => self.mk_apply()
        Unwind => self.unwind()
        Update(n) => self.update(n)
        Pop(n) => self.stack = self.stack.drop(n)
        Alloc(n) => self.alloc_nodes(n)
        Eval => self.eval()
        Slide(n) => self.slide(n)
        Add => self.lift_arith2(fn(x, y) { x + y })
        Sub => self.lift_arith2(fn(x, y) { x - y })
        Mul => self.lift_arith2(fn(x, y) { x * y })
        Div => self.lift_arith2(fn(x, y) { x / y })
        Neg => self.negate()
        Eq => self.lift_cmp2(fn(x, y) { x == y })
        Ne => self.lift_cmp2(fn(x, y) { x != y })
        Lt => self.lift_cmp2(fn(x, y) { x < y })
        Le => self.lift_cmp2(fn(x, y) { x <= y })
        Gt => self.lift_cmp2(fn(x, y) { x > y })
        Ge => self.lift_cmp2(fn(x, y) { x >= y })
        Cond(i1, i2) => self.condition(i1, i2)
        Pack(tag, arity) => self.pack(tag, arity)
        CaseJump(alts) => self.casejump(alts)
        Split => self.split()
        Print => self.gprint()
      }
      return true
    }
  }
}

fn GState::reify(self : GState) -> String {
  if self.step() {
    self.reify()
  } else {
    self.output.contents().to_unchecked_string()
  }
}
