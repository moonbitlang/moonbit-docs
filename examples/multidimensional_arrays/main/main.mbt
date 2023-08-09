func init {
  let triangle = [[2], [3, 4], [6, 5, 7], [4, 1, 8, 3]]
  let result = @lib.minPathSum(triangle)
  result.print() // prints 11
}
