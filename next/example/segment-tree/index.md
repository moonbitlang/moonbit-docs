# Segment Tree

The Segment Tree is a common data structure used to solve various range modification and query problems. For instance, consider the following problem:

- Given a known-length array of numbers with initial values, we need to perform multiple range addition operations (adding a value to all elements in a range) and range sum operations (calculating the sum of elements in a range).

Using a standard array, assuming the length og this array is N, each modification and query would take O(N) time. However, after constructing a Segment Tree in O(log N) time, both operations can be performed in O(log N), highlighting the importance of Segment Trees for range queries.

This example illustrates just one simple problem that Segment Trees can address. They can handle much more complex and interesting scenarios. In the upcoming articles, we will explore the concept of Segment Trees and how to implement them in MoonBit, ultimately creating a tree that supports range addition and multiplication, enables range sum queries, and has immutable properties.

In this section, we will learn the basic principles of Segment Trees and how to write a simple Segment Tree in MoonBit that supports point modifications and queries.

```{toctree}
:maxdepth: 2
:caption: Contents:
:hidden:
segment-tree
segment-tree2