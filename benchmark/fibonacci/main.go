package main

// Declare a main function, this is the entrypoint into our go module
// That will be run. In our example, we won't need this
func main() {}


// This exports an add function.
// It takes in two 32-bit integer values
// And returns a 32-bit integer value.
// To make this function callable from JavaScript,
// we need to add the: "export add" comment above the function
//export fib
func fib(a int) int {
  var aux func(n, acc1, acc2 int) int
	aux = func(n, acc1, acc2 int) int {
		switch n {
		case 0:
			return acc1
		case 1:
			return acc2
		default:
			return aux(n-1, acc2, acc1+acc2)
		}
	}
	return aux(a, 0, 1)
}