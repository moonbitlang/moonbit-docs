fn log(x : Double) -> Double = "math" "log"

fn floor(x : Double) -> Int = "math" "floor"

fn float_of_int(x : Int) -> Double = "math" "float_of_int"

type ImageData

fn set_image_data(self : ImageData, x : Int, rgb : Int) = "imagedata" "set"

let escape_radius = 4.0

let max_iter_number = 1000

// -0.743030 + 0.126433i @ 0.016110 /0.75
// -0.74364085 + 0.13182733i @ 0.00012068 /.75
// -0.7 + 0.0i @ 3.0769 / 0.75

let ratio = 0.75

let image_width = 800.0

let image_height : Double = image_width * ratio // 600

let coffset : Double = if floor(image_width) % 2 == 0 {
  image_width / 2.0 - 0.5
} else {
  image_width / 2.0
}

let roffset : Double = if floor(image_height) % 2 == 0 {
  image_height / 2.0 - 0.5
} else {
  image_height / 2.0
}

pub fn iter(cx : Double, cy : Double) -> Double {
  let mut x = 0.0
  let mut y = 0.0
  let mut newx = 0.0
  let mut newy = 0.0
  let mut smodz = 0.0
  let mut i = 0
  while i < max_iter_number {
    newx = x * x - y * y + cx
    newy = 2.0 * x * y + cy
    x = newx
    y = newy
    i = i + 1
    smodz = x * x + y * y
    if smodz >= escape_radius {
      return float_of_int(i) + 1.0 - log(log(smodz) * 0.5) / log(2.0)
    }
  }
  return -1.0
}

fn interpolation(f : Double, c0 : Int, c1 : Int) -> Int {
  let r0 = c0.asr(16).land(0xFF)
  let g0 = c0.asr(8).land(0xFF)
  let b0 = c0.land(0xFF)
  let r1 = c1.asr(16).land(0xFF)
  let g1 = c1.asr(8).land(0xFF)
  let b1 = c1.land(0xFF)
  let r = floor((1.0 - f) * float_of_int(r0) + f * float_of_int(r1) + 0.5)
  let g = floor((1.0 - f) * float_of_int(g0) + f * float_of_int(g1) + 0.5)
  let b = floor((1.0 - f) * float_of_int(b0) + f * float_of_int(b1) + 0.5)
  return r.lsl(16).lor(g.lsl(8).lor(b))
}

pub fn get_color(d : Double) -> Int {
  if d >= 0.0 {
    let mut k = 0.021 * (d - 1.0 + log(log(128.0)) / log(2.0))
    k = log(1.0 + k) - 29.0 / 400.0
    k = k - float_of_int(floor(k))
    k = k * 400.0
    if k < 63.0 {
      return interpolation(k / 63.0, 0x000764, 0x206BCB)
    } else if k < 167.0 {
      return interpolation((k - 63.0) / (167.0 - 63.0), 0x206BCB, 0xEDFFFF)
    } else if k < 256.0 {
      return interpolation((k - 167.0) / (256.0 - 167.0), 0xEDFFFF, 0xFFAA00)
    } else if k < 342.0 {
      return interpolation((k - 256.0) / (342.0 - 256.0), 0xFFAA00, 0x310230)
    } else {
      return interpolation((k - 342.0) / (400.0 - 342.0), 0x310230, 0x000764)
    }
  } else {
    return 0x000000
  }
}

pub fn calc_color(col : Int, row : Int, ox : Double, oy : Double,
        width : Double) -> Int {
  let pixel_size = width / image_width
  let cx = (float_of_int(col) - coffset) * pixel_size + ox
  let cy = (float_of_int(row) - roffset) * pixel_size + oy
  let mut r = 0
  let mut g = 0
  let mut b = 0
  let mut i = -1
  while i <= 1 {
    let mut j = -1
    while j <= 1 {
      let d = iter(
        cx + float_of_int(i) * pixel_size / 3.0,
        cy + float_of_int(j) * pixel_size / 3.0,
      )
      let c = get_color(d)
      r = r + c.asr(16).land(0xFF)
      g = g + c.asr(8).land(0xFF)
      b = b + c.land(0xFF)
      j = j + 1
    }
    i = i + 1
  }
  r = r / 9
  g = g / 9
  b = b / 9
  return r.lsl(16).lor(g.lsl(8)).lor(b)
}

pub fn draw_color(image_data : ImageData, col : Int, row : Int, rgb : Int) {
  let pindex = ((image_height - float_of_int(row) - 1.0) * image_width + float_of_int(
      col,
    )) * 4.0
  let pindex = floor(pindex)
  set_image_data(image_data, pindex, rgb.lsr(16).land(0xFF))
  set_image_data(image_data, pindex + 1, rgb.lsr(8).land(0xFF))
  set_image_data(image_data, pindex + 2, rgb.land(0xFF))
  set_image_data(image_data, pindex + 3, 0xFF)
}

