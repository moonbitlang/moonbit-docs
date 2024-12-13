# For-in loop

It's cumbersome to write a for loop and manually decide the end condition.

If you want to iterate over a collection, you can use the `for-in` loop.

In the first for-in loop, we iterate over an array. The loop will bind each
element to the variable `element` in each iteration.

We can also iterate over a map with key-value pairs. The second loop will bind
the key to the variable `k` and the value to the variable `v`.

Which collections can be iterated over with a for-in loop? And when does the for-in loop support two variables? The for-in loop functionality actually depends on the API of the collection:

- If the collection provides an `iter()` method to return a `Iter[V]` iterator, then the for-in loop can iterate over it. 

- If the collections provided `iter2()` methods to return a `Iter2[K,V]` iterator, you can use two variables to iterate over it.

We will explain more details about the iterator in a later chapter.

