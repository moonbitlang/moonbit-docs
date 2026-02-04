// blackbox test with qualified package use

test {
  inspect(@E0025.add(1, 2), content="3")
}
