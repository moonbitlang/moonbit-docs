pub extern "wasm" fn extend16(value : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.extend16_s)

pub extern "wasm" fn extend8(value : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.extend8_s)

pub extern "wasm" fn store8(offset : Int, value : Int) =
  #|(func (param i32) (param i32) local.get 0 local.get 1 i32.store8)

pub extern "wasm" fn load8_u(offset : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load8_u)

pub extern "wasm" fn load8(offset : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load8_s)

pub extern "wasm" fn store16(offset : Int, value : Int) =
  #|(func (param i32) (param i32) local.get 0 local.get 1 i32.store16)

pub extern "wasm" fn load16(offset : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load16_s)

pub extern "wasm" fn load16_u(offset : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load16_u)

pub extern "wasm" fn store32(offset : Int, value : Int) =
  #|(func (param i32) (param i32) local.get 0 local.get 1 i32.store)

pub extern "wasm" fn load32(offset : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load)

pub extern "wasm" fn store64(offset : Int, value : Int64) =
  #|(func (param i32) (param i64) local.get 0 local.get 1 i64.store)

pub extern "wasm" fn load64(offset : Int) -> Int64 =
  #|(func (param i32) (result i64) local.get 0 i64.load)

pub extern "wasm" fn storef32(offset : Int, value : Float) =
  #|(func (param i32) (param f32) local.get 0 local.get 1 f32.store)

pub extern "wasm" fn loadf32(offset : Int) -> Float =
  #|(func (param i32) (result f32) local.get 0 f32.load)

pub extern "wasm" fn storef64(offset : Int, value : Double) =
  #|(func (param i32) (param f64) local.get 0 local.get 1 f64.store)

pub extern "wasm" fn loadf64(offset : Int) -> Double =
  #|(func (param i32) (result f64) local.get 0 f64.load)

pub extern "wasm" fn f32_to_i32(value : Float) -> Int =
  #|(func (param f32) (result i32) local.get 0 f32.convert_i32_s)

pub extern "wasm" fn i32_to_f32(value : Int) -> Float =
  #|(func (param i32) (result f32) local.get 0 i32.trunc_f32_s)

pub extern "wasm" fn f32_to_i64(value : Float) -> Int64 =
  #|(func (param f32) (result i64) local.get 0 f32.convert_i64_s)

pub extern "wasm" fn i64_to_f32(value : Int64) -> Float =
  #|(func (param i64) (result f32) local.get 0 i64.trunc_f32_s)

pub extern "wasm" fn f32_to_f64(value : Float) -> Double =
  #|(func (param f32) (result f64) local.get 0 f32.promote_f64)

pub extern "wasm" fn f64_to_f32(value : Double) -> Float =
  #|(func (param f64) (result f32) local.get 0 f64.demote_f32)

extern "wasm" fn malloc_inline(size : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 call $moonbit.malloc)

pub fn malloc(size : Int) -> Int {
  let words = size / 4 + 1
  let address = malloc_inline(8 + words * 4)
  store32(address, 1)
  store32(address + 4, words.lsl(8).lor(246))
  store8(address + words * 4 + 7, 3 - size % 4)
  address + 8
}

pub extern "wasm" fn free(position : Int) =
  #|(func (param i32) local.get 0 i32.const 8 i32.sub call $moonbit.decref)

pub fn copy(dest : Int, src : Int) -> Unit {
  let src = src - 8
  let dest = dest - 8
  let src_len = load32(src + 4).land(0xFFFFFF)
  let dest_len = load32(dest + 4).land(0xFFFFFF)
  let min = if src_len < dest_len { src_len } else { dest_len }
  copy_inline(dest, src, min)
}

extern "wasm" fn copy_inline(dest : Int, src : Int, len : Int) =
  #|(func (param i32) (param i32) (param i32) local.get 0 local.get 1 local.get 2 memory.copy)

pub extern "wasm" fn str2ptr(str : String) -> Int =
  #|(func (param i32) (result i32) local.get 0 call $moonbit.decref local.get 0 i32.const 8 i32.add)

pub extern "wasm" fn ptr2str(ptr : Int) -> String =
  #|(func (param i32) (result i32) local.get 0 i32.const 4 i32.sub i32.const 243 i32.store8 local.get 0 i32.const 8 i32.sub)

pub extern "wasm" fn bytes2ptr(bytes : Bytes) -> Int =
  #|(func (param i32) (result i32) local.get 0 call $moonbit.decref local.get 0 i32.const 8 i32.add)

pub extern "wasm" fn ptr2bytes(ptr : Int) -> Bytes =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.sub)

pub trait Any {}

pub struct Cleanup {
  address : Int
  size : Int
  align : Int
}
