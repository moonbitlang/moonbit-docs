let grid_row_count = 20

let grid_col_count = 10

enum PIECE {
  I
  L
  J
  S
  Z
  T
  O
}

pub fn piece_shape(self : PIECE) -> Array[Array[Int]] {
  match self {
    I => [[1, 1, 1, 1]]
    L => [[0, 0, 2], [2, 2, 2]]
    J => [[3, 0, 0], [3, 3, 3]]
    S => [[0, 4, 4], [4, 4, 0]]
    Z => [[5, 5, 0], [0, 5, 5]]
    T => [[6, 6, 6], [0, 6, 0]]
    O => [[7, 7], [7, 7]]
  }
}
