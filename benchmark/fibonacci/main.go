package main

import (
	"syscall/js"
)

func fib(this js.Value, inputs []js.Value) interface{} {
	a := inputs[0].Int()
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

func main() {
	c := make(chan struct{}, 0)

	js.Global().Set("fib", js.FuncOf(fib))

	<-c
}