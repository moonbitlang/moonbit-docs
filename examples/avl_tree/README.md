# AVL Tree Implementation with MoonBit

This project uses MoonBit, an end-to-end programming language toolchain, to implement an AVL tree data structure. An AVL tree is a self-balancing binary search tree where the heights of the two child subtrees of any node differ by at most one.

## What is MoonBit?

MoonBit is a revolutionary programming language toolchain designed for cloud and edge computing using WebAssembly. It offers several unique advantages, including smaller WASM output, faster runtime performance, and efficient compile-time performance. It employs a simple yet practical, data-oriented language design.

### Getting Started with MoonBit

You can access the MoonBit IDE environment at [try.moonbitlang.com](https://try.moonbitlang.com) without the need for any installation or reliance on external servers.

## AVL Tree

An AVL tree is a balanced binary search tree that ensures the height difference between the left and right subtrees of any node (known as the balance factor) is at most one. This self-balancing property helps maintain efficient insertion, deletion, and retrieval operations.

### AVL Tree Features

- **Balanced Structure:** AVL trees ensure that the tree remains balanced, which guarantees efficient search operations with O(log n) complexity.
- **Insertion and Deletion:** When nodes are inserted or deleted, AVL trees perform rotations to rebalance the tree as needed.
- **Search Efficiency:** Due to the balanced structure, searching for a value in an AVL tree is highly efficient.

## How to Use This Implementation

To use this AVL tree implementation, follow these steps:

1. **Clone the Repository:** Clone this repository to your local machine.
2. **Compile with MoonBit:** Use the MoonBit toolchain to compile the AVL tree implementation.
3. **Run the Program:** Execute the compiled program to interact with the AVL tree.

### Example Code

Here's an example of how to create and interact with an AVL tree using MoonBit:

```moonbit
-- AVL Tree Implementation Example

import avltree

func main() {
    -- Create a new AVL tree
    let tree = avltree.new()

    -- Insert values into the tree
    tree.insert(10)
    tree.insert(5)
    tree.insert(15)

    -- Search for a value
    let result = tree.search(5)

    -- Print the result
    print(result)
}
