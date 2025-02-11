
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
} derive(Eq, Show)

struct GHeap {
  // The heap uses an array, 
  // and the space with None content in the array is available as free memory.
  mut object_count : Int
  memory : Array[Node?]
}

// Allocate heap space for nodes.
fn alloc(self : GHeap, node : Node) -> Addr {
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


fn op_get(self : GHeap, key : Addr) -> Node {
  let Addr(i) = key
  match self.memory[i] {
    Some(node) => node
    None => abort("GHeap::get(): index \{i} was empty")
  }
}

fn op_set(self : GHeap, key : Addr, val : Node) -> Unit {
  self.memory[key._] = Some(val)
}


struct GState {
  mut stack : List[Addr]
  heap : GHeap
  globals : @hashmap.T[String, Addr]
  mut dump : List[(List[Instruction], List[Addr])]
  mut code : List[Instruction]
  mut stats : GStats
}

type GStats Int

fn stat_incr(self : GState) -> Unit {
  self.stats = self.stats._ + 1
}

fn put_stack(self : GState, addr : Addr) -> Unit {
  self.stack = Cons(addr, self.stack)
}

fn put_dump(self : GState, codes : List[Instruction], stack : List[Addr]) -> Unit {
  self.dump = Cons((codes, stack), self.dump)
}

fn put_code(self : GState, instrs : List[Instruction]) -> Unit {
  self.code = instrs + self.code
}

fn pop1(self : GState) -> Addr {
  match self.stack {
    Cons(addr, reststack) => {
      self.stack = reststack
      addr
    }
    Nil => abort("pop1(): stack size smaller than 1")
  }
}

// e1 e2 ..... -> (e1, e2) ......
fn pop2(self : GState) -> (Addr, Addr) {
  match self.stack {
    Cons(addr1, Cons(addr2, reststack)) => {
      self.stack = reststack
      (addr1, addr2)
    }
    _ => abort("pop2(): stack size smaller than 2")
  }
}

fn push_int(self : GState, num : Int) -> Unit {
  let addr = self.heap.alloc(NNum(num))
  self.put_stack(addr)
}

fn push_global(self : GState, name : String) -> Unit {
  let sc = self.globals[name]
  match sc {
    None => abort("push_global(): cant find supercombinator \{name}")
    Some(addr) => self.put_stack(addr)
  }
}

// start push definition
fn push(self : GState, offset : Int) -> Unit {
  // Push(n) a0 : . . . : an : s
  //     =>  an : a0 : . . . : an : s
  let addr = self.stack.unsafe_nth(offset)
  self.put_stack(addr)
}
// end push definition

// start slide definition
fn slide(self : GState, n : Int) -> Unit {
  let addr = self.pop1()
  self.stack = Cons(addr, self.stack.drop(n))
}
// end slide definition

// start rearrange definition
fn rearrange(self : GState, n : Int) -> Unit {
  let appnodes = self.stack.take(n)
  let args = appnodes.map(fn (addr) {
    guard let NApp(_, arg) = self.heap[addr] else {
      _ => panic()
    }
    arg 
  })
  self.stack = args + appnodes.drop(n - 1)
}
// end rearrange definition

fn mk_apply(self : GState) -> Unit {
  let (a1, a2) = self.pop2()
  let appaddr = self.heap.alloc(NApp(a1, a2))
  self.put_stack(appaddr)
}
fn update(self : GState, n : Int) -> Unit {
  let addr = self.pop1()
  let dst = self.stack.unsafe_nth(n)
  self.heap[dst] = NInd(addr)
}

// start unwind definition
fn unwind(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(_) => {
      match self.dump {
        Nil => self.put_stack(addr)
        Cons((instrs, stack), rest_dump) => {
          self.stack = stack
          self.put_stack(addr)
          self.dump = rest_dump
          self.code = instrs
        }
      }
    }
    NApp(a1, _) => {
      self.put_stack(addr)
      self.put_stack(a1)
      self.put_code(@immut/list.of([Unwind]))
    }
    NGlobal(_, n, c) => {
      if self.stack.length() < n {
        abort("Unwinding with too few arguments")
      } else {
        if n != 0 {
          self.rearrange(n)
        } else {
          self.put_stack(addr)
        }
        self.put_code(c)
      }
    }
    NInd(a) => {
      self.put_stack(a)
      self.put_code(@immut/list.of([Unwind]))
    }
  }
}
// end unwind definition

// start alloc definition
fn alloc_nodes(self : GState, n : Int) -> Unit {
  let dummynode : Node = NInd(Addr(-1))
  for i = 0; i < n; i = i + 1 {
    let addr = self.heap.alloc(dummynode)
    self.put_stack(addr)
  }
}
// end alloc definition

// start eval definition
fn eval(self : GState) -> Unit {
  let addr = self.pop1()
  self.put_dump(self.code, self.stack)
  self.stack = @immut/list.of([addr])
  self.code = @immut/list.of([Unwind])
}
// end eval definition

// start cond definition
fn condition(self : GState, i1 : List[Instruction], i2 : List[Instruction]) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(0) => {
      // false
      self.code = i2 + self.code
    }
    NNum(1) => {
      // true
      self.code = i1 + self.code
    }
    otherwise => abort("cond : \{addr} = \{otherwise}")
  }
}
// end cond definition

// start op definition
fn negate(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(n) => {
      let addr = self.heap.alloc(NNum(-n))
      self.put_stack(addr)
    }
    otherwise => {
      abort("negate: wrong kind of node \{otherwise}, address \{addr}")
    }
  }
}

fn lift_arith2(self : GState, op : (Int, Int) -> Int) -> Unit {
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

fn lift_cmp2(self : GState, op : (Int, Int) -> Bool) -> Unit {
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
// end op definition

fn build_initial_heap(
  scdefs : List[(String, Int, List[Instruction])]
) -> (GHeap, @hashmap.T[String, Addr]) {
  let heap = { object_count: 0, memory: Array::make(10000, None) }
  let globals = @hashmap.new(capacity=50)
  loop scdefs {
    Nil => ()
    Cons((name, arity, instrs), rest) => {
      let addr = heap.alloc(NGlobal(name, arity, instrs))
      globals[name] = addr
      continue rest
    }
  }
  return (heap, globals)
}



fn step(self : GState) -> Bool {
  match self.code {
    Nil => return false
    Cons(i, rest) => {
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
        Add => self.lift_arith2(fn (x, y) { x + y})
        Sub => self.lift_arith2(fn (x, y) { x - y})
        Mul => self.lift_arith2(fn (x, y) { x * y})
        Div => self.lift_arith2(fn (x, y) { x / y})
        Neg => self.negate()
        Eq => self.lift_cmp2(fn (x, y) { x == y })
        Ne => self.lift_cmp2(fn (x, y) { x != y })
        Lt => self.lift_cmp2(fn (x, y) { x < y })
        Le => self.lift_cmp2(fn (x, y) { x <= y })
        Gt => self.lift_cmp2(fn (x, y) { x > y })
        Ge => self.lift_cmp2(fn (x, y) { x >= y })
        Cond(i1, i2) => self.condition(i1, i2)
      }
      return true
    }
  }
}



fn reify(self : GState) -> Node {
  if self.step() {
    self.reify()
  } else {
    let stack = self.stack
    match stack {
      Cons(addr, Nil) => {
        let res = self.heap[addr]
        return res
      }
      _ => abort("wrong stack \{stack}")
    }
  }
}

