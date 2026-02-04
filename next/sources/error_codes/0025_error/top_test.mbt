// blackbox test (no import, unqualified use)

test {
  inspect(add(1, 2), content="3")
}
