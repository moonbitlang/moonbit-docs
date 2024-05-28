struct SBuffer {
  mut data : Bytes
  mut len : Int
}

pub fn SBuffer::new(size : Int) -> SBuffer {
  { data: Bytes::make(size), len: 0 }
}

pub fn op_get(self : SBuffer, i : Int) -> Option[Byte] {
  if i < self.data.length() {
    Some(self.data[i])
  } else {
    None
  }
}

pub fn capacity(self : SBuffer) -> Int {
  self.data.length()
}

pub fn length(self : SBuffer) -> Int {
  self.len
}

fn expand_size(self : SBuffer) -> Unit {
  let new_capacity = if self.data.length() != 0 {
    self.data.length() * 2
  } else {
    (self.data.length() + 1) * 2
  }
  let new_data = Bytes::make(new_capacity)
  let mut index = 0
  while index < self.len {
    new_data[index] = self.data[index]
    index = index + 1
  }
  self.data = new_data
}

pub fn append_int(self : SBuffer, value : Int) -> Unit {
  if self.len >= self.data.length() {
    self.expand_size()
  }
  if value > 127 || value < -128 {
    self.data[self.len] = value.asr(24).land(0xFF).to_byte()
    self.data[self.len + 1] = value.asr(16).land(0xFF).to_byte()
    self.data[self.len + 2] = value.asr(8).land(0xFF).to_byte()
    self.data[self.len + 3] = value.land(0xFF).to_byte()
    self.len = self.len + 4
  } else {
    self.data[self.len] = value.to_byte()
    self.len = self.len + 1
  }
}

pub fn truncate(self : SBuffer, another : SBuffer) -> Unit {
  let mut index = 0
  while index < another.len {
    if self.len >= self.data.length() {
      self.expand_size()
    }
    self.data[self.len] = another.data[index]
    self.len = self.len + 1
    index = index + 1
  }
}

pub fn clear(self : SBuffer) -> Unit {
  let mut index = 0
  while index < self.len {
    self.data[index] = b'\x00'
    index = index + 1
  }
  self.len = 0
}

pub fn reset(self : SBuffer, capacity : Int) -> Unit {
  self.len = 0
  self.data = Bytes::make(capacity)
}

pub fn to_bytes(self : SBuffer) -> Bytes {
  self.data
}

pub fn bytes_to_int(bytes : Bytes, start : Int) -> Int {
  bytes[start].to_int().land(0xff).lsl(24).lor(
    bytes[start + 1].to_int().land(0xff).lsl(16).lor(
      bytes[start + 2].to_int().land(0xff).lsl(8).lor(
        bytes[start + 3].to_int().land(0xff),
      ),
    ),
  )
}

fn init {
  ()
}
