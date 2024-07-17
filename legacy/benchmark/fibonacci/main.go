package main

import (
	"syscall/js"
)

func fib(n int) int {
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
	return aux(n, 0, 1)
}

func test(this js.Value, inputs []js.Value) interface{} {
	n := inputs[0].Int()
	count := inputs[1].Int()
	i := 0
	res := 0
	for i < count {
		res = fib(n)
		i += 1
	}
	return res
}

func main() {
	c := make(chan struct{}, 0)

	js.Global().Set("test", js.FuncOf(test))

	<-c
}