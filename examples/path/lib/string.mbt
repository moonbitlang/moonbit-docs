pub func split(s : String, sep : Char) -> (Array[String], Int) {
  var index = 0
  var result : Array[String] = Array::make(5, "")
  var cur = 0
  let it = iter(s)
  while it.index != it.length {
    let Some(c) = it.next()
    if c == sep {
      let Some(sub) = sub_string(s, index, it.index - 1)
      result.set(cur, sub)
      cur = cur + 1
      if cur >= result.length() {
        var new_result = Array::make(result.length() * 2, "")
        var tmp_cur = 0
        while tmp_cur < result.length() {
          new_result.set(tmp_cur, result[tmp_cur])
          tmp_cur = tmp_cur + 1
        }
        result = new_result
      }
      index = it.index
    }
  }
  let Some(sub) = sub_string(s, index, it.length)
  result.set(cur, sub)
  (result, cur)
}

pub func sub_string(s : String, start : Int, end : Int) -> Option[String] {
  if start > end || start < 0 || end > s.length() {
    return None
  }
  let it = iter(s)
  var result : String = ""
  while it.index != it.length {
    let Some(c) = it.next()
    if it.index - 1 >= start && it.index - 1 < end {
      result = result + c.to_string()
    }
  }
  Some(result)
}

pub func trim(s : String, removed : Char) -> String {
  let l = s.length()
  var start = 0
  var end = l - 1
  while start < l && s[start] == removed {
    start = start + 1
  }
  while end >= 0 && s[end] == removed {
    end = end - 1
  }
  if start <= end {
    let Some(r) = sub_string(s, start, end + 1)
    return r
  }
  s
}

pub func index_of(s : String, pattern : String) -> Option[Int] {
  let prefix_func = prefix_function(pattern)
  var s_index = 0
  var p_index = 0
  let l = s.length()
  while s_index < l {
    if s[s_index] == pattern[p_index] {
      while p_index < pattern.length() &&
      s_index < l && s[s_index] == pattern[p_index] {
        s_index = s_index + 1
        p_index = p_index + 1
      }
      if p_index == pattern.length() {
        return Some(s_index - pattern.length())
      } else {
        p_index = 0
        s_index = s_index + (p_index - prefix_func[p_index])
      }
    } else {
      s_index = s_index + 1
    }
  }
  None
}

pub func last_index_of(s : String, pattern : String) -> Option[Int] {
  let prefix_func = prefix_function(pattern)
  var s_index = 0
  var p_index = 0
  var index = -1
  let l = s.length()
  while s_index < l {
    if s[s_index] == pattern[p_index] {
      while p_index < pattern.length() &&
      s_index < l && s[s_index] == pattern[p_index] {
        s_index = s_index + 1
        p_index = p_index + 1
      }
      if p_index == pattern.length() {
        let d = s_index - pattern.length()
        if d > index {
          index = d
        }
      }
      p_index = 0
      s_index = s_index + (p_index - prefix_func[p_index])
    } else {
      s_index = s_index + 1
    }
  }
  if index == -1 {
    None
  } else {
    Some(index)
  }
}

pub func contains(s : String, sub : String) -> Bool {
  match index_of(s, sub) {
    Some(v) => v != -1
    None => false
  }
}

func prefix_function(pattern : String) -> Array[Int] {
  let result = Array::make(pattern.length(), 0)
  var n = pattern.length()
  var i = 1
  while i < n {
    var j = result[i - 1]
    while j > 0 && pattern[i] != pattern[j] {
      j = result[j - 1]
    }
    if pattern[i] == pattern[j] {
      j = j + 1
    }
    result[i] = j
    i = i + 1
  }
  result
}

pub func char_at(s : String, pos : Int) -> Option[Char] {
  if pos >= 0 && pos < s.length() {
    return Some(s.get(pos))
  }
  None
}

pub func to_char_array(s : String) -> Array[Char] {
  let l = s.length()
  var array = Array::make(l, ' ')
  var index = 0
  while index < l {
    array[index] = s.get(index)
    index = index + 1
  }
  array
}

pub struct Iterator {
  mut index : Int
  length : Int
  data : String
}

pub func iter(s : String) -> Iterator {
  { index: 0, length: s.length(), data: s }
}

pub func next(self : Iterator) -> Option[Char] {
  if self.index == self.length {
    return None
  }
  let c = self.data[self.index]
  self.index = self.index + 1
  Some(c)
}

