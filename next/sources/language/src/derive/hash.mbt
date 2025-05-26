// start derive hash struct
struct DeriveHash {
  x : Int
  y : String?
} derive(Hash, Eq, Show)

test "derive hash struct" {
  let hs = @hashset.new()
  hs.add(DeriveHash::{ x: 123, y: None })
  hs.add(DeriveHash::{ x: 123, y: None })
  assert_eq!(hs.size(), 1)
  hs.add(DeriveHash::{ x: 123, y: Some("456") })
  assert_eq!(hs.size(), 2)
}
// end derive hash struct
