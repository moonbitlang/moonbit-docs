package main

import (
	"syscall/js"
)

func fib(n int) int {
    var acc1 int = 0
    var acc2 int = 1
    var i int = n
    for true {
      switch i {
        case 0:
            return acc1
        case 1:
            return acc2
        default:
            i = i - 1
            acc1, acc2 = acc2, acc1 + acc2
      }
    }
    return 0
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