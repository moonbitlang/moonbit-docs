trait Animal {
  make_sound(Self) -> String
  make_sound(Self) -> String  // Error: method make_sound is declared twice
}