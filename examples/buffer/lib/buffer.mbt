pub struct SBuffer[T] {
  mut cap : Int
  mut len : Int
  mut data : Array[T]
}

pub fn SBuffer::new[T : Default](capacity : Int) -> SBuffer[T] {
  { cap: capacity, len: 0, data: Array::make(capacity, T::default()) }
}

pub fn capacity[T](self : SBuffer[T]) -> Int {
  self.cap
}

pub fn length[T](self : SBuffer[T]) -> Int {
  self.len
}

pub fn op_get[T](self : SBuffer[T], i : Int) -> Option[T] {
  if i < self.cap {
    Some(self.data[i])
  } else {
    None
  }
}

fn expand_size[T : Default](self : SBuffer[T]) -> Unit {
  let new_capacity = if self.cap != 0 {
    self.cap * 2
  } else {
    (self.cap + 1) * 2
  }
  self.cap = new_capacity
  let new_data = Array::make(new_capacity, T::default())
  let mut index = 0
  while index < self.len {
    new_data[index] = self.data[index]
    index = index + 1
  }
  self.data = new_data
}

pub fn append[T : Default](self : SBuffer[T], value : T) -> Unit {
  if self.len >= self.cap {
    self.expand_size()
  }
  self.data[self.len] = value
  self.len = self.len + 1
}

pub fn truncate[T : Default](self : SBuffer[T], another : SBuffer[T]) -> Unit {
  let mut index = 0
  while index < another.len {
    if self.len >= self.cap {
      self.expand_size()
    }
    self.data[self.len] = another.data[index]
    self.len = self.len + 1
    index = index + 1
  }
}

pub fn clear[T : Default](self : SBuffer[T]) -> Unit {
  let mut index = 0
  while index < self.len {
    self.data[index] = T::default()
    index = index + 1
  }
  self.len = 0
}

pub fn reset[T : Default](self : SBuffer[T], capacity : Int) -> Unit {
  self.cap = capacity
  self.len = 0
  self.data = Array::make(capacity, T::default())
}

pub fn println[T : Show](self : SBuffer[T]) -> Unit {
  let mut index = 0
  print('[')
  while index < self.len {
    print(self.data[index].to_string())
    index = index + 1
    if index < self.len {
      print(',')
    }
  }
  println(']')
}

fn init {
  ()
}

