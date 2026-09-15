// start derive hash struct
struct DeriveHash {
  x : Int
  y : String?
} derive(Hash, Eq)

pub extend DeriveHash with Hash::{hash, hash_combine}

pub extend DeriveHash with Eq::{not_equal, equal}

test "derive hash struct" {
  let hs = @hashset.HashSet([])
  hs.add(DeriveHash::{ x: 123, y: None })
  hs.add(DeriveHash::{ x: 123, y: None })
  @test.assert_eq(hs.length(), 1)
  hs.add(DeriveHash::{ x: 123, y: Some("456") })
  @test.assert_eq(hs.length(), 2)
}
// end derive hash struct
