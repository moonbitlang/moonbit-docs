// start derive hash struct
struct DeriveHash {
  x : Int
  y : String?
} derive(Hash, Eq, Show)

test "derive hash struct" {
  let hs = @hashset.new()
  hs.add(DeriveHash::{ x: 123, y: None })
  hs.add(DeriveHash::{ x: 123, y: None })
  assert_eq(hs.length(), 1)
  hs.add(DeriveHash::{ x: 123, y: Some("456") })
  assert_eq(hs.length(), 2)
}
// end derive hash struct
