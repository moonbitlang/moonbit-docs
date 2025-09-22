# Array

Array is a collection of elements that have the same type.

You can create an array using *array literal syntax*, which is a comma-separated list
of elements enclosed in square brackets: `[1,2,3]`.

You can also create an array by using the `Array::make` function, which takes a size and an element value,
as shown in the example, `Array::make(4,1)` creates an array equal to `[1,1,1,1]`.

The `arr3` is an array consisting of elements in `arr1`, elements in `arr2` and a few more numbers.
`..arr1` in square brackets is called an *array spread*, which is used to expand an array into another array.

## Array view

You can use the `array[start:end]` syntax to get a view of the array from index `start` to `end` (exclusive). The `start` and `end` parts are optional. A view is a reference to the original array and is used to avoid copying the array.

## Mutability of array

You may notice that we push an element to the array `arr1`, which changes the content of the array. How does that work if `arr1` is not marked with `mut`?

The answer is that the elements inside the array are mutable, which is **defined by the array type itself**. The `mut` keyword in the `let` statement is only used to determine whether the variable name you defined can be reassigned.

If you try to reassign `arr1` to another array like `arr1 = [1,2,3]`, you will get a compilation error.
